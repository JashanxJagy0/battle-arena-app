import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class RankBadge extends StatelessWidget {
  final int rank;

  const RankBadge({super.key, required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank == 1) {
      return _buildBadge('👑', const Color(0xFFFFD700));
    } else if (rank == 2) {
      return _buildBadge('🥈', const Color(0xFFC0C0C0));
    } else if (rank == 3) {
      return _buildBadge('🥉', const Color(0xFFCD7F32));
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBadge(String emoji, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
    );
  }
}
