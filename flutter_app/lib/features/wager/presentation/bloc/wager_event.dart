import 'package:equatable/equatable.dart';

abstract class WagerEvent extends Equatable {
  const WagerEvent();
  @override
  List<Object?> get props => [];
}

class LoadWagerHistory extends WagerEvent {
  final String period;
  const LoadWagerHistory({this.period = 'daily'});
  @override
  List<Object?> get props => [period];
}

class LoadMoreWagers extends WagerEvent {
  const LoadMoreWagers();
}

class ChangePeriod extends WagerEvent {
  final String period;
  const ChangePeriod(this.period);
  @override
  List<Object?> get props => [period];
}
