import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../bloc/ludo_bloc.dart';

class LudoLobbyScreen extends StatefulWidget {
  const LudoLobbyScreen({super.key});

  @override
  State<LudoLobbyScreen> createState() => _LudoLobbyScreenState();
}

class _LudoLobbyScreenState extends State<LudoLobbyScreen> {
  String _selectedMode = '1v1';
  double _selectedFee = 1.0;
  bool _isCustomFee = false;
  final _customFeeController = TextEditingController();

  static const _modes = ['1v1', '2v2', '4-Player'];
  static const _fees = [0.50, 1.0, 2.0, 5.0, 10.0, 25.0, 50.0];

  @override
  void initState() {
    super.initState();
    context.read<LudoBloc>().add(const LoadMatches());
  }

  @override
  void dispose() {
    _customFeeController.dispose();
    super.dispose();
  }

  void _createMatch() {
    final fee = _isCustomFee
        ? double.tryParse(_customFeeController.text) ?? 0.0
        : _selectedFee;
    context.read<LudoBloc>().add(
          CreateMatch(gameMode: _selectedMode, entryFee: fee),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LudoBloc, LudoState>(
      listener: (context, state) {
        if (state is LudoMatchmaking) {
          context.go(
            '/ludo/matchmaking',
            extra: {
              'matchId': state.match.matchId,
              'matchCode': state.matchCode,
            },
          );
        } else if (state is LudoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              title: const Text(
                'Ludo Arena',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              bottom: const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2,
                tabs: [
                  Tab(text: 'Create Match'),
                  Tab(text: 'Open Matches'),
                  Tab(text: 'My Matches'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _CreateMatchTab(
                  selectedMode: _selectedMode,
                  selectedFee: _selectedFee,
                  isCustomFee: _isCustomFee,
                  customFeeController: _customFeeController,
                  isLoading: state is LudoLoading,
                  modes: _modes,
                  fees: _fees,
                  onModeChanged: (mode) => setState(() => _selectedMode = mode),
                  onFeeChanged: (fee) => setState(() {
                    _selectedFee = fee;
                    _isCustomFee = false;
                  }),
                  onCustomFeeToggle: () =>
                      setState(() => _isCustomFee = true),
                  onCreateMatch: _createMatch,
                ),
                _OpenMatchesTab(state: state),
                _MyMatchesTab(state: state),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Create Match Tab ──────────────────────────────────────────────────────────

class _CreateMatchTab extends StatelessWidget {
  final String selectedMode;
  final double selectedFee;
  final bool isCustomFee;
  final TextEditingController customFeeController;
  final bool isLoading;
  final List<String> modes;
  final List<double> fees;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<double> onFeeChanged;
  final VoidCallback onCustomFeeToggle;
  final VoidCallback onCreateMatch;

  const _CreateMatchTab({
    required this.selectedMode,
    required this.selectedFee,
    required this.isCustomFee,
    required this.customFeeController,
    required this.isLoading,
    required this.modes,
    required this.fees,
    required this.onModeChanged,
    required this.onFeeChanged,
    required this.onCustomFeeToggle,
    required this.onCreateMatch,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Game Mode'),
          const SizedBox(height: 12),
          Row(
            children: List.generate(modes.length, (i) {
              final mode = modes[i];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < modes.length - 1 ? 8 : 0),
                  child: _ModeButton(
                    label: mode,
                    isSelected: selectedMode == mode,
                    onTap: () => onModeChanged(mode),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          const _SectionLabel('Entry Fee'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...fees.map((fee) => _FeeChip(
                    label:
                        '\$${fee % 1 == 0 ? fee.toInt() : fee.toStringAsFixed(2)}',
                    isSelected: !isCustomFee && selectedFee == fee,
                    onTap: () => onFeeChanged(fee),
                  )),
              _FeeChip(
                label: 'Custom',
                isSelected: isCustomFee,
                onTap: onCustomFeeToggle,
              ),
            ],
          ),
          if (isCustomFee) ...[
            const SizedBox(height: 16),
            TextField(
              controller: customFeeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: const TextStyle(
                    color: AppColors.primary, fontSize: 16),
                hintText: 'Enter amount',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
          const SizedBox(height: 36),
          GradientButton(
            text: 'CREATE MATCH',
            isLoading: isLoading,
            onPressed: onCreateMatch,
            gradient: AppColors.primaryGradient,
            icon: Icons.add_circle_outline,
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: AppColors.primaryGradient)
              : null,
          color: isSelected ? null : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primaryGlow, blurRadius: 10)]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color:
                  isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FeeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: AppColors.secondaryGradient)
              : null,
          color: isSelected ? null : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.secondary
                : AppColors.border,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.secondaryGlow, blurRadius: 8)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected ? Colors.black : AppColors.textSecondary,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Open Matches Tab ──────────────────────────────────────────────────────────

class _OpenMatchesTab extends StatelessWidget {
  final LudoState state;

  const _OpenMatchesTab({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state is LudoLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final matches =
        state is LudoLobbyLoaded ? (state as LudoLobbyLoaded).openMatches : [];

    if (matches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'No open matches',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return _MatchCard(
          matchCode: match.matchCode,
          entryFee: match.entryFee,
          prizePool: match.prizePool,
          gameMode: match.gameMode,
          playerCount: match.players.length,
          onTap: () =>
              context.read<LudoBloc>().add(JoinMatch(match.matchId)),
        );
      },
    );
  }
}

class _MatchCard extends StatelessWidget {
  final String matchCode;
  final double entryFee;
  final double prizePool;
  final String gameMode;
  final int playerCount;
  final VoidCallback onTap;

  const _MatchCard({
    required this.matchCode,
    required this.entryFee,
    required this.prizePool,
    required this.gameMode,
    required this.playerCount,
    required this.onTap,
  });

  int get _maxPlayers =>
      gameMode.toLowerCase() == '1v1' ? 2 : 4;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#$matchCode',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Badge(gameMode),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                        label: 'Entry',
                        value: '\$${entryFee.toStringAsFixed(2)}',
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        label: 'Prize',
                        value: '\$${prizePool.toStringAsFixed(2)}',
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$playerCount/$_maxPlayers',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Text(
                  'Players',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: AppColors.primaryGradient),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'JOIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── My Matches Tab ────────────────────────────────────────────────────────────

class _MyMatchesTab extends StatelessWidget {
  final LudoState state;

  const _MyMatchesTab({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state is LudoLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final matches =
        state is LudoLobbyLoaded ? (state as LudoLobbyLoaded).myMatches : [];

    if (matches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 56, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'No matches yet',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        final isFinished = match.status == 'finished';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFinished
                      ? AppColors.secondary.withOpacity(0.15)
                      : AppColors.primary.withOpacity(0.15),
                ),
                child: Icon(
                  isFinished ? Icons.emoji_events : Icons.pending,
                  color: isFinished
                      ? AppColors.secondary
                      : AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isFinished
                              ? 'Finished'
                              : match.status.toUpperCase(),
                          style: TextStyle(
                            color: isFinished
                                ? AppColors.secondary
                                : AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Badge(match.gameMode),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prize Pool: \$${match.prizePool.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '#${match.matchCode}',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
