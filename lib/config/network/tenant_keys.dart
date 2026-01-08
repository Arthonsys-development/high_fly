/// Central place to manage tenant API keys.
///
/// Update [TenantApiKeyConfig.activeTenantApiKey] before building to enable the
/// tenant you want to target. Keep all tenant keys below so you can switch
/// between them quickly.
class TenantApiKeyConfig {
  TenantApiKeyConfig._();

  /// Change this to the desired tenant before running a build.
  static const String activeTenantApiKey = TenantApiKeys.testerKey;
}

/// Stores all tenant keys. Add new tenants here.
class TenantApiKeys {
  TenantApiKeys._();

  static const String highFly =  'f5fb6328-dde1-495f-b30d-25086a806a43';
  static const String vistarak = '776e2413-2360-48fc-9a3a-3dc4990f466e';
  static const String testerKey = 'ef5192f3-b5e3-47e4-8cb4-4afe5199cac9';
  static const String benDeveloper = 'cdb83a60-c055-4235-9469-f2625ffc1f6e';
  static const String emily = 'd5ee582d-45b4-42e9-9fc9-7575b621c50f';

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