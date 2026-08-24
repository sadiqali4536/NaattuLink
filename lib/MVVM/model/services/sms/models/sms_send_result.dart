class SmsSendResult {
  final bool success;
  final String? providerId;
  final String? error;

  const SmsSendResult({
    required this.success,
    this.providerId,
    this.error,
  });
}
