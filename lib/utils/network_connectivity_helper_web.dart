import 'package:universal_html/html.dart' as html;

Future<bool> hasInternetConnectionPlatform() async {
  return html.window.navigator.onLine ?? true;
}