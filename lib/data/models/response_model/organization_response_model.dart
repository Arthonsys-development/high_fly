class OrganizationResponse {
  final bool success;
  final Organization? organization;

  OrganizationResponse({
    required this.success,
    required this.organization,
  });

  factory OrganizationResponse.fromJson(Map<String, dynamic> json) {
    return OrganizationResponse(
      success: json['success'] as bool? ?? false,
      organization: json['organization'] != null
          ? Organization.fromJson(json['organization'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AppVersionInfo {
  final String? version;
  final bool? isMandatoryUpdate;
  final String? message;

  const AppVersionInfo({
    this.version,
    this.isMandatoryUpdate,
    this.message,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      version: json['version'] as String?,
      isMandatoryUpdate: json['is_mandatory_update'] as bool?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'is_mandatory_update': isMandatoryUpdate,
      'message': message,
    };
  }
}

class AppUpdate {
  final AppVersionInfo? ios;
  final AppVersionInfo? android;

  const AppUpdate({
    this.ios,
    this.android,
  });

  factory AppUpdate.fromJson(Map<String, dynamic> json) {
    return AppUpdate(
      ios: json['ios'] != null
          ? AppVersionInfo.fromJson(json['ios'] as Map<String, dynamic>)
          : null,
      android: json['android'] != null
          ? AppVersionInfo.fromJson(json['android'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ios': ios?.toJson(),
      'android': android?.toJson(),
    };
  }
}

class Organization {
  final String? id;
  final String? name;
  final String? slug;
  final String? email;
  final String? phone;
  final String? logoUrl;
  final String? address;
  final bool? isActive;
  final String? subscriptionPlan;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final bool? isSubscriptionActive;
  final int? maxAgents;
  final int? maxProjects;
  final int? agentCount;
  final DateTime? createdAt;
  final bool? showSignup;
  final AppUpdate? appUpdate;

  const Organization({
    this.id,
    this.name,
    this.slug,
    this.email,
    this.phone,
    this.logoUrl,
    this.address,
    this.isActive,
    this.subscriptionPlan,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.isSubscriptionActive,
    this.maxAgents,
    this.maxProjects,
    this.agentCount,
    this.createdAt,
    this.showSignup,
    this.appUpdate,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String?,
      name: json['name'] as String?,
      slug: json['slug'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      logoUrl: json['logo_url'] as String?,
      address: json['address'] as String?,
      isActive: json['is_active'] as bool?,
      subscriptionPlan: json['subscription_plan'] as String?,
      subscriptionStartDate: _parseDate(json['subscription_start_date']),
      subscriptionEndDate: _parseDate(json['subscription_end_date']),
      isSubscriptionActive: json['is_subscription_active'] as bool?,
      maxAgents: json['max_agents'] as int?,
      maxProjects: json['max_projects'] as int?,
      agentCount: json['agent_count'] as int?,
      createdAt: _parseDateTime(json['created_at']),
      showSignup: json['show_signup'] as bool?,
      appUpdate: json['app_update'] != null
          ? AppUpdate.fromJson(json['app_update'] as Map<String, dynamic>)
          : null,
    );
  }

  Organization copyWith({
    String? id,
    String? name,
    String? slug,
    String? email,
    String? phone,
    String? logoUrl,
    String? address,
    bool? isActive,
    String? subscriptionPlan,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    bool? isSubscriptionActive,
    int? maxAgents,
    int? maxProjects,
    int? agentCount,
    DateTime? createdAt,
    bool? showSignup,
    AppUpdate? appUpdate,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      isSubscriptionActive: isSubscriptionActive ?? this.isSubscriptionActive,
      maxAgents: maxAgents ?? this.maxAgents,
      maxProjects: maxProjects ?? this.maxProjects,
      agentCount: agentCount ?? this.agentCount,
      createdAt: createdAt ?? this.createdAt,
      showSignup: showSignup ?? this.showSignup,
      appUpdate: appUpdate ?? this.appUpdate,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

