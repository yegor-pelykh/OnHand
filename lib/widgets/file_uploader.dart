import 'dart:convert';
import 'dart:html';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:on_hand/global/global_constants.dart';
import 'package:on_hand/global/global_data.dart';

enum DropzoneState {
  waiting,
  hovering,
  dropped,
}

class FileUploader extends StatefulWidget {
  final BuildContext parentContext;

  FileUploader(this.parentContext, {super.key});

  @override
  State<FileUploader> createState() => _FileUploaderState();
}

class _FileUploaderState extends State<FileUploader> {
  DropzoneState _state = DropzoneState.waiting;
  File? _droppedFile;
  PlatformFile? _pickedFile;

  String _getFileName() {
    return _droppedFile?.name ?? _pickedFile?.name ?? '';
  }

  void _applyDataFromFile() {
    Future<void> replaceFromJson(String jsonString) async {
      GlobalData.groupStorage.replaceFromJson(jsonString);
      await GlobalData.saveToStorage();
    }

    if (_droppedFile != null) {
      FileReader reader = FileReader();
      reader.onLoad.listen((event) {
        final jsonString = reader.result as String?;
        if (jsonString != null) {
          replaceFromJson(jsonString).whenComplete(() {
            Navigator.of(context).pop();
          });
        }
      });
      reader.readAsText(_droppedFile!);
    } else if (_pickedFile?.bytes != null) {
      final jsonString = const Utf8Decoder().convert(_pickedFile!.bytes!);
      replaceFromJson(jsonString).whenComplete(() {
        Navigator.of(context).pop();
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [GlobalConstants.dataFileExtension],
      allowMultiple: false,
      lockParentWindow: true,
    );
    if (result != null &&
        result.files.isNotEmpty &&
        result.files.first.bytes != null) {
      setState(() {
        _pickedFile = result.files.first;
        _state = DropzoneState.dropped;
      });
    }
  }

  Widget _getDropzoneDecoration() {
    switch (_state) {
      case DropzoneState.waiting:
        return InkWell(
          onTap: _pickFile,
          child: Opacity(
            opacity: 0.5,
            child: DottedBorder(
              color: Theme.of(context).colorScheme.primary,
              borderType: BorderType.RRect,
              radius: const Radius.circular(4),
              strokeWidth: 1,
              strokeCap: StrokeCap.round,
              dashPattern: const [4, 4],
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tr('dropzone_welcome_message'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    const Icon(
                      Icons.upload_file,
                      size: 72,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tr('dropzone_welcome_message_alt'),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      case DropzoneState.hovering:
        return DottedBorder(
          color: Theme.of(context).colorScheme.primary,
          borderType: BorderType.RRect,
          radius: const Radius.circular(4),
          strokeWidth: 1,
          strokeCap: StrokeCap.round,
          dashPattern: const [4, 0],
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('dropzone_welcome_message'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.upload_file,
                  size: 72,
                ),
                const SizedBox(height: 20),
                Text(
                  tr('dropzone_welcome_message_alt'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      case DropzoneState.dropped:
        return DottedBorder(
          color: Theme.of(context).colorScheme.primary,
          borderType: BorderType.RRect,
          radius: const Radius.circular(4),
          strokeWidth: 1,
          strokeCap: StrokeCap.round,
          dashPattern: const [4, 0],
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getFileName(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  tr('dropzone_data_apply_question'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _applyDataFromFile,
                  child: Text(tr('apply')),
                )
              ],
            ),
          ),
        );
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 200,
      child: Stack(
        children: [
          DropzoneView(
            operation: DragOperation.copy,
            onCreated: (DropzoneViewController ctrl) {},
            onLoaded: () => setState(() {
              _droppedFile = null;
              _pickedFile = null;
              _state = DropzoneState.waiting;
            }),
            onError: (String? ev) => setState(() {
              _droppedFile = null;
              _pickedFile = null;
              _state = DropzoneState.waiting;
            }),
            onHover: () => setState(() {
              _droppedFile = null;
              _pickedFile = null;
              _state = DropzoneState.hovering;
            }),
            onDrop: (dynamic data) {},
            onDropMultiple: (List<dynamic>? ev) => setState(() {
              _droppedFile = null;
              _pickedFile = null;
              if (ev != null) {
                for (final element in ev) {
                  _droppedFile = element is File &&
                          element.name.toLowerCase().endsWith(
                              '.${GlobalConstants.dataFileExtension.toLowerCase()}')
                      ? element
                      : null;
                  if (_droppedFile != null) {
                    _state = DropzoneState.dropped;
                    return;
                  }
                }
              }
              _state = DropzoneState.waiting;
            }),
            onLeave: () => setState(() {
              _droppedFile = null;
              _pickedFile = null;
              _state = DropzoneState.waiting;
            }),
          ),
          _getDropzoneDecoration(),
        ],
      ),
    );
  }
}
