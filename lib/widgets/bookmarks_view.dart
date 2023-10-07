import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:on_hand/data/group.dart';
import 'package:on_hand/global/global_data.dart';
import 'package:on_hand/widgets/bookmark_tile.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

const viewPadding = 88.0;
const gridChildSize = Size(300, 54);
const gridSpacing = Size(16, 16);
const gridChildPlaceholderOpacity = 0.2;

class BookmarksView extends StatefulWidget {
  final Group group;
  final void Function(int groupIndex) funcActivateGroup;

  const BookmarksView(
    this.group,
    this.funcActivateGroup, {
    super.key,
  });

  @override
  State<BookmarksView> createState() => _BookmarksViewState();
}

class _BookmarksViewState extends State<BookmarksView> {
  @override
  Widget build(BuildContext context) {
    if (widget.group.bookmarks.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(viewPadding),
        scrollDirection: Axis.vertical,
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columnCount = (constraints.maxWidth + gridSpacing.width) ~/
                  (gridChildSize.width + gridSpacing.width);
              final realChildWidth =
                  (constraints.maxWidth + gridSpacing.width) / columnCount -
                      gridSpacing.width;
              final childAspectRatio = realChildWidth / gridChildSize.height;
              return ReorderableGridView.count(
                shrinkWrap: true,
                crossAxisCount: columnCount,
                crossAxisSpacing: gridSpacing.width,
                mainAxisSpacing: gridSpacing.height,
                childAspectRatio: childAspectRatio,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    widget.group.moveBookmark(oldIndex, newIndex);
                    GlobalData.saveToStorage();
                  });
                },
                dragWidgetBuilder: (index, child) => child,
                placeholderBuilder: (dragIndex, dropIndex, dragWidget) =>
                    Opacity(
                  opacity: gridChildPlaceholderOpacity,
                  child: dragWidget,
                ),
                children: widget.group.bookmarks
                    .map((bookmark) => BookmarkTile(
                          key: ValueKey(bookmark),
                          bookmark: bookmark,
                          funcActivateGroup: widget.funcActivateGroup,
                        ))
                    .toList(),
              );
            },
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
