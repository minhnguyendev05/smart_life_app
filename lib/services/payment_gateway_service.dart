import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_secrets.dart';

class PaymentResult {
  PaymentResult({
    required this.success,
    required this.transactionId,
    this.message,
  });

  final bool success;
  final String transactionId;
  final String? message;
}

class PaymentGatewayService {
  bool get isConfigured =>
      AppSecrets.paymentApiEndpoint.isNotEmpty && AppSecrets.paymentApiKey.isNotEmpty;

  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required String orderId,
    required String description,
  }) async {
    if (!isConfigured) {
      return PaymentResult(
        success: false,
        transactionId: '',
        message: 'Chưa cấu hình PAYMENT_API_ENDPOINT/PAYMENT_API_KEY',
      );
    }

    try {
      final uri = Uri.parse(AppSecrets.paymentApiEndpoint);
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppSecrets.paymentApiKey}',
            },
            body: jsonEncode({
              'amount': amount,
              'currency': currency,
              'orderId': orderId,
              'description': description,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return PaymentResult(
          success: false,
          transactionId: '',
          message: 'Payment API error ${response.statusCode}',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return PaymentResult(
        success: body['success'] as bool? ?? true,
        transactionId: body['transactionId'] as String? ??
            'tx-${DateTime.now().microsecondsSinceEpoch}',
        message: body['message'] as String?,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        transactionId: '',
        message: '$e',
      );
    }
  }
}
