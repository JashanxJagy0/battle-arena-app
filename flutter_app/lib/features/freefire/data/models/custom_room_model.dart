import '../../domain/entities/custom_room.dart';

class CustomRoomModel extends CustomRoom {
  const CustomRoomModel({
    required super.roomId,
    required super.roomCode,
    required super.password,
    required super.startTime,
    required super.serverRegion,
  });

  factory CustomRoomModel.fromJson(Map<String, dynamic> json) {
    return CustomRoomModel(
      roomId: json['roomId'] as String? ?? json['_id'] as String? ?? '',
      roomCode: json['roomCode'] as String? ?? '',
      password: json['password'] as String? ?? '',
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : DateTime.now(),
      serverRegion: json['serverRegion'] as String? ?? 'Asia',
    );
  }
}
