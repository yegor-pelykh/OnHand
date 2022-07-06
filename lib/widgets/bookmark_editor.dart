import 'dart:async';
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
  final TextEditingController _addressEditingController =
      TextEditingController();
  final TextEditingController _titleEditingController = TextEditingController();
  late String _selectedGroup;
  BookmarkEditorState _state = BookmarkEditorState.noMetadata;
  Metadata? _metadata;
  Timer? _debounce;
  bool _allowUnavailableAddresses = false;

  String? _validateAddress(String? address) {
    if (address == null || address.isEmpty) {
      return 'Please enter a bookmark address.';
    }
    if (!isURL(address, requireTld: false)) {
      return 'Please enter a valid URL.';
    }
    return null;
  }

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
    if (_metadata == null && _allowUnavailableAddresses == false) {
      return false;
    }
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
        if (_metadata != null && _metadata!.title != null) {
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
      _debounce = Timer(const Duration(milliseconds: 500), () async {
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

  void _submit() {
    if (_isFormValid()) {
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
  }

  @override
  void initState() {
    _addressEditingController.text = widget.initialAddress;
    _titleEditingController.text = widget.initialTitle;
    _selectedGroup = widget.selectedGroup;
    if (_addressEditingController.text.isNotEmpty) {
      _updateMetadata(_addressEditingController.text);
    }
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
              decoration: const InputDecoration(
                labelText: 'Address *',
              ),
              validator: (value) => _validateAddress(value),
              onChanged: (address) => _updateMetadata(address),
              onFieldSubmitted: (value) => _submit(),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    autofocus: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: _titleEditingController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a bookmark title.';
                      }
                      return null;
                    },
                    onChanged: (address) => setState(() {}),
                    onFieldSubmitted: (value) => _submit(),
                  ),
                ),
                _getFavicon(),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField(
              decoration: const InputDecoration(
                labelText: 'Group',
              ),
              icon: const Icon(Icons.keyboard_arrow_down),
              value: _selectedGroup,
              items: widget.groups.map((String groups) {
                return DropdownMenuItem(
                  value: groups,
                  child: Text(groups),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _selectedGroup = newValue;
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Allow unavailable addresses'),
              value: _allowUnavailableAddresses,
              onChanged: (bool? value) {
                if (value != null) {
                  setState(() {
                    _allowUnavailableAddresses = value;
                  });
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _isFormValid() ? _submit : null,
                    child: Text(widget.mode == BookmarkEditorMode.create
                        ? 'Create'
                        : 'Apply'),
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
