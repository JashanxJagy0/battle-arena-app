import '../../domain/entities/referral.dart';

class ReferredUserModel extends ReferredUser {
  const ReferredUserModel({
    required super.id,
    required super.username,
    required super.joinedAt,
    required super.status,
  });

  factory ReferredUserModel.fromJson(Map<String, dynamic> json) {
    return ReferredUserModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      joinedAt: DateTime.tryParse(json['joinedAt'] as String? ?? json['createdAt'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'active',
    );
  }
}

class ReferralStatsModel extends ReferralStats {
  const ReferralStatsModel({
    required super.referralCode,
    required super.referralLink,
    required super.totalReferrals,
    required super.totalEarned,
    required super.referredUsers,
  });

  factory ReferralStatsModel.fromJson(Map<String, dynamic> json) {
    final users = (json['referredUsers'] as List<dynamic>? ?? json['referrals'] as List<dynamic>? ?? [])
        .map((e) => ReferredUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return ReferralStatsModel(
      referralCode: json['referralCode'] as String? ?? '',
      referralLink: json['referralLink'] as String? ?? '',
      totalReferrals: json['totalReferrals'] as int? ?? users.length,
      totalEarned: (json['totalEarned'] as num?)?.toDouble() ?? 0.0,
      referredUsers: users,
    );
  }
}
