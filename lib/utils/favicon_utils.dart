import 'dart:convert';
import 'package:http/http.dart' as http;

class FaviconUtils {
  static const Duration _timeout = Duration(seconds: 10);
  
  /// Get favicon URL for a website
  static String getFaviconUrl(String websiteUrl) {
    try {
      final uri = Uri.parse(websiteUrl);
      final domain = uri.host;
      
      // Use multiple favicon services as fallbacks
      return 'https://www.google.com/s2/favicons?domain=$domain&sz=64';
    } catch (e) {
      // Fallback to a default favicon service
      return 'https://www.google.com/s2/favicons?domain=example.com&sz=64';
    }
  }
  
  /// Get high-quality favicon with fallback options
  static List<String> getFaviconUrls(String websiteUrl) {
    try {
      final uri = Uri.parse(websiteUrl);
      final domain = uri.host;
      
      return [
        'https://www.google.com/s2/favicons?domain=$domain&sz=64',
        'https://favicon.yandex.net/favicon/$domain',
        'https://icons.duckduckgo.com/ip3/$domain.ico',
        'https://$domain/favicon.ico',
      ];
    } catch (e) {
      return ['https://www.google.com/s2/favicons?domain=example.com&sz=64'];
    }
  }
  
  /// Check if a URL is valid (basic validation)
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}