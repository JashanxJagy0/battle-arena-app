enum TransactionType {
  deposit('deposit', 'Deposit'),
  withdrawal('withdrawal', 'Withdrawal'),
  tournamentEntryFee('tournament_entry_fee', 'Tournament Entry Fee'),
  tournamentWinning('tournament_winning', 'Tournament Winning'),
  wager('wager', 'Wager'),
  wagerWinning('wager_winning', 'Wager Winning'),
  bonus('bonus', 'Bonus'),
  referral('referral', 'Referral Bonus'),
  refund('refund', 'Refund');

  final String value;
  final String displayName;

  const TransactionType(this.value, this.displayName);

  factory TransactionType.fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionType.deposit,
    );
  }
}
