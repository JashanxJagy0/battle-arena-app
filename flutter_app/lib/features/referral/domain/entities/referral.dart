import 'package:equatable/equatable.dart';

class ReferralStats extends Equatable {
  final String referralCode;
  final String referralLink;
  final int totalReferrals;
  final double totalEarned;
  final List<ReferredUser> referredUsers;

  const ReferralStats({
    required this.referralCode,
    required this.referralLink,
    required this.totalReferrals,
    required this.totalEarned,
    required this.referredUsers,
  });

  @override
  List<Object?> get props => [referralCode, totalReferrals, totalEarned];
}

class ReferredUser extends Equatable {
  final String id;
  final String username;
  final DateTime joinedAt;
  final String status;

  const ReferredUser({
    required this.id,
    required this.username,
    required this.joinedAt,
    required this.status,
  });

  @override
  List<Object?> get props => [id];
}
