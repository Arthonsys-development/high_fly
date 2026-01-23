// Helper file for reCAPTCHA Enterprise initialization
// This file isolates the reCAPTCHA import to avoid build issues

import 'package:recaptcha_enterprise_flutter/recaptcha.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_client.dart';
import '../config/network/recaptcha_config.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Initialize reCAPTCHA Enterprise client
/// Returns the client if successful, null otherwise
Future<RecaptchaClient?> initializeRecaptchaClient() async {
  try {
    debugPrint('🛡️ Initializing reCAPTCHA Enterprise client...');
    final siteKey = RecaptchaConfig.siteKey;
    debugPrint('🛡️ reCAPTCHA site key loaded');
    
    final client = await Recaptcha.fetchClient(siteKey);
    debugPrint('✅ reCAPTCHA Enterprise client initialized successfully');
    return client;
  } catch (e) {
    debugPrint('❌ reCAPTCHA Enterprise initialization error: $e');
    debugPrint('⚠️ App will continue without reCAPTCHA Enterprise');
    return null;
  }
}
