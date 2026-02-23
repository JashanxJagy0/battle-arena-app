import 'package:equatable/equatable.dart';
import '../../domain/entities/referral.dart';

abstract class ReferralState extends Equatable {
  const ReferralState();
  @override
  List<Object?> get props => [];
}

class ReferralInitial extends ReferralState {
  const ReferralInitial();
}

class ReferralLoading extends ReferralState {
  const ReferralLoading();
}

class ReferralLoaded extends ReferralState {
  final ReferralStats stats;
  const ReferralLoaded({required this.stats});
  @override
  List<Object?> get props => [stats];
}

class ReferralError extends ReferralState {
  final String message;
  const ReferralError({required this.message});
  @override
  List<Object?> get props => [message];
}
