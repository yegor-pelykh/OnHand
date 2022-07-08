import 'dart:html';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:on_hand/data/global_data.dart';

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
  DropzoneState state = DropzoneState.waiting;
  File? file;

  Widget _getDropzoneDecoration() {
    switch (state) {
      case DropzoneState.waiting:
        return Opacity(
          opacity: 0.5,
          child: DottedBorder(
            borderType: BorderType.RRect,
            radius: const Radius.circular(4),
            strokeWidth: 1,
            strokeCap: StrokeCap.round,
            dashPattern: const [4, 4],
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr('dropzone_welcome_message')),
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.upload_file,
                    size: 72,
                  ),
                ],
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
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Icon(
                  color: Theme.of(context).colorScheme.primary,
                  Icons.upload_file,
                  size: 72,
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
                  file!.name,
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
                  child: Text(tr('apply')),
                  onPressed: () {
                    if (file != null) {
                      FileReader reader = FileReader();
                      reader.onLoad.listen((event) {
                        final contents = reader.result as String?;
                        if (contents != null) {
                          GlobalData.groupData
                              .setGroupsFromJsonString(contents);
                          GlobalData.groupData.saveGroups();
                          GlobalData.updateNotifier.notify();
                          Navigator.of(context).pop();
                        }
                      });
                      reader.readAsText(file!);
                    }
                  },
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
            cursor: CursorType.grab,
            onCreated: (DropzoneViewController ctrl) {},
            onLoaded: () => setState(() {
              file = null;
              state = DropzoneState.waiting;
            }),
            onError: (String? ev) => setState(() {
              file = null;
              state = DropzoneState.waiting;
            }),
            onHover: () => setState(() {
              file = null;
              state = DropzoneState.hovering;
            }),
            onDrop: (dynamic data) => setState(() {
              file = data is File ? data : null;
              state = DropzoneState.dropped;
            }),
            onDropMultiple: (List<dynamic>? ev) => setState(() {
              // file = null;
              // state = DropzoneState.waiting;
            }),
            onLeave: () => setState(() {
              file = null;
              state = DropzoneState.waiting;
            }),
          ),
          _getDropzoneDecoration(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
