import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_hand/data/bookmark_info.dart';
import 'package:on_hand/data/dummy_data.dart';
import 'package:on_hand/data/global_data.dart';
import 'package:on_hand/data/group_info.dart';
import 'package:on_hand/helpers/url_launcher.dart';
import 'package:on_hand/widgets/bookmark_editor.dart';
import 'package:reorderables/reorderables.dart';

enum _BookmarkMenuAction {
  edit,
  delete,
}

class BookmarksView extends StatefulWidget {
  final GroupInfo group;

  const BookmarksView(this.group, {super.key});

  @override
  State<BookmarksView> createState() => _BookmarksViewState();
}

class _BookmarksViewState extends State<BookmarksView> {
  bool _isCtrlKeyPressed() {
    final keys = RawKeyboard.instance.keysPressed;
    return keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight);
  }

  void _editBookmark(BookmarkInfo bookmark) {
    final groupTitle = bookmark.group.title;
    showDialog<BookmarkEditorResult?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(tr('bookmark_editing_dlg_title')),
          content: BookmarkEditor(
            BookmarkEditorMode.edit,
            initialAddress: bookmark.url.toString(),
            initialTitle: bookmark.title,
            selectedGroup: groupTitle,
            groups: GlobalData.groupData.groups.map((g) => g.title).toList(),
          ),
        );
      },
    ).then((result) {
      if (result != null) {
        bookmark.url = result.url;
        bookmark.title = result.title;
        bookmark.icon = result.icon;
        if (result.groupTitle != groupTitle) {
          GlobalData.groupData.moveBookmark(bookmark, result.groupTitle);
        }
        GlobalData.groupData.saveToStorage();
        GlobalData.updateNotifier.notify();
      }
    });
  }

  void _deleteBookmark(BookmarkInfo bookmark) {
    showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(tr('bookmark_deleting_dlg_title')),
          content: Text(tr('bookmark_deleting_dlg_content')),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
        final group = bookmark.group;
        group.removeBookmark(bookmark);
        GlobalData.groupData.saveToStorage();
        GlobalData.updateNotifier.notify();
      }
    });
  }

  List<Widget> _getBookmarks() {
    final bookmarks = widget.group.bookmarks
        .map(
          (b) => Card(
            clipBehavior: Clip.hardEdge,
            margin: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Ink(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      width: 1, color: Theme.of(context).colorScheme.secondary),
                ),
                color: Theme.of(context).colorScheme.tertiary,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  UrlLauncher.launch(b.url, _isCtrlKeyPressed());
                },
                onTertiaryTapUp: (details) {
                  UrlLauncher.launch(b.url, true);
                },
                child: InkWell(
                  child: SizedBox(
                    width: 300,
                    child: ListTile(
                      dense: true,
                      mouseCursor: SystemMouseCursors.click,
                      leading: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        child: Container(
                          width: 24,
                          height: 24,
                          color: Colors.white,
                          child: Image.memory(
                            b.icon ?? DummyData.dummyIcon,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            isAntiAlias: true,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ),
                      minLeadingWidth: 28,
                      title: Text(
                        b.title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      subtitle: Text(
                        b.url.toString(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      trailing: PopupMenuButton(
                        tooltip: '',
                        itemBuilder: (context) {
                          return [
                            PopupMenuItem(
                              value: _BookmarkMenuAction.edit,
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
                              value: _BookmarkMenuAction.delete,
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
                        onSelected: (_BookmarkMenuAction value) {
                          switch (value) {
                            case _BookmarkMenuAction.edit:
                              _editBookmark(b);
                              break;
                            case _BookmarkMenuAction.delete:
                              _deleteBookmark(b);
                              break;
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
        .toList();
    return bookmarks;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.group.bookmarks.isNotEmpty) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(80),
          child: Center(
            child: ReorderableWrap(
              spacing: 16,
              runSpacing: 16,
              onReorder: (oldIndex, newIndex) {
                widget.group.moveBookmark(oldIndex, newIndex);
                GlobalData.groupData.saveToStorage();
                GlobalData.updateNotifier.notify();
              },
              children: _getBookmarks(),
            ),
          ),
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('group_no_bookmarks_hint'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: 0.5,
              child: Text(
                tr('group_no_bookmarks_hint_details'),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
  }
}
