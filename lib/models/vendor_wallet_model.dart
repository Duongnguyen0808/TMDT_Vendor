import 'package:intl/intl.dart';

class VendorWalletSummary {
  VendorWalletSummary({
    required this.balance,
    required this.currency,
    required this.storeTitle,
    required this.transactions,
    this.lastDepositAt,
    this.lastWithdrawAt,
  });

  final double balance;
  final String currency;
  final String? storeTitle;
  final DateTime? lastDepositAt;
  final DateTime? lastWithdrawAt;
  final List<VendorWalletTransaction> transactions;

  static final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  factory VendorWalletSummary.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawTx =
        json['transactions'] is List ? json['transactions'] : const [];
    return VendorWalletSummary(
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'VND',
      storeTitle:
          json['store'] is Map ? json['store']['title']?.toString() : null,
      lastDepositAt: _parseDate(json['lastDepositAt']),
      lastWithdrawAt: _parseDate(json['lastWithdrawAt']),
      transactions: rawTx
          .map((tx) => VendorWalletTransaction.fromJson(
              Map<String, dynamic>.from(tx as Map)))
          .toList(),
    );
  }

  String get formattedBalance => _currencyFormat.format(balance);

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value).toLocal();
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

class VendorWalletTransaction {
  VendorWalletTransaction({
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    this.createdAt,
  });

  final String type;
  final double amount;
  final double balanceAfter;
  final String description;
  final DateTime? createdAt;

  static final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  factory VendorWalletTransaction.fromJson(Map<String, dynamic> json) {
    return VendorWalletTransaction(
      type: json['type']?.toString() ?? 'deposit',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0,
      description: json['description']?.toString() ?? '',
      createdAt: VendorWalletSummary._parseDate(json['createdAt']),
    );
  }

  bool get isCredit => amount >= 0;

  String get formattedAmount => _currencyFormat.format(amount.abs());

  String formattedDate() {
    if (createdAt == null) return '';
    return DateFormat('dd/MM HH:mm').format(createdAt!);
  }
}
