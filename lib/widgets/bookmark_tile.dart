import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:on_hand/data/bookmark_info.dart';
import 'package:on_hand/global/global_data.dart';
import 'package:on_hand/helpers/image_helper.dart';
import 'package:on_hand/helpers/url_launcher.dart';

const double iconSize = 24;
const textHeightBehavior = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
  leadingDistribution: TextLeadingDistribution.even,
);

class BookmarkTile extends StatefulWidget {
  final BookmarkInfo bookmark;
  final Function(BuildContext context, BookmarkInfo bookmark) editFunc;
  final Function(BuildContext context, BookmarkInfo bookmark) deleteFunc;

  const BookmarkTile(
    this.bookmark,
    this.editFunc,
    this.deleteFunc, {
    super.key,
  });

  @override
  State<BookmarkTile> createState() => _BookmarkTileState();
}

class _BookmarkTileState extends State<BookmarkTile> {
  bool _isCtrlKeyPressed() {
    final keys = RawKeyboard.instance.keysPressed;
    return keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight);
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

  void _showBookmarkMenu(
    BuildContext context,
    TextHeightBehavior textHeightBehavior,
  ) {
    showModalBottomSheet(
      context: context,
      constraints: const BoxConstraints(
        maxWidth: 400,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (context) {
        final errorColor = Theme.of(context).colorScheme.error;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              color: Theme.of(context).cardColor,
              child: ListTile(
                dense: true,
                minLeadingWidth: iconSize,
                leading: _getLeadingWidget(),
                title: Text(
                  widget.bookmark.title,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1,
                  textHeightBehavior: textHeightBehavior,
                ),
                subtitle: Text(
                  widget.bookmark.url.toString(),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1,
                  textHeightBehavior: textHeightBehavior,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(tr('edit')),
              onTap: () {
                Navigator.pop(context);
                widget.editFunc(context, widget.bookmark);
              },
            ),
            ListTile(
              iconColor: errorColor,
              textColor: errorColor,
              leading: const Icon(Icons.delete),
              title: Text(tr('delete')),
              onTap: () {
                Navigator.pop(context);
                widget.deleteFunc(context, widget.bookmark);
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
    final url = widget.bookmark.url;
    final title = widget.bookmark.title;
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
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  _showBookmarkMenu(context, textHeightBehavior);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
