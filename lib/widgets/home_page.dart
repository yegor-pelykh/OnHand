import 'dart:convert';
import 'dart:html' as p_html;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:on_hand/data/group_storage.dart';
import 'package:on_hand/global/global_constants.dart';
import 'package:on_hand/global/global_data.dart';
import 'package:on_hand/widgets/bookmark_editor.dart';
import 'package:on_hand/widgets/bookmarks_view.dart';
import 'package:on_hand/widgets/file_uploader.dart';
import 'package:on_hand/widgets/groups_manager.dart';

const double kTabIndicatorWeight = 2.0;
const prefKeyActiveGroupIndex = 'index';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  TabController? _tabController;
  int _activeGroupIndex = -1;

  void _onTabIndexChange() {
    if (_tabController != null) {
      _activeGroupIndex = _tabController!.index;
    }
  }

  void _activateTab(int index) {
    if (_tabController != null) {
      _tabController!.index = index;
    }
  }

  void _updateTabController() {
    _tabController?.removeListener(_onTabIndexChange);
    _activeGroupIndex = _normalizeGroupIndex(
      _activeGroupIndex,
      GlobalData.groupStorage.groupsLength,
    );
    if (GlobalData.groupStorage.isNotEmpty) {
      _tabController = TabController(
        animationDuration: Duration.zero,
        length: GlobalData.groupStorage.groupsLength,
        initialIndex: _activeGroupIndex,
        vsync: this,
      );
    } else {
      _tabController = null;
    }
    _tabController?.addListener(_onTabIndexChange);
  }

  void _update() {
    setState(() {
      _updateTabController();
    });
  }

  void _createBookmark(BuildContext context) async {
    final groupIndex = _activeGroupIndex;
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
            groupTitles: GlobalData.groupStorage.titles,
            selectedGroupTitle:
                GlobalData.groupStorage.groupAt(groupIndex)?.title ?? '',
          ),
        );
      },
    ).then((result) {
      if (result != null) {
        final groupIndex = GlobalData.groupStorage.groupIndexWhere(
          (g) => g.title == result.groupTitle,
        );
        if (groupIndex >= 0) {
          final group = GlobalData.groupStorage.groupAt(groupIndex);
          if (group != null) {
            setState(() {
              group.addBookmark(result.url, result.title, result.icon);
              GlobalData.saveToStorage();
              _tabController?.index = groupIndex;
            });
          }
        }
      }
    });
  }

  void _openGroupManagement() async {
    showDialog<GroupStorage?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(tr('group_management_dlg_title')),
          content: const GroupsManager(),
        );
      },
    ).then((groupStorage) {
      if (groupStorage != null) {
        GlobalData.groupStorage.replaceFrom(groupStorage);
        GlobalData.saveToStorage();
      }
    });
  }

  void _downloadFile(String content, String extension) {
    final bytes = utf8.encode(content);
    final uri = Uri.dataFromBytes(bytes, mimeType: 'application/json');
    final anchor = p_html.AnchorElement();
    anchor.href = uri.toString();
    anchor.style.display = 'none';
    anchor.download = 'bookmarks.$extension';
    anchor.click();
    anchor.remove();
  }

  void _downloadData() {
    final jsonString = GlobalData.groupStorage.json;
    final ext = GlobalConstants.dataFileExtension.toLowerCase();
    _downloadFile(jsonString, ext);
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
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
    if (_tabController != null && GlobalData.groupStorage.isNotEmpty) {
      appBarChildren.add(
        TabBar(
          controller: _tabController,
          indicatorWeight: kTabIndicatorWeight,
          isScrollable: true,
          tabs: GlobalData.groupStorage
              .groupsMap(
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
    if (_tabController != null) {
      if (GlobalData.groupStorage.isNotEmpty) {
        return TabBarView(
          controller: _tabController,
          children: GlobalData.groupStorage
              .groupsMap((g) => BookmarksView(g, _activateTab))
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
    } else {
      return Container();
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
    if (_activeGroupIndex >= 0) {
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
    if (GlobalData.groupStorage.isNotEmpty) {
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
  Future<void> initState() async {
    GlobalData.groupStorage.addListener(_update);
    GlobalData.loadFromStorage().whenComplete(() {
      GlobalData.subscribeToStorageChange();
    });
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
    GlobalData.unsubscribeFromStorageChange();
    GlobalData.groupStorage.removeListener(_update);
    super.dispose();
  }

  static int _normalizeGroupIndex(int index, int groupsLength) =>
      groupsLength > 0 ? index.clamp(0, groupsLength - 1) : -1;
}
