import 'package:equatable/equatable.dart';
import '../../domain/entities/wager.dart';

abstract class WagerState extends Equatable {
  const WagerState();
  @override
  List<Object?> get props => [];
}

class WagerInitial extends WagerState {
  const WagerInitial();
}

class WagerLoading extends WagerState {
  const WagerLoading();
}

class WagerLoaded extends WagerState {
  final WagerStats stats;
  final List<Wager> wagers;
  final List<Map<String, dynamic>> chartData;
  final String currentPeriod;
  final int currentPage;
  final bool hasMore;

  const WagerLoaded({
    required this.stats,
    required this.wagers,
    required this.chartData,
    required this.currentPeriod,
    this.currentPage = 1,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [stats, wagers, chartData, currentPeriod, currentPage];

  WagerLoaded copyWith({
    WagerStats? stats,
    List<Wager>? wagers,
    List<Map<String, dynamic>>? chartData,
    String? currentPeriod,
    int? currentPage,
    bool? hasMore,
  }) {
    return WagerLoaded(
      stats: stats ?? this.stats,
      wagers: wagers ?? this.wagers,
      chartData: chartData ?? this.chartData,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class WagerError extends WagerState {
  final String message;
  const WagerError({required this.message});
  @override
  List<Object?> get props => [message];
}
