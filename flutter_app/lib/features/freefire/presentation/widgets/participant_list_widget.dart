import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/participant_model.dart';

/// Scrollable list of tournament participants with avatar and FF UID.
class ParticipantListWidget extends StatelessWidget {
  final List<ParticipantModel> participants;

  const ParticipantListWidget({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const Center(
        child: Text(
          'No participants yet',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        return _ParticipantRow(
          participant: participants[index],
          index: index,
        );
      },
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final ParticipantModel participant;
  final int index;

  const _ParticipantRow({required this.participant, required this.index});

  @override
  Widget build(BuildContext context) {
    final initials = participant.username.isNotEmpty
        ? participant.username[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + UID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.username,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (participant.userId.isNotEmpty)
                  Text(
                    'FF UID: ${participant.userId}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          // Check-in status
          if (participant.isCheckedIn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppColors.secondary.withOpacity(0.5)),
              ),
              child: const Text(
                'Checked In',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
