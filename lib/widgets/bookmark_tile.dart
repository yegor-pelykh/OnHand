import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:on_hand/data/bookmark.dart';
import 'package:on_hand/global/global_constants.dart';
import 'package:on_hand/global/global_data.dart';
import 'package:on_hand/helpers/image_helper.dart';
import 'package:on_hand/helpers/metadata_provider.dart';
import 'package:on_hand/helpers/url_launcher.dart';
import 'package:on_hand/helpers/utils.dart';
import 'package:on_hand/widgets/bookmark_editor.dart';

const double iconSize = 24;

class BookmarkTile extends StatefulWidget {
  final Bookmark bookmark;
  final void Function(int groupIndex) funcActivateGroup;

  const BookmarkTile({
    super.key,
    required this.bookmark,
    required this.funcActivateGroup,
  });

  @override
  State<BookmarkTile> createState() => _BookmarkTileState();
}

class _BookmarkTileState extends State<BookmarkTile> {
  void _editBookmark(BuildContext context, Bookmark bookmark) {
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
            selectedGroupTitle: groupTitle,
            groupTitles: GlobalData.groupStorage.titles,
          ),
        );
      },
    ).then((result) {
      if (result != null) {
        bookmark.url = result.url;
        bookmark.title = result.title;
        bookmark.icon = result.icon;
        if (result.groupTitle != groupTitle) {
          final toGroupIndex = GlobalData.groupStorage.groupIndexWhere(
            (g) => g.title == result.groupTitle,
          );
          if (toGroupIndex >= 0) {
            final toGroup = GlobalData.groupStorage.groupAt(toGroupIndex);
            if (toGroup != null) {
              setState(() {
                GlobalData.moveBookmarkToGroup(bookmark, toGroup);
                widget.funcActivateGroup(toGroupIndex);
              });
            }
          }
        }
        GlobalData.saveToStorage();
      }
    });
  }

  Future<void> _refreshBookmarkIcon(Bookmark bookmark) async {
    bookmark.isIconRefresh = true;
    final metadata = await MetadataProvider.getMetadata(bookmark.url);
    final success = metadata != null && metadata.icon != null;
    if (success) {
      bookmark.icon = metadata.icon!.bytes;
      await GlobalData.saveToStorage();
    }
    bookmark.isIconRefresh = false;
  }

  void _deleteBookmark(BuildContext context, Bookmark bookmark) {
    showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(tr('bookmark_deleting_dlg_title')),
          content: Text(tr('bookmark_deleting_dlg_content')),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
        GlobalData.saveToStorage();
      }
    });
  }

  bool _isCtrlKeyPressed() {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    return keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight);
  }

  Widget _getLeadingWidget() {
    Widget imageWidget;
    if (widget.bookmark.isIconRefresh) {
      imageWidget = const CircularProgressIndicator(
        strokeWidth: 2,
      );
    } else {
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
          color: GlobalConstants.mainColor,
          size: iconSize,
        );
      }
    }
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: imageWidget,
    );
  }

  void _showBookmarkMenu(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      constraints: const BoxConstraints(
        maxWidth: 400,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (context) {
        final errorColor = Theme.of(context).colorScheme.error;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              dense: true,
              minLeadingWidth: iconSize,
              leading: _getLeadingWidget(),
              title: Text(
                widget.bookmark.title,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                maxLines: 1,
              ),
              subtitle: Text(
                Utils.getUriString(widget.bookmark.url),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                maxLines: 1,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(tr('edit')),
              onTap: () {
                Navigator.pop(context);
                _editBookmark(context, widget.bookmark);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: Text(tr('refresh_bookmark_icon')),
              onTap: () {
                Navigator.pop(context);
                _refreshBookmarkIcon(widget.bookmark);
              },
            ),
            ListTile(
              iconColor: errorColor,
              textColor: errorColor,
              leading: const Icon(Icons.delete),
              title: Text(tr('delete')),
              onTap: () {
                Navigator.pop(context);
                _deleteBookmark(context, widget.bookmark);
              },
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tileColor = Color.lerp(
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.surface,
      0.9,
    );
    final url = widget.bookmark.url;
    final title = widget.bookmark.title;
    return SizedBox(
      width: 200,
      height: 54,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 4,
        color: tileColor,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
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
              ),
              subtitle: Text(
                Utils.getUriString(url),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                maxLines: 1,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  _showBookmarkMenu(context);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
