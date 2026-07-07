import 'network_connectivity_helper_stub.dart'
    if (dart.library.io) 'network_connectivity_helper_io.dart'
    if (dart.library.html) 'network_connectivity_helper_web.dart';

class NetworkConnectivityHelper {
  static Future<bool> hasInternetConnection() {
    return hasInternetConnectionPlatform();
  }
}