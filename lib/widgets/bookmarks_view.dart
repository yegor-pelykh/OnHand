import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:on_hand/data/bookmark_info.dart';
import 'package:on_hand/global/global_data.dart';
import 'package:on_hand/data/group_info.dart';
import 'package:on_hand/widgets/bookmark_tile.dart';
import 'package:reorderables/reorderables.dart';

class BookmarksView extends StatefulWidget {
  final GroupInfo group;
  final Function(BuildContext context, BookmarkInfo bookmark) editFunc;
  final Function(BuildContext context, BookmarkInfo bookmark) deleteFunc;

  const BookmarksView(
    this.group,
    this.editFunc,
    this.deleteFunc, {
    super.key,
  });

  @override
  State<BookmarksView> createState() => _BookmarksViewState();
}

class _BookmarksViewState extends State<BookmarksView> {
  List<BookmarkTile> _getBookmarks() {
    return widget.group.bookmarks
        .map((b) => BookmarkTile(b, widget.editFunc, widget.deleteFunc))
        .toList();
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
                GlobalData.appData.saveToStorage();
                GlobalData.appData.notifyChanged();
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
