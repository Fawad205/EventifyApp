import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class MapService {
  static Future<void> openMap(double lat, double lng) async {
    Uri googleUrl;
    Uri appleUrl;

    if (Platform.isAndroid) {
      // Use the 'google.navigation' intent for direct navigation on Android
      googleUrl = Uri.parse('google.navigation:q=$lat,$lng');
      if (await canLaunchUrl(googleUrl)) {
        await launchUrl(googleUrl);
      } else {
        // Fallback to web search in browser if intent fails
        googleUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
        await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
      }
    } else if (Platform.isIOS) {
      appleUrl = Uri.parse('apple.maps://?q=$lat,$lng');
      if (await canLaunchUrl(appleUrl)) {
        await launchUrl(appleUrl);
      } else {
        googleUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
        await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
      }
    } else {
      // For web or other platforms
      googleUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    }
  }
}
