import 'dart:typed_data';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as p_html;
import 'package:image/image.dart' as p_image;
import 'package:dio/dio.dart' as p_dio;
import 'package:on_hand/helpers/charset_converter.dart';

const signatureIco = [0, 0, 1, 0];
const signaturePng = [137, 80, 78, 71, 13, 10, 26, 10];

const charsetValueMark = 'charset=';
const contentTypeFlagPng = 'png';
const contentTypeFlagSvg = 'svg+xml';

class Metadata {
  String? title;
  IconData? icon;

  Metadata(
    this.title, {
    this.icon,
  });
}

class IconData implements Comparable<IconData> {
  String contentType;
  Uint8List bytes;
  int width;
  int height;

  IconData(
    this.contentType,
    this.bytes, {
    this.width = 0,
    this.height = 0,
  });

  @override
  int compareTo(IconData other) {
    // Sort vector graphics before bitmaps
    if (contentType.contains(contentTypeFlagSvg)) return -1;
    if (other.contentType.contains(contentTypeFlagSvg)) return 1;

    // Sort on bitmap size
    return (width * height > other.width * other.height) ? -1 : 1;
  }
}

abstract class MetadataProvider {
  static final p_dio.Dio _dio = p_dio.Dio();
  static p_dio.CancelToken? _cancelToken;

  static Future<Metadata?> getMetadata(Uri uri) async {
    if (_cancelToken != null) {
      _cancelToken!.cancel();
      _cancelToken = null;
    }
    _cancelToken = p_dio.CancelToken();
    final document = await _getHtml(uri);
    if (document == null) {
      return null;
    }
    final title = _getTitle(document);
    final iconData = await _getIconData(uri, document);
    return Metadata(title, icon: iconData);
  }

  static String? _getCharsetFromResponseBody(p_dio.ResponseBody responseBody) {
    final contentTypeValue = responseBody.headers['content-type']?.first;
    if (contentTypeValue != null) {
      final charsetMarkIndex = contentTypeValue.lastIndexOf(charsetValueMark);
      if (charsetMarkIndex >= 0) {
        final charsetStartIndex = charsetMarkIndex + charsetValueMark.length;
        final charsetEndIndex =
            contentTypeValue.indexOf(';', charsetStartIndex);
        final charset = contentTypeValue.substring(
          charsetStartIndex,
          charsetEndIndex >= 0 ? charsetEndIndex : null,
        );
        return charset.toLowerCase();
      }
    }
    return null;
  }

  static String _decodeHtmlBytes(
    List<int> responseBytes,
    p_dio.RequestOptions options,
    p_dio.ResponseBody responseBody,
  ) {
    final charset = _getCharsetFromResponseBody(responseBody);
    final codec = CharsetConverter.getCodecForCharset(charset);
    return codec.decode(responseBytes);
  }

  static Future<Document?> _getHtml(Uri uri) async {
    try {
      final response = await _dio.getUri(
        uri,
        cancelToken: _cancelToken,
        options: p_dio.Options(
          receiveDataWhenStatusError: true,
          responseDecoder: _decodeHtmlBytes,
        ),
      );
      return p_html.parse(response.data);
    } catch (ex) {
      return null;
    }
  }

  static String? _getTitle(Document document) {
    if (document.head == null) return null;
    final tags = document.head!.getElementsByTagName('title');
    return tags.isNotEmpty ? tags.first.text : null;
  }

  static Future<IconData?> _getIconData(Uri uri, Document document) async {
    List<IconData> iconDataList = <IconData>[];

    // Look for icons in tags
    for (var rel in ['icon', 'shortcut icon']) {
      for (var iconTag in document.querySelectorAll('link[rel=\'$rel\']')) {
        if (iconTag.attributes['href'] != null) {
          var strUrl = iconTag.attributes['href']!.trim();

          // Fix scheme relative URLs
          if (strUrl.startsWith('//')) {
            strUrl = '${uri.scheme}:$strUrl';
          }

          // Fix relative URLs
          if (strUrl.startsWith('/')) {
            strUrl = '${uri.scheme}://${uri.host}$strUrl';
          }

          // Fix naked URLs
          if (!strUrl.startsWith('http')) {
            strUrl = '${uri.scheme}://${uri.host}/$strUrl';
          }

          // Remove query strings
          strUrl = strUrl.split('?').first;

          final imageUri = Uri.parse(strUrl);
          final iconData = await _getIconDataByUrl(imageUri);
          if (iconData != null) {
            iconDataList.add(iconData);
          }
        }
      }
    }

    // Look for icon by predefined URL
    final imageUri = Uri.parse('${uri.scheme}://${uri.host}/favicon.ico');
    final iconData = await _getIconDataByUrl(imageUri);
    if (iconData != null) {
      iconDataList.add(iconData);
    }

    if (iconDataList.isEmpty) {
      return null;
    }

    // Deduplicate and sort
    iconDataList = iconDataList.toSet().toList();
    iconDataList.sort();

    return iconDataList.first;
  }

  static Future<IconData?> _getIconDataByUrl(Uri uri) async {
    p_dio.Response response;
    try {
      response = await _dio.getUri(
        uri,
        cancelToken: _cancelToken,
        options: p_dio.Options(responseType: p_dio.ResponseType.bytes),
      );
    } catch (ex) {
      return null;
    }
    if (response.statusCode != 200) {
      return null;
    }
    String? contentType = response.headers.value('content-type');
    if (contentType == null || !contentType.contains('image')) {
      return null;
    }
    Uint8List imageBytes = response.data as Uint8List;
    if (contentType.contains(contentTypeFlagSvg)) {
      return IconData(contentType, imageBytes);
    } else {
      p_image.Image? image =
          p_image.IcoDecoder().decodeImageLargest(imageBytes);
      image ??= p_image.decodeImage(imageBytes);
      if (image == null) {
        return null;
      }
      imageBytes = Uint8List.fromList(p_image.encodePng(image));
      contentType = 'image/$contentTypeFlagPng';
      return IconData(
        contentType,
        imageBytes,
        width: image.width,
        height: image.height,
      );
    }
  }
}
