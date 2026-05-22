import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

enum ChequeAnalysisStatus {
  /// Gemini confirmed this IS a valid cheque with a readable cheque number
  success,
  /// Gemini confirmed this is NOT a cheque
  notACheque,
  /// Image is a cheque but the cheque number is blurred / cropped / unreadable
  chequeNumberUnreadable,
  /// Cheque payee name does not match the project's required pay_name
  payNameMismatch,
  /// Gemini API server is temporarily unavailable (503 / overload)
  serverUnavailable,
  /// API key missing or invalid
  apiKeyError,
  /// Any other unexpected error
  unknownError,
}

class ChequeInfo {
  final ChequeAnalysisStatus status;
  final String? chequeNumber;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? payeeName;
  final String? amount;
  final String? date;
  final String? micrCode;
  final String? branchName;
  final String? drawerName;
  final String? errorMessage;

  const ChequeInfo({
    required this.status,
    this.chequeNumber,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.payeeName,
    this.amount,
    this.date,
    this.micrCode,
    this.branchName,
    this.drawerName,
    this.errorMessage,
  });

  bool get isCheque => status == ChequeAnalysisStatus.success;
  bool get isServerError => status == ChequeAnalysisStatus.serverUnavailable;
  bool get isNotACheque => status == ChequeAnalysisStatus.notACheque;
  bool get isChequeNumberUnreadable => status == ChequeAnalysisStatus.chequeNumberUnreadable;
  bool get isPayNameMismatch => status == ChequeAnalysisStatus.payNameMismatch;
}

class ChequeAnalysisService {
  static const String _modelName = 'gemini-2.5-flash';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  static const String _prompt = '''
You are analyzing an Indian bank cheque image.

TASK 1 — Is this a cheque?
Look for: bank name/logo, PAY line, RUPEES line, date box, A/C No, signature area.
If NOT a cheque → respond ONLY: {"is_cheque": false}

TASK 2 — If it IS a cheque, answer these questions IN ORDER:

QUESTION A: Look at the VERY BOTTOM EDGE of the image right now.
Can you physically see a horizontal strip of numbers printed in a special magnetic ink font (MICR band)?
The MICR band is the last printed line at the absolute bottom of the cheque leaf.
Set "micr_band_visible" to true ONLY if this strip is present and not cut off in the image.
Set "micr_band_visible" to false if the bottom of the image is cut off, blank, or the MICR strip is not there.

QUESTION B: If micr_band_visible is true — read the FIRST group of digits at the bottom-LEFT of the MICR band.
That is the cheque serial number. It is exactly 6 digits (e.g. 000453, 012876).
Set "cheque_number" to those 6 digits ONLY if you can read every single digit clearly.
If even one digit is unclear → set cheque_number to null and cheque_number_readable to false.
NEVER guess, estimate, or infer. NEVER use numbers from the body of the cheque.

Respond with ONLY this JSON (no markdown, no code block):
{
  "is_cheque": true,
  "micr_band_visible": true or false,
  "cheque_number_readable": true or false,
  "cheque_number": "6-digit number or null",
  "bank_name": "bank name or null",
  "branch_name": "branch name or null",
  "account_number": "account number or null",
  "ifsc_code": "IFSC or null",
  "payee_name": "payee name or null",
  "amount": "amount or null",
  "date": "DD/MM/YYYY or null",
  "micr_code": "9-digit MICR code or null",
  "drawer_name": "drawer name or null"
}
''';

  String _buildPrompt({String? expectedPayName}) {
    final trimmedPayName = expectedPayName?.trim();
    if (trimmedPayName == null || trimmedPayName.isEmpty) {
      return _prompt;
    }

    return '''
$_prompt

TASK 3 — Payee name verification (REQUIRED)
The required payee name for this project is: "$trimmedPayName"
Read the payee name printed on the "Pay" line of the cheque.
Set "pay_name_matches" to true ONLY if the payee on the cheque clearly refers to the same entity as the required name (allow minor spelling differences, abbreviations, extra prefixes like M/s, Pvt Ltd, or word order changes).
Set "pay_name_matches" to false if the payee is a clearly different person/company, the Pay line is blank/unreadable, or you cannot confirm a match.
Add "pay_name_matches": true or false to your JSON response.
''';
  }

  Future<ChequeInfo> analyzeCheque(
    List<int> imageBytes, {
    String? expectedPayName,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
      debugPrint('⚠️ ChequeAnalysis: GEMINI_API_KEY not set in .env file');
      return const ChequeInfo(
        status: ChequeAnalysisStatus.apiKeyError,
        errorMessage: 'Gemini API key is not configured.\nPlease set GEMINI_API_KEY in the .env file.',
      );
    }

    final model = GenerativeModel(model: _modelName, apiKey: apiKey);
    final prompt = _buildPrompt(expectedPayName: expectedPayName);

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        debugPrint('🤖 ChequeAnalysis: attempt $attempt/$_maxRetries');

        final response = await model.generateContent([
          Content.multi([
            TextPart(prompt),
            DataPart('image/jpeg', Uint8List.fromList(imageBytes)),
          ]),
        ]);

        final text = (response.text ?? '').trim();
        debugPrint('🤖 ChequeAnalysis response: $text');
        return _parseResponse(text, expectedPayName: expectedPayName);
      } catch (e) {
        final errStr = e.toString();
        debugPrint('❌ ChequeAnalysis attempt $attempt error: $errStr');

        final isNetworkError = errStr.contains('SocketException') ||
            errStr.contains('ClientException') ||
            errStr.contains('Failed host lookup') ||
            errStr.contains('NetworkException') ||
            errStr.contains('Connection refused') ||
            errStr.contains('Connection timed out');

        final isServerOverload = errStr.contains('503') ||
            errStr.contains('UNAVAILABLE') ||
            errStr.contains('high demand') ||
            errStr.contains('Server Error');

        if (isServerOverload && attempt < _maxRetries) {
          final delay = _retryDelay * attempt;
          debugPrint('⏳ ChequeAnalysis: retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
          continue;
        }

        if (isNetworkError) {
          return const ChequeInfo(
            status: ChequeAnalysisStatus.serverUnavailable,
            errorMessage: 'Some technical issue occurred.\nPlease check your internet connection and try again.',
          );
        }

        if (isServerOverload) {
          return const ChequeInfo(
            status: ChequeAnalysisStatus.serverUnavailable,
            errorMessage: 'Some technical issue occurred.\nPlease try again in a moment.',
          );
        }

        return const ChequeInfo(
          status: ChequeAnalysisStatus.unknownError,
          errorMessage: 'Some technical issue occurred.\nPlease try again or enter cheque details manually.',
        );
      }
    }

    // Should not reach here, but just in case
    return const ChequeInfo(
      status: ChequeAnalysisStatus.serverUnavailable,
      errorMessage: 'Some technical issue occurred.\nPlease try again or enter cheque details manually.',
    );
  }

  ChequeInfo _parseResponse(String text, {String? expectedPayName}) {
    try {
      final cleaned = text
          .replaceAll(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
          .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
          .trim();

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      if (jsonMatch == null) {
        return const ChequeInfo(
          status: ChequeAnalysisStatus.unknownError,
          errorMessage: 'Some technical issue occurred. Please try again.',
        );
      }

      final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

      if (json['is_cheque'] != true) {
        return const ChequeInfo(status: ChequeAnalysisStatus.notACheque);
      }

      // Gate 1: MICR band must be physically visible in the image
      final micrBandVisible = json['micr_band_visible'];
      if (micrBandVisible == false || micrBandVisible == 'false') {
        return const ChequeInfo(
          status: ChequeAnalysisStatus.chequeNumberUnreadable,
          errorMessage:
              'Cheque number is not visible.\n\nThe bottom part of the cheque (MICR band) appears to be cropped or missing. Please capture the full cheque including the bottom strip and upload again.',
        );
      }

      // Gate 2: cheque_number_readable flag
      final chequeNumberReadable = json['cheque_number_readable'];
      final rawChequeNumber = _asString(json['cheque_number']);

      // Gate 3: client-side strict validation — must be exactly 6 digits
      final isValidFormat = rawChequeNumber != null &&
          RegExp(r'^\d{6}$').hasMatch(rawChequeNumber);

      final isUnreadable = chequeNumberReadable == false ||
          chequeNumberReadable == 'false' ||
          rawChequeNumber == null ||
          !isValidFormat;

      if (isUnreadable) {
        return const ChequeInfo(
          status: ChequeAnalysisStatus.chequeNumberUnreadable,
          errorMessage:
              'Cheque number is not clearly visible.\n\nPlease make sure the bottom portion of the cheque is fully visible, not blurred or cropped, and upload again.',
        );
      }

      final chequeNumber = rawChequeNumber;

      final trimmedExpectedPayName = expectedPayName?.trim();
      if (trimmedExpectedPayName != null && trimmedExpectedPayName.isNotEmpty) {
        final payNameMatches = json['pay_name_matches'];
        final matches = payNameMatches == true || payNameMatches == 'true';
        if (!matches) {
          return ChequeInfo(
            status: ChequeAnalysisStatus.payNameMismatch,
            payeeName: _asString(json['payee_name']),
            errorMessage:
                'The payee name on the cheque does not match the required payee name "$trimmedExpectedPayName".\n\nPlease upload a cheque made out to the correct payee.',
          );
        }
      }

      return ChequeInfo(
        status: ChequeAnalysisStatus.success,
        chequeNumber: chequeNumber,
        bankName: _asString(json['bank_name']),
        accountNumber: _asString(json['account_number']),
        ifscCode: _asString(json['ifsc_code']),
        payeeName: _asString(json['payee_name']),
        amount: _asString(json['amount']),
        date: _asString(json['date']),
        micrCode: _asString(json['micr_code']),
        branchName: _asString(json['branch_name']),
        drawerName: _asString(json['drawer_name']),
      );
    } catch (e) {
      return const ChequeInfo(
        status: ChequeAnalysisStatus.unknownError,
        errorMessage: 'Some technical issue occurred. Please try again.',
      );
    }
  }

  String? _asString(dynamic value) {
    if (value == null || value == 'null') return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }
}
