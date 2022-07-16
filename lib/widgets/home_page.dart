import 'dart:convert';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
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

  void _onTabIndexChange() {
    if (_tabController != null) {
      GlobalData.activeGroupIndex = _tabController!.index;
    }
  }

  void _updateTabController() {
    _tabController?.removeListener(_onTabIndexChange);
    _tabController = GlobalData.groupData.groups.isNotEmpty
        ? TabController(
            animationDuration: Duration.zero,
            length: GlobalData.groupData.groups.length,
            initialIndex: GlobalData.activeGroupIndex,
            vsync: this,
          )
        : null;
    _tabController?.addListener(_onTabIndexChange);
  }

  void _update() {
    setState(() {
      _updateTabController();
    });
  }

  void _createBookmark(BuildContext context) async {
    final groupIndex = GlobalData.activeGroupIndex;
    if (groupIndex < 0) {
      return;
    }
    showDialog<BookmarkEditorResult?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(tr('bookmark_creating_dlg_title')),
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
            GlobalData.groupData.saveToStorage();
          });
        }
      }
    });
  }

  void _openGroupManagement() async {
    showDialog<GroupData?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(tr('group_management_dlg_title')),
          content: const GroupsManager(),
        );
      },
    ).then((groupData) {
      if (groupData != null) {
        GlobalData.groupData = groupData;
        GlobalData.groupData.saveToStorage();
        _update();
      }
    });
  }

  Future<void> _downloadData() async {
    final jsonString = GlobalData.groupData.toJsonString();
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    final ext = GlobalData.dataFileExtension.toLowerCase();
    await FileSaver.instance.saveFile('bookmarks.$ext', bytes, ext);
  }

  void _exportToFile(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(tr('export_to_file_dlg_title')),
          content: Text(tr('export_to_file_dlg_content')),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            TextButton(
              child: Text(tr('cancel')),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(tr('save')),
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

  void _importFromFile(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(tr('import_from_file_dlg_title')),
          content: FileUploader(context),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            TextButton(
              child: Text(tr('cancel')),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  AppBar _getAppBar() {
    List<Widget> appBarChildren = <Widget>[];
    if (_tabController != null && GlobalData.groupData.groups.isNotEmpty) {
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
    if (_tabController != null && GlobalData.groupData.groups.isNotEmpty) {
      return TabBarView(
        controller: _tabController,
        children: GlobalData.groupData.groups
            .map((group) => BookmarksView(group))
            .toList(),
      );
    } else {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('home_no_groups_hint'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: 0.5,
              child: Text(
                tr('home_no_groups_hint_details'),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
  }

  SpeedDial _getSpeedDial(BuildContext context) {
    final backgroundColor = Theme.of(context).colorScheme.secondary;
    final labelBackgroundColor = Theme.of(context).colorScheme.secondary;
    final foregroundColor = Theme.of(context).colorScheme.onSecondary;
    final labelStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSecondary,
    );
    List<SpeedDialChild> children = [];
    if (GlobalData.activeGroupIndex >= 0) {
      children.add(
        SpeedDialChild(
          child: const Icon(Icons.add),
          label: tr('create_bookmark'),
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
        label: tr('group_management'),
        backgroundColor: backgroundColor,
        labelBackgroundColor: labelBackgroundColor,
        foregroundColor: foregroundColor,
        labelStyle: labelStyle,
        onTap: () => _openGroupManagement(),
      ),
    );
    if (GlobalData.groupData.groups.isNotEmpty) {
      children.add(
        SpeedDialChild(
          child: const Icon(Icons.download),
          label: tr('export_to_file'),
          backgroundColor: backgroundColor,
          labelBackgroundColor: labelBackgroundColor,
          foregroundColor: foregroundColor,
          labelStyle: labelStyle,
          onTap: () => _exportToFile(context),
        ),
      );
    }
    children.add(
      SpeedDialChild(
        child: const Icon(Icons.upload),
        label: tr('import_from_file'),
        backgroundColor: backgroundColor,
        labelBackgroundColor: labelBackgroundColor,
        foregroundColor: foregroundColor,
        labelStyle: labelStyle,
        onTap: () => _importFromFile(context),
      ),
    );
    return SpeedDial(
      icon: Icons.more_vert,
      children: children,
    );
  }

  @override
  void initState() {
    GlobalData.groupData = GroupData.fromStorage();
    GlobalData.groupData.addListener(_update);
    _updateTabController();
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
    GlobalData.groupData.removeListener(_update);
    super.dispose();
  }
}
