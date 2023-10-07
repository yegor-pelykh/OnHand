import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:on_hand/data/group.dart';
import 'package:on_hand/data/group_storage.dart';
import 'package:on_hand/global/global_data.dart';
import 'package:on_hand/widgets/group_editor.dart';
import 'package:on_hand/widgets/group_tile.dart';

class GroupsManager extends StatefulWidget {
  const GroupsManager({super.key});

  @override
  State<GroupsManager> createState() => _GroupsManagerState();
}

class _GroupsManagerState extends State<GroupsManager> {
  final GroupStorage groupStorage;

  _GroupsManagerState() : groupStorage = GlobalData.groupStorage.clone();

  void _update() {
    setState(() {});
  }

  void _createGroup() {
    final forbiddenNames = groupStorage.titles;
    showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(tr('group_creating_dlg_title')),
          content: GroupEditor(
            GroupEditorMode.create,
            forbiddenNames: forbiddenNames,
          ),
        );
      },
    ).then((groupTitle) {
      if (groupTitle != null && groupTitle.isNotEmpty) {
        final group = Group(
          groupStorage,
          groupTitle,
        );
        groupStorage.addGroup(group);
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
        groupStorage.moveGroup(oldIndex, newIndex);
      },
      itemCount: groupStorage.groupsLength,
      itemBuilder: ((context, index) {
        final group = groupStorage.groupAt(index);
        if (group != null) {
          return ReorderableDragStartListener(
            key: ValueKey(index),
            index: index,
            child: GroupTile(group),
          );
        } else {
          return Container();
        }
      }),
      proxyDecorator: (child, index, animation) {
        return child;
      },
    );
  }

  @override
  void initState() {
    super.initState();
    groupStorage.addListener(_update);
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
        const SizedBox(height: 8),
        SizedBox(
          width: 400,
          height: 365,
          child: groupStorage.isNotEmpty ? _getListView() : _getInformationBadge(),
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
                onPressed: () => Navigator.pop(context, groupStorage),
                child: Text(tr('save')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    groupStorage.removeListener(_update);
    super.dispose();
  }
}
