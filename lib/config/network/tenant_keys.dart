/// Central place to manage tenant API keys.
///
/// Update [TenantApiKeyConfig.activeTenantApiKey] before building to enable the
/// tenant you want to target. Keep all tenant keys below so you can switch
/// between them quickly.
class TenantApiKeyConfig {
  TenantApiKeyConfig._();

  /// Change this to the desired tenant before running a build.
  static const String activeTenantApiKey = TenantApiKeys.teprodVisstKey;
}

/// Stores all tenant keys. Add new tenants here.
class TenantApiKeys {
  TenantApiKeys._();

  static const String highFly =  'f5fb6328-dde1-495f-b30d-25086a806a43';
  static const String vistarak = 'd1dfebc4-b37f-4997-9b5c-086cd4e5dcdf';
  static const String testerKey = 'ef5192f3-b5e3-47e4-8cb4-4afe5199cac9';
  static const String benDeveloper = 'cdb83a60-c055-4235-9469-f2625ffc1f6e';
  static const String emily = 'e198deae-ccf1-43c0-8e53-e7f1cff91d21';

  static const String teprodVisstKey = '474ba05d-7f3c-4277-b715-6623e398d992';

  // static const String anotherOrg = '<replace-with-key>';
}

/*
emily
https://drive.google.com/file/d/1pMlLhJWHW3MOS9ltbswhSzqiUGvfJ5Vv/view?usp=sharing


vistarak
https://drive.google.com/file/d/10EffrszBqORMs4u1frXalONvPyBdjEKY/view?usp=sharing

tester
https://drive.google.com/file/d/1iwLu5j_1_oKVhAVeVMYrN14L8BHUG4i_/view?usp=sharing
*/