import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:on_hand/data/global_data.dart';
import 'package:on_hand/data/group_data.dart';
import 'package:on_hand/data/group_info.dart';
import 'package:on_hand/widgets/group_editor.dart';

enum _GroupMenuAction {
  edit,
  delete,
}

class GroupsManager extends StatefulWidget {
  const GroupsManager({super.key});

  @override
  State<GroupsManager> createState() => _GroupsManagerState();
}

class _GroupsManagerState extends State<GroupsManager> {
  GroupData groupData = GlobalData.groupData.clone();

  void _createGroup() {
    showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(tr('group_creating_dlg_title')),
          content: GroupEditor(GroupEditorMode.create),
        );
      },
    ).then((groupTitle) {
      if (groupTitle != null && groupTitle.isNotEmpty) {
        setState(() {
          groupData.addGroup(groupTitle);
        });
      }
    });
  }

  void _editGroup(GroupInfo group) {
    showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(tr('group_editing_dlg_title')),
          content: GroupEditor(
            GroupEditorMode.edit,
            initialTitle: group.title,
            forbiddenNames: groupData.groups
                .where((g) => g != group)
                .map((g) => g.title)
                .toList(),
          ),
        );
      },
    ).then((result) {
      if (result != null && result.isNotEmpty) {
        setState(() {
          group.title = result;
        });
      }
    });
  }

  void _deleteGroup(GroupInfo group) {
    showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(tr('group_deleting_dlg_title')),
          content: Text(tr('group_deleting_dlg_content')),
          actions: <Widget>[
            ElevatedButton(
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
        setState(() {
          groupData.groups.remove(group);
        });
      }
    });
  }

  Widget _getInformationBadge() {
    return Center(
      child: Text(tr('hint_no_groups')),
    );
  }

  Widget _getListView() {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex--;
        }
        final GroupInfo group = groupData.groups.removeAt(oldIndex);
        groupData.groups.insert(newIndex, group);
      },
      itemCount: groupData.groups.length,
      itemBuilder: ((context, index) {
        return ReorderableDragStartListener(
          key: ValueKey(index),
          index: index,
          child: Card(
            child: ListTile(
              title: Text(groupData.groups[index].title),
              subtitle: Text(plural('bookmarks_number',
                  groupData.groups[index].bookmarks.length)),
              trailing: PopupMenuButton(
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      value: _GroupMenuAction.edit,
                      child: Row(
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.edit),
                          ),
                          Text(tr('edit')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _GroupMenuAction.delete,
                      child: Row(
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.delete),
                          ),
                          Text(tr('delete')),
                        ],
                      ),
                    )
                  ];
                },
                onSelected: (_GroupMenuAction value) {
                  switch (value) {
                    case _GroupMenuAction.edit:
                      _editGroup(groupData.groups[index]);
                      break;
                    case _GroupMenuAction.delete:
                      _deleteGroup(groupData.groups[index]);
                      break;
                  }
                },
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: () => _createGroup(),
          icon: const Icon(Icons.add_circle),
          label: Text(tr('new_group_label')),
        ),
        SizedBox(
          width: 400,
          height: 365,
          child: groupData.groups.isNotEmpty
              ? _getListView()
              : _getInformationBadge(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr('cancel_changes')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, groupData),
                child: Text(tr('save')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
