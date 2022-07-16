import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:on_hand/data/bookmark_info.dart';
import 'package:on_hand/data/global_data.dart';
import 'package:on_hand/helpers/image_helper.dart';
import 'package:on_hand/helpers/url_launcher.dart';
import 'package:on_hand/widgets/bookmark_editor.dart';

enum _BookmarkMenuAction {
  edit,
  delete,
}

const double iconSize = 24;

class BookmarkTile extends StatefulWidget {
  final BookmarkInfo bookmark;

  const BookmarkTile(this.bookmark, {super.key});

  @override
  State<BookmarkTile> createState() => _BookmarkTileState();
}

class _BookmarkTileState extends State<BookmarkTile> {
  bool _isCtrlKeyPressed() {
    final keys = RawKeyboard.instance.keysPressed;
    return keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight);
  }

  void _editBookmark(BuildContext context) {
    final groupTitle = widget.bookmark.group.title;
    showDialog<BookmarkEditorResult?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(tr('bookmark_editing_dlg_title')),
          content: BookmarkEditor(
            BookmarkEditorMode.edit,
            initialAddress: widget.bookmark.url.toString(),
            initialTitle: widget.bookmark.title,
            selectedGroup: groupTitle,
            groups: GlobalData.groupData.groups.map((g) => g.title).toList(),
          ),
        );
      },
    ).then((result) {
      if (result != null) {
        widget.bookmark.url = result.url;
        widget.bookmark.title = result.title;
        widget.bookmark.icon = result.icon;
        if (result.groupTitle != groupTitle) {
          GlobalData.groupData.moveBookmark(widget.bookmark, result.groupTitle);
        }
        GlobalData.groupData.saveToStorage();
        GlobalData.updateNotifier.notify();
      }
    });
  }

  void _deleteBookmark(BuildContext context) {
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
        final group = widget.bookmark.group;
        group.removeBookmark(widget.bookmark);
        GlobalData.groupData.saveToStorage();
        GlobalData.updateNotifier.notify();
      }
    });
  }

  Widget _getLeadingWidget() {
    Widget imageWidget;
    if (widget.bookmark.icon != null) {
      if (ImageHelper.isPng(widget.bookmark.icon!)) {
        imageWidget = Image.memory(
          widget.bookmark.icon!,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
          isAntiAlias: true,
          filterQuality: FilterQuality.medium,
        );
      } else {
        final content =
            utf8.decode(widget.bookmark.icon!, allowMalformed: true);
        imageWidget = ScalableImageWidget(
          si: ScalableImage.fromSvgString(content),
          fit: BoxFit.cover,
        );
      }
    } else {
      imageWidget = const Icon(
        Icons.favorite,
        color: GlobalData.mainColor,
      );
    }
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: imageWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.bookmark.url;
    final title = widget.bookmark.title;
    const textHeightBehavior = TextHeightBehavior(
      applyHeightToFirstAscent: false,
      applyHeightToLastDescent: false,
      leadingDistribution: TextLeadingDistribution.even,
    );
    return SizedBox(
      width: 300,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          onTap: () {
            UrlLauncher.launch(url, _isCtrlKeyPressed());
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTertiaryTapUp: (details) {
              UrlLauncher.launch(url, true);
            },
            child: ListTile(
              dense: true,
              minLeadingWidth: iconSize,
              leading: _getLeadingWidget(),
              title: Text(
                title,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                maxLines: 1,
                textHeightBehavior: textHeightBehavior,
              ),
              subtitle: Text(
                url.toString(),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                maxLines: 1,
                textHeightBehavior: textHeightBehavior,
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
                      _editBookmark(context);
                      break;
                    case _BookmarkMenuAction.delete:
                      _deleteBookmark(context);
                      break;
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
