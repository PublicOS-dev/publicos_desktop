/// MIME / extension helpers for media dispatch (image vs video).
///
/// Centralizes the inline `mimeType.startsWith('image/')` checks scattered
/// across the codebase, plus extension-based inference for URLs that don't
/// carry a MIME type (post media, anchor URLs, etc.).
library;

const Set<String> _imageExtensions = {
  '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg', '.heic', '.heif',
};

const Set<String> _videoExtensions = {
  '.mp4', '.webm', '.mov', '.m4v',
};

bool isImageMime(String? mime) =>
    mime != null && mime.startsWith('image/');

bool isVideoMime(String? mime) =>
    mime != null && mime.startsWith('video/');

/// Lower-cased extension including the leading dot, or `''` if the URL has no
/// recognizable extension.
String _extOf(String url) {
  try {
    final path = Uri.parse(url).path;
    final dot = path.lastIndexOf('.');
    if (dot == -1) return '';
    return path.substring(dot).toLowerCase();
  } catch (_) {
    return '';
  }
}

bool isImageUrl(String url) => _imageExtensions.contains(_extOf(url));
bool isVideoUrl(String url) => _videoExtensions.contains(_extOf(url));

/// True if the filename ends with a known video extension (used by remote
/// XMTP attachments that may lack a MIME type).
bool isVideoFilename(String filename) {
  final lower = filename.toLowerCase();
  for (final ext in _videoExtensions) {
    if (lower.endsWith(ext)) return true;
  }
  return false;
}

bool isImageFilename(String filename) {
  final lower = filename.toLowerCase();
  for (final ext in _imageExtensions) {
    if (lower.endsWith(ext)) return true;
  }
  return false;
}
