import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:on_hand/data/group.dart';
import 'package:on_hand/widgets/group_editor.dart';

class GroupTile extends StatefulWidget {
  final Group group;

  const GroupTile(this.group, {super.key});

  @override
  State<GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends State<GroupTile> {
  void _editGroup(BuildContext context) {
    final forbiddenNames = widget.group.storage.titles;
    showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(tr('group_editing_dlg_title')),
          content: GroupEditor(
            GroupEditorMode.edit,
            initialTitle: widget.group.title,
            forbiddenNames: forbiddenNames,
          ),
        );
      },
    ).then((result) {
      if (result != null && result.isNotEmpty) {
        setState(() {
          widget.group.title = result;
        });
      }
    });
  }

  void _deleteGroup(BuildContext context) {
    showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(tr('group_deleting_dlg_title')),
          content: Text(tr('group_deleting_dlg_content')),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: <Widget>[
            TextButton(
              child: Text(tr('no')),
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
    ).then((result) {
      if (result == true) {
        widget.group.storage.removeGroup(widget.group);
      }
    });
  }

  void _showGroupMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      constraints: const BoxConstraints(
        maxWidth: 400,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (context) {
        final errorColor = Theme.of(context).colorScheme.error;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              dense: true,
              title: Text(
                widget.group.title,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                maxLines: 1,
              ),
              subtitle: Text(
                plural('bookmarks_number', widget.group.bookmarks.length),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                maxLines: 1,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(tr('edit')),
              onTap: () {
                Navigator.pop(context);
                _editGroup(context);
              },
            ),
            ListTile(
              iconColor: errorColor,
              textColor: errorColor,
              leading: const Icon(Icons.delete),
              title: Text(tr('delete')),
              onTap: () {
                Navigator.pop(context);
                _deleteGroup(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        dense: true,
        title: Text(widget.group.title),
        subtitle:
            Text(plural('bookmarks_number', widget.group.bookmarks.length)),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            _showGroupMenu(context);
          },
        ),
      ),
    );
  }
}
