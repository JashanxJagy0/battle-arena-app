import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String type;
  final double amount;
  final String currency;
  final String status;
  final String? description;
  final String? referenceId;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    this.description,
    this.referenceId,
    required this.createdAt,
  });

  bool get isCredit =>
      ['deposit', 'tournament_winning', 'wager_winning', 'bonus', 'referral', 'refund'].contains(type);

  @override
  List<Object?> get props => [id, type, amount, currency, status, description, referenceId, createdAt];
}
