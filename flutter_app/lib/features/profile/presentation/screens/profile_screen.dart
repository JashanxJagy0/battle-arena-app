import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/profile_bloc.dart';
import '../../domain/entities/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const LoadProfile());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileBloc>().add(const LoadProfile()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          UserProfile? profile;
          if (state is ProfileLoaded) profile = state.profile;
          if (state is ProfileUpdated) profile = state.profile;

          return _buildContent(context, profile);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserProfile? profile) {
    return RefreshIndicator(
      onRefresh: () async => context.read<ProfileBloc>().add(const LoadProfile()),
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            backgroundColor: AppColors.background,
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                onPressed: () => context.push('/profile/edit'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  // Avatar & Name
                  FadeInDown(
                    child: _buildAvatarSection(context, profile),
                  ),
                  const SizedBox(height: 24),

                  // Stats row
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    child: _buildStatsRow(profile),
                  ),
                  const SizedBox(height: 20),

                  // Game info
                  if (profile?.freefireUid != null || profile?.freefireIgn != null) ...[
                    FadeInDown(
                      delay: const Duration(milliseconds: 150),
                      child: _buildGameInfoCard(profile!),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Quick Links
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: _buildQuickLinks(context),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, UserProfile? profile) {
    final xpProgress = profile != null && profile.xpToNextLevel > 0
        ? (profile.xp / profile.xpToNextLevel).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
                boxShadow: [
                  BoxShadow(color: AppColors.primaryGlow, blurRadius: 16, spreadRadius: 2),
                ],
              ),
              child: ClipOval(
                child: profile?.avatarUrl != null
                    ? Image.network(profile!.avatarUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultAvatar())
                    : _defaultAvatar(),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/profile/edit'),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.black, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '@${profile?.username ?? '...'}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⭐', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              'Level ${profile?.level ?? 1}',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // XP bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: xpProgress,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${profile?.xp ?? 0} / ${profile?.xpToNextLevel ?? 1000} XP',
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 4),
        if (profile != null)
          Text(
            'Member since ${DateFormat('MMM yyyy').format(profile.memberSince)}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
      ],
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppColors.cardBackground,
      child: const Icon(Icons.person, color: AppColors.primary, size: 48),
    );
  }

  Widget _buildStatsRow(UserProfile? profile) {
    final stats = [
      {'label': 'Games', 'value': '${profile?.totalGames ?? 0}'},
      {'label': 'Wins', 'value': '${profile?.totalWins ?? 0}'},
      {'label': 'Loss', 'value': '${profile?.totalLosses ?? 0}'},
      {'label': 'Win%', 'value': '${(profile?.winRate ?? 0).toStringAsFixed(0)}%'},
    ];

    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Text(
                  s['value']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s['label']!,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGameInfoCard(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          if (profile.freefireUid != null)
            Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                const Text('Free Fire UID: ', style: TextStyle(color: Colors.white54, fontSize: 13)),
                Text(profile.freefireUid!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          if (profile.freefireUid != null && profile.freefireIgn != null)
            const Divider(color: AppColors.divider, height: 16),
          if (profile.freefireIgn != null)
            Row(
              children: [
                const Text('🎮', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                const Text('IGN: ', style: TextStyle(color: Colors.white54, fontSize: 13)),
                Text(profile.freefireIgn!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    final links = [
      {'icon': Icons.bar_chart_rounded, 'label': 'Wager History', 'route': '/wagers'},
      {'icon': Icons.emoji_events_rounded, 'label': 'Leaderboard', 'route': '/leaderboard'},
      {'icon': Icons.card_giftcard_rounded, 'label': 'Bonuses', 'route': '/bonuses'},
      {'icon': Icons.people_rounded, 'label': 'Referrals', 'route': '/referral'},
      {'icon': Icons.notifications_rounded, 'label': 'Notifications', 'route': '/notifications'},
      {'icon': Icons.settings_rounded, 'label': 'Settings', 'route': '/settings'},
      {'icon': Icons.support_agent_rounded, 'label': 'Support', 'route': null},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              '── Quick Links ──',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          ...links.map((link) {
            return Column(
              children: [
                ListTile(
                  leading: Icon(link['icon'] as IconData, color: AppColors.primary, size: 22),
                  title: Text(
                    link['label'] as String,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
                  dense: true,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (link['route'] != null) {
                      context.push(link['route'] as String);
                    }
                  },
                ),
                if (link != links.last)
                  const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
              ],
            );
          }),
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
            title: const Text('Logout', style: TextStyle(color: AppColors.error, fontSize: 14)),
            dense: true,
            onTap: () {
              HapticFeedback.mediumImpact();
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
