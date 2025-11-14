/// Central place to manage tenant API keys.
///
/// Update [TenantApiKeyConfig.activeTenantApiKey] before building to enable the
/// tenant you want to target. Keep all tenant keys below so you can switch
/// between them quickly.
class TenantApiKeyConfig {
  TenantApiKeyConfig._();

  /// Change this to the desired tenant before running a build.
  static const String activeTenantApiKey = TenantApiKeys.vistarak;
}

/// Stores all tenant keys. Add new tenants here.
class TenantApiKeys {
  TenantApiKeys._();

  static const String highFly =  'f5fb6328-dde1-495f-b30d-25086a806a43';
  static const String vistarak = '776e2413-2360-48fc-9a3a-3dc4990f466e';
  // static const String anotherOrg = '<replace-with-key>';
}

