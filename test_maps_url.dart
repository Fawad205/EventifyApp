import 'dart:io';

void main() async {
  // Let's test with a mock expanded URL first
  String url1 = "https://www.google.com/maps/place/Lahore+Expo+Center/@31.4187,73.0791,15z/data=!3m1!4b1!4m6!3m5!1s0x392242a895a55ca9:0xb5e76d91bb165242!8m2!3d31.4187!4d73.0791!16s%2Fg%2F11b6d1_w00";
  
  print('Extracting from: $url1');
  
  // Method 1: Look for @lat,lng
  RegExp regExp = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)');
  var match = regExp.firstMatch(url1);
  if (match != null) {
    print('Lat: ${match.group(1)}, Lng: ${match.group(2)}');
  } else {
    // Method 2: Look for 3dlat!4dlng
    RegExp regExp2 = RegExp(r'3d(-?\d+\.\d+)!4d(-?\d+\.\d+)');
    var match2 = regExp2.firstMatch(url1);
    if (match2 != null) {
      print('Lat: ${match2.group(1)}, Lng: ${match2.group(2)}');
    } else {
      print('Not found');
    }
  }
}
