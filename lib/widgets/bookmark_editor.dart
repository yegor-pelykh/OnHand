import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_hand/data/dummy_data.dart';
import 'package:on_hand/helpers/metadata_provider.dart';
import 'package:validators/validators.dart';

const protocolHttp = 'http';
const protocolHttps = 'https';
const protocolsToTryIfNoScheme = [
  protocolHttps,
  protocolHttp,
];

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
  final String selectedGroup;
  final List<String> groups;

  BookmarkEditor(
    this.mode, {
    super.key,
    this.initialAddress = '',
    this.initialTitle = '',
    this.selectedGroup = '',
    this.groups = const [],
  });

  @override
  State<BookmarkEditor> createState() => _BookmarkEditorState();
}

class _BookmarkEditorState extends State<BookmarkEditor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _addressEditingController;
  late TextEditingController _titleEditingController;
  late String _selectedGroup;
  bool _isAddressDirty = false;
  bool _isTitleDirty = false;
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
        if (_metadata?.title != null) {
          _titleEditingController.text = _metadata!.title!;
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

  Widget _getFavicon() {
    switch (_state) {
      case BookmarkEditorState.noMetadata:
        return Container();
      case BookmarkEditorState.requesting:
        return const Padding(
          padding: EdgeInsets.fromLTRB(8, 8, 0, 8),
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
          padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
          child: Container(
            width: 24,
            height: 24,
            color: Colors.white,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(12),
              ),
              child: Container(
                width: 24,
                height: 24,
                color: Colors.white,
                child: Image.memory(
                  _metadata?.icon?.bytes ?? DummyData.dummyIcon,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  isAntiAlias: true,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
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
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
    Navigator.pop(
      context,
      BookmarkEditorResult(_selectedGroup, url, title, icon),
    );
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
    if (!_isAddressDirty) {
      return null;
    }
    if (address == null || address.isEmpty) {
      return tr('bookmark_address_empty_hint');
    }
    if (!isURL(address, requireTld: false)) {
      return tr('bookmark_address_invalid_hint');
    }
    return null;
  }

  String? _validateTitle(String? title) {
    if (!_isTitleDirty) {
      return null;
    }
    if (title == null || title.isEmpty) {
      return tr('bookmark_title_empty_hint');
    }
    return null;
  }

  void _onAddressChanged(String current) {
    _isAddressDirty = true;
    _updateMetadata(current);
  }

  void _onTitleChanged(String current) {
    _isTitleDirty = true;
    setState(() {});
  }

  void _onGroupChanged(String? current) {
    if (current != null) {
      _selectedGroup = current;
      setState(() {});
    }
  }

  @override
  void initState() {
    _addressEditingController =
        TextEditingController(text: widget.initialAddress);
    if (_addressEditingController.text.isNotEmpty) {
      _updateMetadata(_addressEditingController.text);
    }
    _titleEditingController = TextEditingController(text: widget.initialTitle);
    _selectedGroup = widget.selectedGroup;
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
              ),
              onChanged: (value) => _onAddressChanged(value),
              validator: (value) => _validateAddress(value),
              onFieldSubmitted: (value) => _submit(context),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    autofocus: true,
                    controller: _titleEditingController,
                    decoration: InputDecoration(
                      labelText: tr('bookmark_title_label'),
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
              ),
              icon: const Icon(Icons.keyboard_arrow_down),
              value: _selectedGroup,
              items: widget.groups.map((String groups) {
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
                    onPressed: _isFormValid() ? () => _submit(context) : null,
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
