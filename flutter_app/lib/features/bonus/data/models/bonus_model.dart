import '../../domain/entities/bonus.dart';

class BonusModel extends Bonus {
  const BonusModel({
    required super.id,
    required super.bonusType,
    required super.amount,
    required super.wageringRequirement,
    required super.wageredAmount,
    required super.isClaimed,
    required super.isExpired,
    super.expiresAt,
    super.claimedAt,
    super.promoCode,
    super.description,
  });

  factory BonusModel.fromJson(Map<String, dynamic> json) {
    return BonusModel(
      id: json['id'] as String? ?? '',
      bonusType: _parseType(json['type'] as String? ?? json['bonusType'] as String? ?? ''),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      wageringRequirement: (json['wageringRequirement'] as num?)?.toDouble() ?? 0.0,
      wageredAmount: (json['wageredAmount'] as num?)?.toDouble() ?? 0.0,
      isClaimed: json['isClaimed'] as bool? ?? false,
      isExpired: json['isExpired'] as bool? ?? false,
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'] as String) : null,
      claimedAt: json['claimedAt'] != null ? DateTime.tryParse(json['claimedAt'] as String) : null,
      promoCode: json['promoCode'] as String?,
      description: json['description'] as String?,
    );
  }

  static BonusType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'daily': return BonusType.daily;
      case 'weekly': return BonusType.weekly;
      case 'monthly': return BonusType.monthly;
      case 'promo': return BonusType.promo;
      case 'referral': return BonusType.referral;
      default: return BonusType.daily;
    }
  }
}
