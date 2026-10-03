/// One client account (`GET /accounts`). `accountId` doubles as the
/// portfolio ID used by `/portfolios/{portfolioId}` and notification payloads.
class Account {
  const Account({
    required this.accountId,
    required this.label,
    required this.totalMarketValue,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        accountId: json['accountId'] as String,
        label: (json['label'] as String?) ?? json['accountId'] as String,
        totalMarketValue: (json['totalMarketValue'] as num?)?.toDouble() ?? 0,
      );

  final String accountId;
  final String label;
  final double totalMarketValue;

  @override
  bool operator ==(Object other) =>
      other is Account &&
      other.accountId == accountId &&
      other.label == label &&
      other.totalMarketValue == totalMarketValue;

  @override
  int get hashCode => Object.hash(accountId, label, totalMarketValue);
}
