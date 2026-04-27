class PaymentDetails {
  final String paymentAmount;
  final String paymentMethod;
  final String paymentMethodKey;
  final String paymentType;
  final String paymentTypeKey;
  final String panNumber;
  final String aadharNumber;
  final bool isSalariedIndividual;
  final String? salarySlipPath;
  final String? form16APath;
  final String additionalNotes;
  final String? chequeNumber;
  final DateTime? chequeDate;
  final String? chequeImageName;
  final List<int>? chequeImageBytes;

  const PaymentDetails({
    required this.paymentAmount,
    required this.paymentMethod,
    required this.paymentMethodKey,
    required this.paymentType,
    required this.paymentTypeKey,
    required this.panNumber,
    required this.aadharNumber,
    this.isSalariedIndividual = false,
    this.salarySlipPath,
    this.form16APath,
    required this.additionalNotes,
    this.chequeNumber,
    this.chequeDate,
    this.chequeImageName,
    this.chequeImageBytes,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      paymentAmount: json['paymentAmount'] as String,
      paymentMethod: json['paymentMethod'] as String,
      paymentMethodKey: json['paymentMethodKey'] as String,
      paymentType: json['paymentType'] as String,
      paymentTypeKey: json['paymentTypeKey'] as String,
      panNumber: json['panNumber'] as String,
      aadharNumber: json['aadharNumber'] as String,
      isSalariedIndividual: json['isSalariedIndividual'] as bool? ?? false,
      salarySlipPath: json['salarySlipPath'] as String?,
      form16APath: json['form16APath'] as String?,
      additionalNotes: json['additionalNotes'] as String,
      chequeNumber: json['chequeNumber'] as String?,
      chequeDate: json['chequeDate'] != null ? DateTime.parse(json['chequeDate'] as String) : null,
      chequeImageName: json['chequeImageName'] as String?,
      chequeImageBytes: json['chequeImageBytes'] != null
          ? List<int>.from(json['chequeImageBytes'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentAmount': paymentAmount,
      'paymentMethod': paymentMethod,
      'paymentMethodKey': paymentMethodKey,
      'paymentType': paymentType,
      'paymentTypeKey': paymentTypeKey,
      'panNumber': panNumber,
      'aadharNumber': aadharNumber,
      'isSalariedIndividual': isSalariedIndividual,
      'salarySlipPath': salarySlipPath,
      'form16APath': form16APath,
      'additionalNotes': additionalNotes,
      'chequeNumber': chequeNumber,
      'chequeDate': chequeDate?.toIso8601String(),
      'chequeImageName': chequeImageName,
      'chequeImageBytes': chequeImageBytes,
    };
  }

  PaymentDetails copyWith({
    String? paymentAmount,
    String? paymentMethod,
    String? paymentMethodKey,
    String? paymentType,
    String? paymentTypeKey,
    String? panNumber,
    String? aadharNumber,
    bool? isSalariedIndividual,
    String? salarySlipPath,
    String? form16APath,
    String? additionalNotes,
    String? chequeNumber,
    DateTime? chequeDate,
    String? chequeImageName,
    List<int>? chequeImageBytes,
  }) {
    return PaymentDetails(
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentMethodKey: paymentMethodKey ?? this.paymentMethodKey,
      paymentType: paymentType ?? this.paymentType,
      paymentTypeKey: paymentTypeKey ?? this.paymentTypeKey,
      panNumber: panNumber ?? this.panNumber,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      isSalariedIndividual: isSalariedIndividual ?? this.isSalariedIndividual,
      salarySlipPath: salarySlipPath ?? this.salarySlipPath,
      form16APath: form16APath ?? this.form16APath,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      chequeNumber: chequeNumber ?? this.chequeNumber,
      chequeDate: chequeDate ?? this.chequeDate,
      chequeImageName: chequeImageName ?? this.chequeImageName,
      chequeImageBytes: chequeImageBytes ?? this.chequeImageBytes,
    );
  }
}

class PaymentMethod {
  static const String cheque = 'cheque';
  static const String rtgs = 'rtgs';
  static const String online = 'online';
  static const String upi = 'upi';

  static const Map<String, String> all = {
    cheque: 'Cheque',
    rtgs: 'RTGS/NEFT',
   // online: 'Online Transfer',
   // upi: 'UPI',
  };

  static List<String> get keys => all.keys.toList();
  static List<String> get values => all.values.toList();
  static String getValue(String key) => all[key] ?? '';
}

class PaymentType {
  static const String oneTime = 'one_time';
  static const String finance = 'finance';

  static const Map<String, String> all = {
    oneTime: 'One Time Payment',
    finance: 'Finance/EMI',
  };

  static List<String> get keys => all.keys.toList();
  static List<String> get values => all.values.toList();
  static String getValue(String key) => all[key] ?? '';
}
