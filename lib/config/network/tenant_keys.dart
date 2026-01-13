import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place to manage tenant API keys.
///
/// Tenant API keys are now loaded from .env files.
/// Update ACTIVE_TENANT_API_KEY in your .env file to switch tenants.
class TenantApiKeyConfig {
  TenantApiKeyConfig._();

  /// Gets the active tenant API key from environment variables.
  /// Falls back to teprodVisstKey if not set in .env
  static String get activeTenantApiKey {
    return dotenv.env['ACTIVE_TENANT_API_KEY'] ?? 
           TenantApiKeys.teprodVisstKey;
  }
}

/// Stores all tenant keys loaded from environment variables.
/// Add new tenants to your .env files.
class TenantApiKeys {
  TenantApiKeys._();

  static String get highFly => 
    dotenv.env['TENANT_API_KEY_HIGHFLY'] ?? 
    'f5fb6328-dde1-495f-b30d-25086a806a43';
  
  static String get vistarak => 
    dotenv.env['TENANT_API_KEY_VISTARAK'] ?? 
    'd1dfebc4-b37f-4997-9b5c-086cd4e5dcdf';
  
  static String get testerKey => 
    dotenv.env['TENANT_API_KEY_TESTER'] ?? 
    'ef5192f3-b5e3-47e4-8cb4-4afe5199cac9';
  
  static String get benDeveloper => 
    dotenv.env['TENANT_API_KEY_BEN_DEVELOPER'] ?? 
    'cdb83a60-c055-4235-9469-f2625ffc1f6e';
  
  static String get emily => 
    dotenv.env['TENANT_API_KEY_EMILY'] ?? 
    'e198deae-ccf1-43c0-8e53-e7f1cff91d21';

  static String get teprodVisstKey => 
    dotenv.env['TENANT_API_KEY_TEPROD_VISST'] ?? 
    '474ba05d-7f3c-4277-b715-6623e398d992';
}

/*
emily
https://drive.google.com/file/d/1pMlLhJWHW3MOS9ltbswhSzqiUGvfJ5Vv/view?usp=sharing


vistarak
https://drive.google.com/file/d/10EffrszBqORMs4u1frXalONvPyBdjEKY/view?usp=sharing

tester
https://drive.google.com/file/d/1iwLu5j_1_oKVhAVeVMYrN14L8BHUG4i_/view?usp=sharing
*/