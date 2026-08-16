import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

class FontMetadata {
  final String? familyName;
  final String? postScriptName;
  final String? fullName;

  FontMetadata({this.familyName, this.postScriptName, this.fullName});

  @override
  String toString() {
    return 'FontMetadata(familyName: $familyName, postScriptName: $postScriptName, fullName: $fullName)';
  }
}

class FontMetadataReader {
  FontMetadataReader._();

  /// Parse TrueType/OpenType font file binary to extract metadata.
  static Future<FontMetadata?> readMetadata(File file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length < 12) return null;

      final data = ByteData.sublistView(bytes);
      final numTables = data.getUint16(4);

      int nameTableOffset = -1;

      for (int i = 0; i < numTables; i++) {
        final entryOffset = 12 + (i * 16);
        if (entryOffset + 16 > bytes.length) break;

        // Reading table tag bytes
        final tagCodes = bytes.sublist(entryOffset, entryOffset + 4);
        final tag = String.fromCharCodes(tagCodes);
        if (tag == 'name') {
          nameTableOffset = data.getUint32(entryOffset + 8);
          break;
        }
      }

      if (nameTableOffset == -1 || nameTableOffset + 6 > bytes.length) return null;

      final count = data.getUint16(nameTableOffset + 2);
      final stringOffset = data.getUint16(nameTableOffset + 4);

      String? familyName;
      String? postScriptName;
      String? fullName;

      for (int i = 0; i < count; i++) {
        final recordOffset = nameTableOffset + 6 + (i * 12);
        if (recordOffset + 12 > bytes.length) break;

        final platformId = data.getUint16(recordOffset);
        final nameId = data.getUint16(recordOffset + 6);
        final length = data.getUint16(recordOffset + 8);
        final offset = data.getUint16(recordOffset + 10);

        // We target:
        // Name ID 1: Font Family Name
        // Name ID 4: Full Font Name
        // Name ID 6: PostScript Name
        if (nameId == 1 || nameId == 4 || nameId == 6) {
          final absStringOffset = nameTableOffset + stringOffset + offset;
          if (absStringOffset + length > bytes.length) continue;

          final stringBytes = bytes.sublist(absStringOffset, absStringOffset + length);
          
          String decoded = '';
          if (platformId == 0 || platformId == 3) {
            // UTF-16BE encoding (Unicode or Windows platforms)
            final chars = <int>[];
            for (int j = 0; j < length; j += 2) {
              if (j + 1 < length) {
                chars.add((stringBytes[j] << 8) | stringBytes[j + 1]);
              }
            }
            decoded = String.fromCharCodes(chars);
          } else {
            // Mac/ISO standard (mostly UTF-8/ASCII)
            decoded = utf8.decode(stringBytes, allowMalformed: true);
          }

          decoded = decoded.trim();
          if (decoded.isNotEmpty) {
            if (nameId == 1) {
              familyName ??= decoded;
            } else if (nameId == 4) {
              fullName ??= decoded;
            } else if (nameId == 6) {
              postScriptName ??= decoded;
            }
          }
        }
      }

      return FontMetadata(
        familyName: familyName,
        postScriptName: postScriptName,
        fullName: fullName,
      );
    } catch (_) {
      return null;
    }
  }
}
