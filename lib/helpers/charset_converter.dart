import 'dart:convert';
import 'package:enough_convert/enough_convert.dart';

class CharsetConverter {
  static const _latin1Codec = Latin1Codec(allowInvalid: true);
  static const _latin2Codec = Latin2Codec(allowInvalid: true);
  static const _latin3Codec = Latin3Codec(allowInvalid: true);
  static const _latin4Codec = Latin4Codec(allowInvalid: true);
  static const _latin5Codec = Latin5Codec(allowInvalid: true);
  static const _latin6Codec = Latin6Codec(allowInvalid: true);
  static const _latin7Codec = Latin7Codec(allowInvalid: true);
  static const _latin8Codec = Latin8Codec(allowInvalid: true);
  static const _latin9Codec = Latin9Codec(allowInvalid: true);
  static const _latin10Codec = Latin10Codec(allowInvalid: true);
  static const _latin11Codec = Latin11Codec(allowInvalid: true);
  static const _latin13Codec = Latin13Codec(allowInvalid: true);
  static const _latin14Codec = Latin14Codec(allowInvalid: true);
  static const _latin15Codec = Latin15Codec(allowInvalid: true);
  static const _latin16Codec = Latin16Codec(allowInvalid: true);
  static const _win1250Codec = Windows1250Codec(allowInvalid: true);
  static const _win1251Codec = Windows1251Codec(allowInvalid: true);
  static const _win1252Codec = Windows1252Codec(allowInvalid: true);
  static const _win1253Codec = Windows1253Codec(allowInvalid: true);
  static const _win1254Codec = Windows1254Codec(allowInvalid: true);
  static const _win1256Codec = Windows1256Codec(allowInvalid: true);
  static const _cp850Codec = CodePage850Codec(allowInvalid: true);
  static const _gbkCodec = GbkCodec(allowInvalid: true);
  static const _koi8rCodec = Koi8rCodec(allowInvalid: true);
  static const _koi8uCodec = Koi8uCodec(allowInvalid: true);
  static const _big5Codec = Big5Codec(allowInvalid: true);
  static const _asciiCodec = AsciiCodec(allowInvalid: true);
  static const _utf8Codec = Utf8Codec(allowMalformed: true);
  static const Map<String, Encoding> _ianaDictionary = {
    // ISO_8859-1:1987
    'iso_8859-1:1987': _latin1Codec,
    'iso-ir-100': _latin1Codec,
    'iso_8859-1': _latin1Codec,
    'iso-8859-1': _latin1Codec,
    'latin1': _latin1Codec,
    'l1': _latin1Codec,
    'ibm819': _latin1Codec,
    'cp819': _latin1Codec,
    'csisolatin1': _latin1Codec,

    // ISO_8859-2:1987
    'iso_8859-2:1987': _latin2Codec,
    'iso-ir-101': _latin2Codec,
    'iso_8859-2': _latin2Codec,
    'iso-8859-2': _latin2Codec,
    'latin2': _latin2Codec,
    'l2': _latin2Codec,
    'csisolatin2': _latin2Codec,

    // ISO_8859-3:1988
    'iso_8859-3:1988': _latin3Codec,
    'iso-ir-109': _latin3Codec,
    'iso_8859-3': _latin3Codec,
    'iso-8859-3': _latin3Codec,
    'latin3': _latin3Codec,
    'l3': _latin3Codec,
    'csisolatin3': _latin3Codec,

    // ISO_8859-4:1988
    'iso_8859-4:1988': _latin4Codec,
    'iso-ir-110': _latin4Codec,
    'iso_8859-4': _latin4Codec,
    'iso-8859-4': _latin4Codec,
    'latin4': _latin4Codec,
    'l4': _latin4Codec,
    'csisolatin4': _latin4Codec,

    // ISO_8859-5:1988
    'iso_8859-5:1988': _latin5Codec,
    'iso-ir-144': _latin5Codec,
    'iso_8859-5': _latin5Codec,
    'iso-8859-5': _latin5Codec,
    'cyrillic': _latin5Codec,
    'csisolatincyrillic': _latin5Codec,

    // ISO_8859-6:1987
    'iso_8859-6:1987': _latin6Codec,
    'iso-ir-127': _latin6Codec,
    'iso_8859-6': _latin6Codec,
    'iso-8859-6': _latin6Codec,
    'ecma-114': _latin6Codec,
    'asmo-708': _latin6Codec,
    'arabic': _latin6Codec,
    'csisolatinarabic': _latin6Codec,

    // ISO_8859-7:1987
    'iso_8859-7:1987': _latin7Codec,
    'iso-ir-126': _latin7Codec,
    'iso_8859-7': _latin7Codec,
    'iso-8859-7': _latin7Codec,
    'elot_928': _latin7Codec,
    'ecma-118': _latin7Codec,
    'greek': _latin7Codec,
    'greek8': _latin7Codec,
    'csisolatingreek': _latin7Codec,

    // ISO_8859-8:1988
    'iso_8859-8:1988': _latin8Codec,
    'iso-ir-138': _latin8Codec,
    'iso_8859-8': _latin8Codec,
    'iso-8859-8': _latin8Codec,
    'hebrew': _latin8Codec,
    'csisolatinhebrew': _latin8Codec,

    // ISO_8859-9:1989
    'iso_8859-9:1989': _latin9Codec,
    'iso-ir-148': _latin9Codec,
    'iso_8859-9': _latin9Codec,
    'iso-8859-9': _latin9Codec,
    'latin5': _latin9Codec,
    'l5': _latin9Codec,
    'csisolatin5': _latin9Codec,

    // ISO-8859-10
    'iso-8859-10': _latin10Codec,
    'iso-ir-157': _latin10Codec,
    'l6': _latin10Codec,
    'iso_8859-10:1992': _latin10Codec,
    'csisolatin6': _latin10Codec,
    'latin6': _latin10Codec,

    // TIS-620
    'tis-620': _latin11Codec,
    'cstis620': _latin11Codec,
    'iso-8859-11': _latin11Codec,

    // ISO-8859-13
    'iso-8859-13': _latin13Codec,
    'csiso885913': _latin13Codec,

    // ISO-8859-14
    'iso-8859-14': _latin14Codec,
    'iso-ir-199': _latin14Codec,
    'iso_8859-14:1998': _latin14Codec,
    'iso_8859-14': _latin14Codec,
    'latin8': _latin14Codec,
    'iso-celtic': _latin14Codec,
    'l8': _latin14Codec,
    'csiso885914': _latin14Codec,

    // ISO-8859-15
    'iso-8859-15': _latin15Codec,
    'iso_8859-15': _latin15Codec,
    'latin-9': _latin15Codec,
    'csiso885915': _latin15Codec,

    // ISO-8859-16
    'iso-8859-16': _latin16Codec,
    'iso-ir-226': _latin16Codec,
    'iso_8859-16:2001': _latin16Codec,
    'iso_8859-16': _latin16Codec,
    'latin10': _latin16Codec,
    'l10': _latin16Codec,
    'csiso885916': _latin16Codec,

    // windows-1250
    'windows-1250': _win1250Codec,
    'cswindows1250': _win1250Codec,

    // windows-1251
    'windows-1251': _win1251Codec,
    'cswindows1251': _win1251Codec,

    // windows-1252
    'windows-1252': _win1252Codec,
    'cswindows1252': _win1252Codec,

    // windows-1253
    'windows-1253': _win1253Codec,
    'cswindows1253': _win1253Codec,

    // windows-1254
    'windows-1254': _win1254Codec,
    'cswindows1254': _win1254Codec,

    // windows-1256
    'windows-1256': _win1256Codec,
    'cswindows1256': _win1256Codec,

    // IBM850
    'ibm850': _cp850Codec,
    'cp850': _cp850Codec,
    '850': _cp850Codec,
    'cspc850multilingual': _cp850Codec,

    // GBK
    'gbk': _gbkCodec,
    'cp936': _gbkCodec,
    'ms936': _gbkCodec,
    'windows-936': _gbkCodec,
    'csgbk': _gbkCodec,

    // KOI8-R
    'koi8-r': _koi8rCodec,
    'cskoi8r': _koi8rCodec,

    // KOI8-U
    'koi8-u': _koi8uCodec,
    'cskoi8u': _koi8uCodec,

    // Big5
    'big5': _big5Codec,
    'csbig5': _big5Codec,

    // US-ASCII
    'iso-ir-6': _asciiCodec,
    'ansi_x3.4-1968': _asciiCodec,
    'ansi_x3.4-1986': _asciiCodec,
    'iso_646.irv:1991': _asciiCodec,
    'iso646-us': _asciiCodec,
    'us-ascii': _asciiCodec,
    'us': _asciiCodec,
    'ibm367': _asciiCodec,
    'cp367': _asciiCodec,
    'csascii': _asciiCodec,
    'ascii': _asciiCodec, // this is not in the IANA official names

    // UTF-8
    'utf-8': _utf8Codec,
    'csutf8': _utf8Codec,
  };

  static Encoding getCodecForCharset(String? charset) {
    return charset != null
        ? (_ianaDictionary[charset.toLowerCase()] ?? _utf8Codec)
        : _utf8Codec;
  }
}
