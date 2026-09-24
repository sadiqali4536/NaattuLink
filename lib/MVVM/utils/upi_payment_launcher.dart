import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

enum UpiPaymentStatus {
  SUCCESS,
  FAILURE,
  CANCELLED,
  NO_UPI_APP,
  ERROR,
  UNKNOWN,
}

class UpiResponse {
  final UpiPaymentStatus status;
  final String? responseCode;
  final String? txnId;
  final String? txnRef;
  final String? approvalRefNo;
  final String rawResponse;

  UpiResponse({
    required this.status,
    this.responseCode,
    this.txnId,
    this.txnRef,
    this.approvalRefNo,
    this.rawResponse = '',
  });

  factory UpiResponse.fromMap(Map<dynamic, dynamic> map) {
    UpiPaymentStatus parsedStatus = UpiPaymentStatus.UNKNOWN;

    // The native layer returns a unified status string
    final String statusStr =
        map['status']?.toString().toUpperCase() ?? 'UNKNOWN';

    switch (statusStr) {
      case 'SUCCESS':
        parsedStatus = UpiPaymentStatus.SUCCESS;
        break;
      case 'FAILURE':
        parsedStatus = UpiPaymentStatus.FAILURE;
        break;
      case 'CANCELLED':
        parsedStatus = UpiPaymentStatus.CANCELLED;
        break;
      case 'NO_UPI_APP':
        parsedStatus = UpiPaymentStatus.NO_UPI_APP;
        break;
      case 'ERROR':
        parsedStatus = UpiPaymentStatus.ERROR;
        break;
      default:
        parsedStatus = UpiPaymentStatus.UNKNOWN;
    }

    return UpiResponse(
      status: parsedStatus,
      responseCode: map['responseCode']?.toString(),
      txnId: map['txnId']?.toString(),
      txnRef: map['txnRef']?.toString(),
      approvalRefNo: map['ApprovalRefNo']?.toString(),
      rawResponse: map['rawResponse']?.toString() ?? '',
    );
  }
}

class UpiPaymentLauncher {
  static const MethodChannel _channel =
      MethodChannel('com.naattulink.upi/payment');

  static Future<UpiResponse> initiatePayment({
    required String upiId,
    required String amount,
    String? transactionRef,
    String? transactionNote,
    String payeeName =
        'NaattuLink', // Default payee name, pass actual name to avoid mismatch
  }) async {
    if (!kIsWeb && Platform.isIOS) {
      debugPrint(
          'UPI Payments are currently only supported on Android via native chooser.');
      return UpiResponse(
        status: UpiPaymentStatus.ERROR,
        rawResponse: 'Unsupported Platform: iOS',
      );
    }

    try {
      final Map<String, dynamic> arguments = {
        'pa': upiId,
        'pn': payeeName,
        'am': amount,
        'cu': 'INR',
      };

      if (transactionRef != null && transactionRef.isNotEmpty)
        arguments['tr'] = transactionRef;
      if (transactionNote != null && transactionNote.isNotEmpty)
        arguments['tn'] = transactionNote;

      debugPrint('========== NATIVE UPI DEBUG ==========');
      debugPrint('Sending arguments to Native: $arguments');

      final dynamic result =
          await _channel.invokeMethod('initiatePayment', arguments);

      if (result is Map) {
        debugPrint('Received response from Native: $result');
        return UpiResponse.fromMap(result);
      }

      return UpiResponse(
        status: UpiPaymentStatus.UNKNOWN,
        rawResponse: 'Unexpected result type: ${result.runtimeType}',
      );
    } on PlatformException catch (e) {
      debugPrint('PlatformException invoking UPI: ${e.message}');
      return UpiResponse(
        status: e.code == 'NO_UPI_APP'
            ? UpiPaymentStatus.NO_UPI_APP
            : UpiPaymentStatus.ERROR,
        rawResponse: e.message ?? e.code,
      );
    } catch (e) {
      debugPrint('Exception invoking UPI: $e');
      return UpiResponse(
        status: UpiPaymentStatus.ERROR,
        rawResponse: e.toString(),
      );
    }
  }
}
