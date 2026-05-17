import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  String url1 = "https://maps.app.goo.gl/bM5j2hGqT6C1oR1A8"; 
  var response2 = await http.get(Uri.parse(url1));
  print('Final URL: ${response2.request?.url}');
  print('Body snippet: ${response2.body.substring(0, 500)}');
}
