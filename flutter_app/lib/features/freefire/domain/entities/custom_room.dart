import 'package:equatable/equatable.dart';

class CustomRoom extends Equatable {
  final String roomId;
  final String roomCode;
  final String password;
  final DateTime startTime;
  final String serverRegion;

  const CustomRoom({
    required this.roomId,
    required this.roomCode,
    required this.password,
    required this.startTime,
    required this.serverRegion,
  });

  @override
  List<Object?> get props => [roomId, roomCode, password, startTime, serverRegion];
}
