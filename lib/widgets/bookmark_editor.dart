import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:on_hand/global/global_constants.dart';
import 'package:on_hand/helpers/image_helper.dart';
import 'package:on_hand/helpers/metadata_provider.dart';
import 'package:validators/validators.dart';

const protocolHttp = 'http';
const protocolHttps = 'https';
const protocolsToTryIfNoScheme = [
  protocolHttps,
  protocolHttp,
];
const titleFilterRegexString =
    r'[^\p{Alpha}\p{M}\p{Nd}\p{P}\p{S}\p{Z}\p{Join_C}\s]+';
const double iconSize = 24;

enum BookmarkEditorMode {
  create,
  edit,
}

enum BookmarkEditorState {
  noMetadata,
  requesting,
  metadataReady,
}

class BookmarkEditorResult {
  String groupTitle;
  Uri url;
  String title;
  Uint8List? icon;

  BookmarkEditorResult(this.groupTitle, this.url, this.title, this.icon);
}

class BookmarkEditor extends StatefulWidget {
  final BookmarkEditorMode mode;
  final String initialAddress;
  final String initialTitle;
  final List<String> groupTitles;
  final String? selectedGroupTitle;

  BookmarkEditor(
    this.mode, {
    super.key,
    this.initialAddress = '',
    this.initialTitle = '',
    this.groupTitles = const [],
    this.selectedGroupTitle,
  });

  @override
  State<BookmarkEditor> createState() => _BookmarkEditorState();
}

class _BookmarkEditorState extends State<BookmarkEditor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _addressEditingController;
  late TextEditingController _titleEditingController;
  String? _selectedGroupTitle;
  BookmarkEditorState _state = BookmarkEditorState.noMetadata;
  Metadata? _metadata;
  Timer? _debounce;

  void _replaceAddress(Uri uri) {
    setState(() {
      final newText = uri.toString();
      final lengthDifference =
          newText.length - _addressEditingController.text.length;
      final preservedSelection = _addressEditingController.selection;
      _addressEditingController.text = uri.toString();
      _addressEditingController.selection = TextSelection(
        baseOffset: preservedSelection.baseOffset + lengthDifference,
        extentOffset: preservedSelection.extentOffset + lengthDifference,
        affinity: preservedSelection.affinity,
      );
    });
  }

  bool _isFormValid() {
    return _formKey.currentState != null && _formKey.currentState!.validate();
  }

  void _setTitle(String title) {
    _titleEditingController.text = title
        .replaceAll(RegExp(titleFilterRegexString, unicode: true), '')
        .trim();
  }

  Future<bool> _requestMetadata(Uri uri) async {
    setState(() {
      _metadata = null;
      _state = BookmarkEditorState.requesting;
    });
    final metadata = await MetadataProvider.getMetadata(uri);
    if (metadata != null) {
      setState(() {
        _metadata = metadata;
        _state = BookmarkEditorState.metadataReady;
        if (_metadata!.title != null) {
          _setTitle(_metadata!.title!);
        }
      });
      return true;
    } else {
      setState(() {
        _metadata = null;
        _state = BookmarkEditorState.noMetadata;
      });
      return false;
    }
  }

  void _updateMetadata(String address) {
    setState(() {
      _metadata = null;
      _state = BookmarkEditorState.noMetadata;
    });
    if (_validateAddress(address) == null) {
      if (_debounce != null && _debounce!.isActive) {
        _debounce!.cancel();
      }
      _debounce = Timer(const Duration(milliseconds: 100), () async {
        Uri uri = Uri.parse(address);
        if (uri.hasScheme) {
          await _requestMetadata(uri);
        } else {
          for (final protocol in protocolsToTryIfNoScheme) {
            uri = Uri.parse('$protocol://$address');
            if (await _requestMetadata(uri)) {
              _replaceAddress(uri);
              break;
            }
          }
        }
      });
    }
  }

  Widget _getIcon() {
    final iconBytes = _metadata?.icon?.bytes;
    final Widget imageWidget;
    if (iconBytes != null) {
      if (ImageHelper.isPng(iconBytes)) {
        imageWidget = Image.memory(
          iconBytes,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
          isAntiAlias: true,
          filterQuality: FilterQuality.medium,
        );
      } else {
        final content = utf8.decode(iconBytes, allowMalformed: true);
        imageWidget = ScalableImageWidget(
          si: ScalableImage.fromSvgString(content),
          fit: BoxFit.cover,
        );
      }
    } else {
      imageWidget = const Icon(
        Icons.favorite,
        color: GlobalConstants.mainColor,
      );
    }
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: imageWidget,
    );
  }

  Widget _getFavicon() {
    switch (_state) {
      case BookmarkEditorState.noMetadata:
        return Container();
      case BookmarkEditorState.requesting:
        return const Padding(
          padding: EdgeInsets.all(8),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        );
      case BookmarkEditorState.metadataReady:
        return Padding(
          padding: const EdgeInsets.all(8),
          child: _getIcon(),
        );
    }
  }

  Future<bool?> _askForUsageWithoutMetadata(BuildContext context) async {
    return await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(tr('bookmark_wo_metadata_dlg_title')),
          content: Text(tr('bookmark_wo_metadata_dlg_content')),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: <Widget>[
            TextButton(
              child: Text(tr('cancel')),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: Text(tr('yes')),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  void _applyAndClose(BuildContext context) {
    Uri url = Uri.parse(_addressEditingController.text);
    if (!url.hasScheme) {
      url = Uri.parse('$protocolHttp://${_addressEditingController.text}');
    }
    final title = _titleEditingController.text;
    final icon = _metadata?.icon?.bytes;
    final groupTitle = _selectedGroupTitle ??
        (widget.groupTitles.isNotEmpty ? widget.groupTitles.first : null);
    if (groupTitle != null) {
      Navigator.pop(
        context,
        BookmarkEditorResult(groupTitle, url, title, icon),
      );
    } else {
      Navigator.pop(
        context,
      );
    }
  }

  void _submit(BuildContext context) {
    if (_isFormValid()) {
      if (_metadata != null) {
        _applyAndClose(context);
      } else {
        _askForUsageWithoutMetadata(context).then((accept) {
          if (accept == true) {
            _applyAndClose(context);
          }
        });
      }
    }
  }

  String? _validateAddress(String? address) {
    if (address == null || address.isEmpty) {
      return tr('bookmark_address_empty_hint');
    }
    if (!isURL(address, requireTld: false)) {
      return tr('bookmark_address_invalid_hint');
    }
    return null;
  }

  String? _validateTitle(String? title) {
    if (title == null || title.isEmpty) {
      return tr('bookmark_title_empty_hint');
    }
    return null;
  }

  void _onAddressChanged(String current) {
    _updateMetadata(current);
  }

  void _onTitleChanged(String current) {
    setState(() {});
  }

  void _onGroupChanged(String? current) {
    setState(() {
      _selectedGroupTitle = current;
    });
  }

  @override
  void initState() {
    _addressEditingController =
        TextEditingController(text: widget.initialAddress);
    if (_addressEditingController.text.isNotEmpty) {
      _updateMetadata(_addressEditingController.text);
    }
    _selectedGroupTitle = widget.selectedGroupTitle;
    _titleEditingController = TextEditingController(text: widget.initialTitle);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 400),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              autofocus: true,
              controller: _addressEditingController,
              decoration: InputDecoration(
                labelText: tr('bookmark_address_label'),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => _onAddressChanged(value),
              validator: (value) => _validateAddress(value),
              onFieldSubmitted: (value) => _submit(context),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    autofocus: true,
                    controller: _titleEditingController,
                    decoration: InputDecoration(
                      labelText: tr('bookmark_title_label'),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => _onTitleChanged(value),
                    validator: (value) => _validateTitle(value),
                    onFieldSubmitted: (value) => _submit(context),
                  ),
                ),
                _getFavicon(),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField(
              decoration: InputDecoration(
                labelText: tr('bookmark_group_label'),
                border: const OutlineInputBorder(),
              ),
              icon: const Icon(Icons.keyboard_arrow_down),
              value: _selectedGroupTitle,
              items: widget.groupTitles.map((String groups) {
                return DropdownMenuItem(
                  value: groups,
                  child: Text(groups),
                );
              }).toList(),
              onChanged: _onGroupChanged,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(tr('cancel')),
                  ),
                  ElevatedButton(
                    onPressed: () => _submit(context),
                    child: Text(
                      widget.mode == BookmarkEditorMode.create
                          ? tr('create')
                          : tr('apply'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressEditingController.dispose();
    _titleEditingController.dispose();
    super.dispose();
  }
}
