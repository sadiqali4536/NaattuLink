class PaymentOcrResult {
  final String rawText;
  final List<String> transactionIds;
  final List<String> referenceIds;
  final double? amount;
  final DateTime? paymentDateTime;
  final bool hasSuccessIndicator;
  final bool hasUpiIndicator;
  final String? receiverUpi;
  final double confidence;

  const PaymentOcrResult({
    required this.rawText,
    required this.transactionIds,
    required this.referenceIds,
    required this.amount,
    required this.paymentDateTime,
    required this.hasSuccessIndicator,
    required this.hasUpiIndicator,
    this.receiverUpi,
    required this.confidence,
  });
}
