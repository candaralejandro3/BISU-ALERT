class AlertMessage {
  const AlertMessage({
    required this.title,
    required this.detail,
    required this.timestamp,
    required this.isCritical,
  });

  final String title;
  final String detail;
  final DateTime timestamp;
  final bool isCritical;
}
