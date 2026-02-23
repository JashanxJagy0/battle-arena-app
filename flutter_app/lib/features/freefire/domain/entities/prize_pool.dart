import 'package:equatable/equatable.dart';

class PrizePool extends Equatable {
  final double total;
  final double firstPlace;
  final double secondPlace;
  final double thirdPlace;
  final Map<int, double> positions;

  const PrizePool({
    required this.total,
    required this.firstPlace,
    required this.secondPlace,
    required this.thirdPlace,
    this.positions = const {},
  });

  @override
  List<Object?> get props => [total, firstPlace, secondPlace, thirdPlace, positions];
}
