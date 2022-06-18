import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_hand/data/bookmark_info.dart';
import 'package:on_hand/data/dummy_data.dart';
import 'package:on_hand/data/global_data.dart';
import 'package:on_hand/data/group_info.dart';
import 'package:on_hand/widgets/bookmark_editor.dart';
import 'package:reorderables/reorderables.dart';
import 'package:url_launcher/url_launcher.dart';

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
  void _editBookmark(BookmarkInfo bookmark) {
    final groupTitle = bookmark.group.title;
    showDialog<BookmarkEditorResult?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Edit bookmark'),
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
        GlobalData.groupData.saveGroups();
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
          title: const Text('Delete bookmark'),
          content: const Text('Are you sure you want to delete this bookmark?'),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: const Text('Yes'),
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
        GlobalData.groupData.saveGroups();
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
                  bottom: BorderSide(width: 1, color: Theme.of(context).colorScheme.secondary),
                ),
                color: Theme.of(context).colorScheme.tertiary,
              ),
              child: InkWell(
                onTap: () {
                  final isCtrlPressed = RawKeyboard.instance.keysPressed.contains(
                    LogicalKeyboardKey.controlLeft,
                  );
                  final windowName = isCtrlPressed ? '_blank' : '_self';
                  launchUrl(b.url, webOnlyWindowName: windowName);
                },
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
                              children: const <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(Icons.edit),
                                ),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: _BookmarkMenuAction.delete,
                            child: Row(
                              children: const <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(Icons.delete),
                                ),
                                Text('Delete'),
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
        )
        .toList();
    return bookmarks;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(80),
        child: Center(
          child: ReorderableWrap(
            spacing: 16,
            runSpacing: 16,
            onReorder: (oldIndex, newIndex) {
              widget.group.moveBookmark(oldIndex, newIndex);
              GlobalData.groupData.saveGroups();
              GlobalData.updateNotifier.notify();
            },
            children: _getBookmarks(),
          ),
        ),
      ),
    );
  }
}
