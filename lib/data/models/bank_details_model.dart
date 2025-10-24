import 'package:flutter/foundation.dart';

@immutable
class BankDetails {
  final String? accountHolderName;
  final String? branchName;
  final String? accountNumber;
  final String? ifscCode;
  final String? accountType;
  final String? contactNumber;

  const BankDetails({
    this.accountHolderName,
    this.branchName,
    this.accountNumber,
    this.ifscCode,
    this.accountType,
    this.contactNumber,
  });

  BankDetails copyWith({
    String? accountHolderName,
    String? branchName,
    String? accountNumber,
    String? ifscCode,
    String? accountType,
    String? contactNumber,
  }) {
    return BankDetails(
      accountHolderName: accountHolderName ?? this.accountHolderName,
      branchName: branchName ?? this.branchName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      accountType: accountType ?? this.accountType,
      contactNumber: contactNumber ?? this.contactNumber,
    );
  }

  @override
  String toString() {
    return 'BankDetails(accountHolderName: $accountHolderName, branchName: $branchName, accountNumber: $accountNumber, ifscCode: $ifscCode, accountType: $accountType, contactNumber: $contactNumber)';
  }
}

class BankConstants {
  static const Map<String, String> accountTypes = {
    'savings': 'Savings',
    'current': 'Current',
  };
}
