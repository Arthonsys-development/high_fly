// Stub file for reCAPTCHA Enterprise when running on unsupported platforms (web)
// This allows the code to compile on all platforms

/// Stub RecaptchaClient class for unsupported platforms
class RecaptchaClient {
  RecaptchaClient._();
  
  Future<String> execute(dynamic action) async {
    throw UnsupportedError('reCAPTCHA Enterprise is not supported on this platform');
  }
}

/// Stub Recaptcha class for unsupported platforms
class Recaptcha {
  Recaptcha._();
  
  static Future<RecaptchaClient> fetchClient(String siteKey) async {
    throw UnsupportedError('reCAPTCHA Enterprise is not supported on this platform');
  }
}

/// Stub RecaptchaAction class
class RecaptchaAction {
  RecaptchaAction._();
  
  static RecaptchaAction LOGIN() => RecaptchaAction._();
}
