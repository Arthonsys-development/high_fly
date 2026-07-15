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
  final String? existingChequeImageUrl;
  final String? rtgsImageName;
  final List<int>? rtgsImageBytes;
  final String? existingRtgsImageUrl;
  final String? upiImageName;
  final List<int>? upiImageBytes;
  final String? existingUpiImageUrl;
  final String? loanBankName;
  final String? loanBankKey;
  final String? loanAmount;
  final String pricePerSqYd;
  final String totalAmount;
  final String? upiTransactionId;

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
    this.existingChequeImageUrl,
    this.rtgsImageName,
    this.rtgsImageBytes,
    this.existingRtgsImageUrl,
    this.upiImageName,
    this.upiImageBytes,
    this.existingUpiImageUrl,
    this.loanBankName,
    this.loanBankKey,
    this.loanAmount,
    this.pricePerSqYd = '',
    this.totalAmount = '',
    this.upiTransactionId,
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
      existingChequeImageUrl: json['existingChequeImageUrl'] as String?,
      rtgsImageName: json['rtgsImageName'] as String?,
      rtgsImageBytes: json['rtgsImageBytes'] != null
          ? List<int>.from(json['rtgsImageBytes'] as List)
          : null,
      existingRtgsImageUrl: json['existingRtgsImageUrl'] as String?,
        upiImageName: json['upiImageName'] as String?,
        upiImageBytes: json['upiImageBytes'] != null
          ? List<int>.from(json['upiImageBytes'] as List)
          : null,
        existingUpiImageUrl: json['existingUpiImageUrl'] as String?,
      loanBankName: json['loanBankName'] as String?,
      loanBankKey: json['loanBankKey'] as String?,
      loanAmount: json['loanAmount'] as String?,
      pricePerSqYd: json['pricePerSqYd'] as String? ?? '',
      totalAmount: json['totalAmount'] as String? ?? '',
      upiTransactionId: json['upiTransactionId'] as String?,
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
      'existingChequeImageUrl': existingChequeImageUrl,
      'rtgsImageName': rtgsImageName,
      'rtgsImageBytes': rtgsImageBytes,
      'existingRtgsImageUrl': existingRtgsImageUrl,
      'upiImageName': upiImageName,
      'upiImageBytes': upiImageBytes,
      'existingUpiImageUrl': existingUpiImageUrl,
      'loanBankName': loanBankName,
      'loanBankKey': loanBankKey,
      'loanAmount': loanAmount,
      'pricePerSqYd': pricePerSqYd,
      'totalAmount': totalAmount,
      'upiTransactionId': upiTransactionId,
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
    String? existingChequeImageUrl,
    String? rtgsImageName,
    List<int>? rtgsImageBytes,
    String? existingRtgsImageUrl,
    String? upiImageName,
    List<int>? upiImageBytes,
    String? existingUpiImageUrl,
    String? loanBankName,
    String? loanBankKey,
    String? loanAmount,
    String? pricePerSqYd,
    String? totalAmount,
    String? upiTransactionId,
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
      existingChequeImageUrl: existingChequeImageUrl ?? this.existingChequeImageUrl,
      rtgsImageName: rtgsImageName ?? this.rtgsImageName,
      rtgsImageBytes: rtgsImageBytes ?? this.rtgsImageBytes,
      existingRtgsImageUrl: existingRtgsImageUrl ?? this.existingRtgsImageUrl,
      upiImageName: upiImageName ?? this.upiImageName,
      upiImageBytes: upiImageBytes ?? this.upiImageBytes,
      existingUpiImageUrl: existingUpiImageUrl ?? this.existingUpiImageUrl,
      loanBankName: loanBankName ?? this.loanBankName,
      loanBankKey: loanBankKey ?? this.loanBankKey,
      loanAmount: loanAmount ?? this.loanAmount,
      pricePerSqYd: pricePerSqYd ?? this.pricePerSqYd,
      totalAmount: totalAmount ?? this.totalAmount,
      upiTransactionId: upiTransactionId ?? this.upiTransactionId,
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
    upi: 'UPI',
   // online: 'Online Transfer',
  };

  static List<String> get keys => all.keys.toList();
  static List<String> get values => all.values.toList();
  static String getValue(String key) => all[key] ?? '';
}

class PaymentType {
  static const String oneTime = 'one_time';
  static const String finance = 'finance';

  static const Map<String, String> all = {
    oneTime: 'Without Loan',
    finance: 'With Loan',
  };

  static List<String> get keys => all.keys.toList();
  static List<String> get values => all.values.toList();
  static String getValue(String key) => all[key] ?? '';
}

class IndianBanks {
  static const Map<String, String> all = {
    // Public Sector Banks
    'sbi': 'State Bank of India',
    'bob': 'Bank of Baroda',
    'boi': 'Bank of India',
    'bom': 'Bank of Maharashtra',
    'canara': 'Canara Bank',
    'central_bank': 'Central Bank of India',
    'indian_bank': 'Indian Bank',
    'iob': 'Indian Overseas Bank',
    'psb': 'Punjab & Sind Bank',
    'pnb': 'Punjab National Bank',
    'uco': 'UCO Bank',
    'union_bank': 'Union Bank of India',
    // Private Sector Banks
    'axis': 'Axis Bank',
    'bandhan': 'Bandhan Bank',
    'cub': 'City Union Bank',
    'csb': 'CSB Bank',
    'dcb': 'DCB Bank',
    'dhanlaxmi': 'Dhanlaxmi Bank',
    'federal': 'Federal Bank',
    'hdfc': 'HDFC Bank',
    'icici': 'ICICI Bank',
    'idbi': 'IDBI Bank',
    'idfc_first': 'IDFC First Bank',
    'indusind': 'IndusInd Bank',
    'jk_bank': 'Jammu & Kashmir Bank',
    'karnataka': 'Karnataka Bank',
    'kvb': 'Karur Vysya Bank',
    'kotak': 'Kotak Mahindra Bank',
    'nainital': 'Nainital Bank',
    'rbl': 'RBL Bank',
    'south_indian': 'South Indian Bank',
    'tmb': 'Tamilnad Mercantile Bank',
    'yes_bank': 'YES Bank',
    // Small Finance Banks
    'au_sfb': 'AU Small Finance Bank',
    'equitas_sfb': 'Equitas Small Finance Bank',
    'esaf_sfb': 'ESAF Small Finance Bank',
    'fincare_sfb': 'Fincare Small Finance Bank',
    'jana_sfb': 'Jana Small Finance Bank',
    'ne_sfb': 'North East Small Finance Bank',
    'shivalik_sfb': 'Shivalik Small Finance Bank',
    'suryoday_sfb': 'Suryoday Small Finance Bank',
    'ujjivan_sfb': 'Ujjivan Small Finance Bank',
    'unity_sfb': 'Unity Small Finance Bank',
    'utkarsh_sfb': 'Utkarsh Small Finance Bank',
    // Payments Banks
    'airtel_pb': 'Airtel Payments Bank',
    'ippb': 'India Post Payments Bank',
    'jio_pb': 'Jio Payments Bank',
    'paytm_pb': 'Paytm Payments Bank',
    'fino_pb': 'FINO Payments Bank',
  };

  static List<String> get keys => all.keys.toList();
  static List<String> get values => all.values.toList();
  static String getValue(String key) => all[key] ?? '';
}
