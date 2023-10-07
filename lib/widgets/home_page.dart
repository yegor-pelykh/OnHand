import 'dart:convert';
import 'dart:html' as p_html;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:on_hand/data/group_storage.dart';
import 'package:on_hand/global/global_constants.dart';
import 'package:on_hand/global/global_data.dart';
import 'package:on_hand/widgets/bookmark_editor.dart';
import 'package:on_hand/widgets/bookmarks_view.dart';
import 'package:on_hand/widgets/expandable_fab.dart';
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
  final _fabKey = GlobalKey<ExpandableFabState>();
  TabController? _tabController;
  int _activeGroupIndex = -1;
  bool _isFabOpen = false;

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
          indicatorColor: Theme.of(context).colorScheme.primary,
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

  Widget _getFabMenuItem({
    required Widget icon,
    required Widget label,
    required void Function() onPressed,
  }) {
    final tooltipBackground = Theme.of(context).colorScheme.primaryContainer;
    final tooltipForeground = Theme.of(context).colorScheme.onPrimaryContainer;
    final tooltipShadowColor = Theme.of(context).colorScheme.shadow;
    final tooltipSplashColor = tooltipForeground.withOpacity(0.12);
    final tooltipFocusColor = tooltipForeground.withOpacity(0.12);
    final tooltipHoverColor = tooltipForeground.withOpacity(0.08);
    final List<Widget> children = [];
    if (_isFabOpen) {
      children.addAll([
        Material(
          color: tooltipBackground,
          shadowColor: tooltipShadowColor,
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            splashColor: tooltipSplashColor,
            focusColor: tooltipFocusColor,
            hoverColor: tooltipHoverColor,
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: label,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ]);
    }
    children.add(
      FloatingActionButton.small(
        onPressed: onPressed,
        elevation: 4,
        child: icon,
      ),
    );
    return Row(children: children);
  }

  Widget _getFabMenu(BuildContext context) {
    final List<Widget> children = [];

    if (_activeGroupIndex >= 0) {
      children.add(
        _getFabMenuItem(
          icon: const Icon(Icons.add),
          label: Text(tr('create_bookmark')),
          onPressed: () {
            _createBookmark(context);
            _fabKey.currentState?.toggle();
          },
        ),
      );
    }
    children.add(
      _getFabMenuItem(
        icon: const Icon(Icons.apps),
        label: Text(tr('group_management')),
        onPressed: () {
          _openGroupManagement();
          _fabKey.currentState?.toggle();
        },
      ),
    );
    if (GlobalData.groupStorage.isNotEmpty) {
      children.add(
        _getFabMenuItem(
          icon: const Icon(Icons.download),
          label: Text(tr('export_to_file')),
          onPressed: () {
            _exportToFile(context);
            _fabKey.currentState?.toggle();
          },
        ),
      );
    }
    children.add(
      _getFabMenuItem(
        icon: const Icon(Icons.upload),
        label: Text(tr('import_from_file')),
        onPressed: () {
          _importFromFile(context);
          _fabKey.currentState?.toggle();
        },
      ),
    );

    return ExpandableFab(
      key: _fabKey,
      type: ExpandableFabType.up,
      childrenOffset: const Offset(8, 16),
      distance: 56,
      overlayStyle: ExpandableFabOverlayStyle(
        color: Colors.black.withOpacity(0.5),
      ),
      afterOpen: (() => setState(() => _isFabOpen = true)),
      beforeClose: (() => setState(() => _isFabOpen = false)),
      children: children,
    );
  }

  @override
  void initState() {
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
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: _getFabMenu(context),
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
