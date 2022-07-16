import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:on_hand/data/global_data.dart';
import 'package:on_hand/data/group_data.dart';
import 'package:on_hand/data/group_info.dart';
import 'package:on_hand/widgets/group_editor.dart';
import 'package:on_hand/widgets/group_tile.dart';

class GroupsManager extends StatefulWidget {
  const GroupsManager({super.key});

  @override
  State<GroupsManager> createState() => _GroupsManagerState();
}

class _GroupsManagerState extends State<GroupsManager> {
  final GroupData groupData;

  _GroupsManagerState() : groupData = GroupData.clone(GlobalData.groupData) {
    for (final group in groupData.groups) {
      group.data = groupData;
    }
  }

  void _update() {
    setState(() {});
  }

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
          child: GroupTile(groupData.groups[index]),
        );
      }),
    );
  }

  @override
  void initState() {
    super.initState();
    groupData.addListener(_update);
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

  @override
  void dispose() {
    groupData.removeListener(_update);
    super.dispose();
  }
}
