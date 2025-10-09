class PaymentDetails {
  final String paymentAmount;
  final String paymentMethod;
  final String paymentType;
  final String panNumber;
  final String aadharNumber;
  final bool isSalariedIndividual;
  final String? salarySlipPath;
  final String? form16APath;
  final String additionalNotes;

  const PaymentDetails({
    required this.paymentAmount,
    required this.paymentMethod,
    required this.paymentType,
    required this.panNumber,
    required this.aadharNumber,
    this.isSalariedIndividual = false,
    this.salarySlipPath,
    this.form16APath,
    required this.additionalNotes,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      paymentAmount: json['paymentAmount'] as String,
      paymentMethod: json['paymentMethod'] as String,
      paymentType: json['paymentType'] as String,
      panNumber: json['panNumber'] as String,
      aadharNumber: json['aadharNumber'] as String,
      isSalariedIndividual: json['isSalariedIndividual'] as bool? ?? false,
      salarySlipPath: json['salarySlipPath'] as String?,
      form16APath: json['form16APath'] as String?,
      additionalNotes: json['additionalNotes'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentAmount': paymentAmount,
      'paymentMethod': paymentMethod,
      'paymentType': paymentType,
      'panNumber': panNumber,
      'aadharNumber': aadharNumber,
      'isSalariedIndividual': isSalariedIndividual,
      'salarySlipPath': salarySlipPath,
      'form16APath': form16APath,
      'additionalNotes': additionalNotes,
    };
  }

  PaymentDetails copyWith({
    String? paymentAmount,
    String? paymentMethod,
    String? paymentType,
    String? panNumber,
    String? aadharNumber,
    bool? isSalariedIndividual,
    String? salarySlipPath,
    String? form16APath,
    String? additionalNotes,
  }) {
    return PaymentDetails(
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentType: paymentType ?? this.paymentType,
      panNumber: panNumber ?? this.panNumber,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      isSalariedIndividual: isSalariedIndividual ?? this.isSalariedIndividual,
      salarySlipPath: salarySlipPath ?? this.salarySlipPath,
      form16APath: form16APath ?? this.form16APath,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }
}

class PaymentMethod {
  static const String bankCheck = 'Bank check';
  static const String bankTransfer = 'Bank Transfer';
  static const String creditDebitCard = 'Credit/Debit Card';

  static List<String> get all => [bankCheck, bankTransfer, creditDebitCard];
}

class PaymentType {
  static const String oneTimePayment = 'One-time Payment';
  static const String loan = 'Loan';

  static List<String> get all => [oneTimePayment, loan];
}
