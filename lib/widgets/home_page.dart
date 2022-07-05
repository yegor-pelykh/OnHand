import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:on_hand/data/global_data.dart';
import 'package:on_hand/data/group_data.dart';
import 'package:on_hand/widgets/bookmark_editor.dart';
import 'package:on_hand/widgets/bookmarks_view.dart';
import 'package:on_hand/widgets/file_uploader.dart';
import 'package:on_hand/widgets/groups_manager.dart';

const double kTabIndicatorWeight = 2.0;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  TabController? _tabController;

  _HomePageState() {
    GlobalData.groupData.loadGroups().then((_) => update());
  }

  void update() {
    setState(() {
      _tabController = TabController(
        length: GlobalData.groupData.groups.length,
        vsync: this,
      );
    });
  }

  void _createBookmark(BuildContext context) async {
    final groupIndex = GlobalData.groupData.activeGroupIndex;
    if (groupIndex < 0) {
      return;
    }
    showDialog<BookmarkEditorResult?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: const Text('New bookmark'),
          content: BookmarkEditor(
            BookmarkEditorMode.create,
            groups: GlobalData.groupData.groups.map((g) => g.title).toList(),
            selectedGroup: GlobalData.groupData.groups[groupIndex].title,
          ),
        );
      },
    ).then((result) {
      if (result != null) {
        final groupIndex = GlobalData.groupData.groups.indexWhere(
          (g) => g.title == result.groupTitle,
        );
        if (groupIndex >= 0) {
          final group = GlobalData.groupData.groups[groupIndex];
          setState(() {
            group.addBookmark(result.url, result.title, result.icon);
            GlobalData.groupData.saveGroups();
          });
        }
      }
    });
  }

  void _manageGroups() async {
    showDialog<GroupData?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          scrollable: true,
          title: Text('Manage groups'),
          content: GroupsManager(),
        );
      },
    ).then((groupData) {
      if (groupData != null) {
        setState(() {
          GlobalData.groupData = groupData;
          GlobalData.groupData.activeGroupIndex = GlobalData.groupData.groups.isNotEmpty ? 0 : -1;
          GlobalData.groupData.saveGroups();
        });
      }
    });
  }

  Future<void> _downloadData() async {
    final jsonString = GlobalData.groupData.groupsToJsonString();
    Uint8List bytes = Uint8List.fromList(utf8.encode(jsonString));
    await FileSaver.instance.saveFile('data', bytes, 'json', mimeType: MimeType.JSON);
  }

  void _saveToFile(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Save to file'),
          content: const Text('Do you want to save all data to a file?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                _downloadData();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _loadFromFile(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Load from file'),
          content: FileUploader(context),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  AppBar _getAppBar() {
    List<Widget> appBarChildren = <Widget>[];
    if (_tabController != null) {
      appBarChildren.add(
        TabBar(
          controller: _tabController,
          indicatorWeight: kTabIndicatorWeight,
          isScrollable: true,
          tabs: GlobalData.groupData.groups
              .map(
                (group) => Tab(
                  height: kMinInteractiveDimension,
                  child: Text(group.title),
                ),
              )
              .toList(),
          onTap: (index) {
            GlobalData.groupData.activeGroupIndex = index;
          },
        ),
      );
    }
    return AppBar(
      toolbarHeight: kMinInteractiveDimension + kTabIndicatorWeight,
      flexibleSpace: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: appBarChildren,
      ),
    );
  }

  Widget _getBody() {
    if (_tabController == null) {
      return Container();
    }
    return TabBarView(
      controller: _tabController,
      children: GlobalData.groupData.groups.map((group) => BookmarksView(group)).toList(),
    );
  }

  SpeedDial _getSpeedDial(BuildContext context) {
    final backgroundColor = Theme.of(context).colorScheme.secondary;
    final labelBackgroundColor = Theme.of(context).colorScheme.secondary;
    final foregroundColor = Theme.of(context).colorScheme.onSecondary;
    final labelStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSecondary,
    );
    List<SpeedDialChild> children = [];
    if (GlobalData.groupData.activeGroupIndex >= 0) {
      children.add(
        SpeedDialChild(
          child: const Icon(Icons.add),
          label: 'New bookmark',
          backgroundColor: backgroundColor,
          labelBackgroundColor: labelBackgroundColor,
          foregroundColor: foregroundColor,
          labelStyle: labelStyle,
          onTap: () => _createBookmark(context),
        ),
      );
    }
    children.add(
      SpeedDialChild(
        child: const Icon(Icons.apps),
        label: 'Manage groups',
        backgroundColor: backgroundColor,
        labelBackgroundColor: labelBackgroundColor,
        foregroundColor: foregroundColor,
        labelStyle: labelStyle,
        onTap: () => _manageGroups(),
      ),
    );
    if (GlobalData.groupData.groups.isNotEmpty) {
      children.add(
        SpeedDialChild(
          child: const Icon(Icons.download),
          label: 'Save to file',
          backgroundColor: backgroundColor,
          labelBackgroundColor: labelBackgroundColor,
          foregroundColor: foregroundColor,
          labelStyle: labelStyle,
          onTap: () => _saveToFile(context),
        ),
      );
    }
    children.add(
      SpeedDialChild(
        child: const Icon(Icons.upload),
        label: 'Load from file',
        backgroundColor: backgroundColor,
        labelBackgroundColor: labelBackgroundColor,
        foregroundColor: foregroundColor,
        labelStyle: labelStyle,
        onTap: () => _loadFromFile(context),
      ),
    );
    return SpeedDial(
      icon: Icons.more_vert,
      children: children,
    );
  }

  @override
  void initState() {
    GlobalData.updateNotifier.addListener(update);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _getAppBar(),
      body: _getBody(),
      floatingActionButton: _getSpeedDial(context),
    );
  }

  @override
  void dispose() {
    GlobalData.updateNotifier.removeListener(update);
    super.dispose();
  }
}
