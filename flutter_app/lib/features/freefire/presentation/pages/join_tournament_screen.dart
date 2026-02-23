import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../domain/entities/tournament.dart';
import '../bloc/freefire_bloc.dart';

class JoinTournamentScreen extends StatefulWidget {
  final String tournamentId;
  final Tournament? tournament;

  const JoinTournamentScreen({
    super.key,
    required this.tournamentId,
    this.tournament,
  });

  @override
  State<JoinTournamentScreen> createState() => _JoinTournamentScreenState();
}

class _JoinTournamentScreenState extends State<JoinTournamentScreen>
    with TickerProviderStateMixin {
  bool _termsAccepted = false;
  bool _joining = false;
  bool _success = false;

  late AnimationController _successCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _successCtrl,
      curve: Curves.elasticOut,
    );

    // Load tournament detail if not supplied
    if (widget.tournament == null) {
      context
          .read<FreefireBloc>()
          .add(LoadTournamentDetail(widget.tournamentId));
    }
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    super.dispose();
  }

  void _onJoin() {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms to continue.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    context.read<FreefireBloc>().add(JoinTournament(widget.tournamentId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FreefireBloc, FreefireState>(
      listener: (context, state) {
        if (state is TournamentsLoading) {
          setState(() => _joining = true);
        } else if (state is JoinSuccess) {
          setState(() {
            _joining = false;
            _success = true;
          });
          _successCtrl.forward();
        } else if (state is FreefireError) {
          setState(() => _joining = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final tournament = state is JoinSuccess
            ? state.tournament
            : state is TournamentDetailLoaded
                ? state.tournament
                : widget.tournament;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            title: const Text(
              'Join Tournament',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
            leading: const BackButton(color: Colors.white),
          ),
          body: _success
              ? _SuccessView(
                  tournament: tournament,
                  scaleAnim: _scaleAnim,
                )
              : _JoinForm(
                  tournament: tournament,
                  termsAccepted: _termsAccepted,
                  joining: _joining,
                  onTermsChanged: (v) =>
                      setState(() => _termsAccepted = v ?? false),
                  onJoin: _onJoin,
                ),
        );
      },
    );
  }
}

// ── Success View ──────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final Tournament? tournament;
  final Animation<double> scaleAnim;

  const _SuccessView({required this.tournament, required this.scaleAnim});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: scaleAnim,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: AppColors.secondaryGradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 56),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'You\'re In! 🎮',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (tournament != null) ...[
              const SizedBox(height: 12),
              Text(
                tournament!.title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Entry fee of \$${tournament!.entryFee.toStringAsFixed(2)} deducted',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 32),
            GradientButton(
              text: 'Back to Tournaments',
              gradient: AppColors.primaryGradient,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Join Form ─────────────────────────────────────────────────────────────────

class _JoinForm extends StatelessWidget {
  final Tournament? tournament;
  final bool termsAccepted;
  final bool joining;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onJoin;

  const _JoinForm({
    required this.tournament,
    required this.termsAccepted,
    required this.joining,
    required this.onTermsChanged,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    if (tournament == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tournament info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tournament!.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tournament!.gameMode.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Fee summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _FeeRow(
                  label: 'Entry Fee',
                  value:
                      '\$${tournament!.entryFee.toStringAsFixed(2)}',
                  valueColor: AppColors.textPrimary,
                ),
                const Divider(color: AppColors.border, height: 24),
                _FeeRow(
                  label: 'Prize Pool',
                  value:
                      '\$${tournament!.prizePool.total.toStringAsFixed(2)}',
                  valueColor: const Color(0xFFFFD700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Free Fire UID notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.accent, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your Free Fire UID will be shared with the organizer for room invite.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Terms checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: termsAccepted,
                onChanged: onTermsChanged,
                activeColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border, width: 1.5),
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'I agree to the tournament rules and understand that entry fees are non-refundable once the tournament begins.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Join button
          GradientButton(
            text: joining
                ? 'Joining...'
                : 'Confirm & Pay \$${tournament!.entryFee.toStringAsFixed(2)}',
            gradient: AppColors.secondaryGradient,
            isLoading: joining,
            onPressed: joining ? null : onJoin,
            icon: joining ? null : Icons.sports_esports,
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _FeeRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
