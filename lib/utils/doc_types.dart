import 'package:flutter/material.dart';

/// How a shared document looks: a family glyph on a tinted tile.
///
/// THE ONE fixed list, never a fall-through: every
/// extension maps to exactly one family below, and anything not listed gets
/// the generic file icon. It is never hidden. Used by the conversation
/// settings sheet's Docs tab and the chat's document chip.
@immutable
class DocType {
  final IconData icon;
  final Color color;
  const DocType(this.icon, this.color);
}

const DocType _pdf = DocType(Icons.picture_as_pdf_outlined, Color(0xFFFF6B6B));
const DocType _doc = DocType(Icons.description_outlined, Color(0xFF5B9DFF));
const DocType _sheet = DocType(Icons.table_chart_outlined, Color(0xFF3DDC84));
const DocType _slides = DocType(Icons.slideshow_outlined, Color(0xFFFFA552));
const DocType _web = DocType(Icons.html_rounded, Color(0xFFB88CFF));
const DocType _code = DocType(Icons.data_object_rounded, Color(0xFF64FFDA));
const DocType _archive = DocType(Icons.folder_zip_outlined, Color(0xFFF5C451));
const DocType _text = DocType(Icons.article_outlined, Color(0xFFC9CED6));
const DocType _audio = DocType(Icons.audiotrack_rounded, Color(0xFFFF7AC6));
const DocType _app = DocType(Icons.install_mobile_rounded, Color(0xFF8BE36B));
const DocType _key = DocType(Icons.key_rounded, Color(0xFFFFD166));

/// Anything not in [_byExtension].
const DocType kGenericDocType =
    DocType(Icons.insert_drive_file_outlined, Color(0xFF9AA3AE));

const Map<String, DocType> _byExtension = {
  'pdf': _pdf,
  'doc': _doc, 'docx': _doc, 'odt': _doc, 'rtf': _doc, 'pages': _doc,
  'xls': _sheet, 'xlsx': _sheet, 'csv': _sheet, 'ods': _sheet, 'numbers': _sheet,
  'ppt': _slides, 'pptx': _slides, 'odp': _slides, 'key': _slides,
  'html': _web, 'htm': _web,
  'json': _code, 'js': _code, 'ts': _code, 'dart': _code, 'py': _code,
  'sol': _code, 'rs': _code, 'go': _code, 'yaml': _code, 'yml': _code, 'xml': _code,
  'zip': _archive, 'rar': _archive, '7z': _archive, 'tar': _archive, 'gz': _archive,
  'txt': _text, 'md': _text, 'log': _text,
  'mp3': _audio, 'wav': _audio, 'm4a': _audio, 'ogg': _audio, 'flac': _audio,
  'apk': _app, 'ipa': _app, 'exe': _app, 'dmg': _app, 'msi': _app,
  'pem': _key, 'crt': _key, 'p12': _key,
};

/// Lower-cased extension without the dot, or '' when there is none.
String docExtension(String filename) {
  final dot = filename.lastIndexOf('.');
  if (dot < 0 || dot == filename.length - 1) return '';
  return filename.substring(dot + 1).toLowerCase();
}

DocType docTypeFor(String filename) =>
    _byExtension[docExtension(filename)] ?? kGenericDocType;

/// MIME families -> the same fixed list. Exact types first (the server's
/// allow-list), then the `type/` prefix, then
/// the filename. For post attachments, whose stored extension may be
/// `.bin` while the MIME is right.
const Map<String, DocType> _byMime = {
  'application/pdf': _pdf,
  'application/msword': _doc,
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': _doc,
  'application/rtf': _doc,
  'application/vnd.ms-excel': _sheet,
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': _sheet,
  'text/csv': _sheet,
  'application/vnd.ms-powerpoint': _slides,
  'application/vnd.openxmlformats-officedocument.presentationml.presentation': _slides,
  'text/html': _web,
  'application/json': _code,
  'application/xml': _code,
  'text/xml': _code,
  'application/zip': _archive,
  'application/vnd.rar': _archive,
  'application/x-7z-compressed': _archive,
  'application/gzip': _archive,
  'application/epub+zip': _doc,
  'text/plain': _text,
  'text/markdown': _text,
  'application/vnd.android.package-archive': _app,
};

DocType docTypeForMime(String mimeType, String filename) {
  final m = mimeType.toLowerCase();
  final exact = _byMime[m];
  if (exact != null) return exact;
  if (m.startsWith('audio/')) return _audio;
  if (m.startsWith('text/')) return _text;
  return docTypeFor(filename);
}

/// "84 KB", "1.2 MB" — the size format both the chat chip and the Docs tab use.
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb >= 1024) return '${(kb / 1024).toStringAsFixed(1)} MB';
  return '${kb.toStringAsFixed(0)} KB';
}

/// The 40×40 tinted tile carrying a [DocType] glyph (the chat doc chip's
/// shape: radius 10, 15% tint).
class DocTypeTile extends StatelessWidget {
  final String filename;
  final double size;
  const DocTypeTile({super.key, required this.filename, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final t = docTypeFor(filename);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: t.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Icon(t.icon, color: t.color, size: size * 0.55),
    );
  }
}
