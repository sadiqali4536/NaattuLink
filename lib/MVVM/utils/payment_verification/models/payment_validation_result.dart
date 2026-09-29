enum PaymentVerificationStatus {
  valid,
  invalid,
  needsReview,
}

enum PaymentValidationReason {
  amountNotFound,
  amountMismatch,
  transactionIdNotFound,
  successEvidenceNotFound,
  dateNotFound,
  timeNotFound,
  paymentBeforeQrCreation,
  paymentAfterQrExpiry,
  receiverNotFound,
  receiverMismatch,
}

class PaymentValidationResult {
  final PaymentVerificationStatus status;
  final List<PaymentValidationReason> reasons;

  const PaymentValidationResult({
    required this.status,
    this.reasons = const [],
  });
}
