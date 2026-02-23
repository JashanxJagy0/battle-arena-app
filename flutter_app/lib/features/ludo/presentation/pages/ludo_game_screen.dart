import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/ludo_bloc.dart';
import '../widgets/dice_widget.dart';
import '../widgets/game_timer_widget.dart';
import '../widgets/ludo_board_widget.dart';
import '../widgets/player_panel.dart';

class LudoGameScreen extends StatefulWidget {
  final String matchId;
  final String myUserId;

  const LudoGameScreen({
    required this.matchId,
    required this.myUserId,
    super.key,
  });

  @override
  State<LudoGameScreen> createState() => _LudoGameScreenState();
}

class _LudoGameScreenState extends State<LudoGameScreen> {
  static const _emojis = ['😎', '😡', '👏', '😂', '🔥', '💀'];

  @override
  void initState() {
    super.initState();
    context.read<LudoBloc>().add(
          ConnectToMatch(
            matchId: widget.matchId,
            myUserId: widget.myUserId,
          ),
        );
  }

  @override
  void dispose() {
    context.read<LudoBloc>().add(const DisconnectFromMatch());
    super.dispose();
  }

  void _onPieceTap(int pieceId, int toPos) {
    context.read<LudoBloc>().add(
          MovePiece(
            matchId: widget.matchId,
            pieceId: pieceId,
            toPos: toPos,
          ),
        );
  }

  void _onDiceTap() {
    context
        .read<LudoBloc>()
        .add(RollDice(widget.matchId));
  }

  void _onEmojiTap(String emoji) {
    context.read<LudoBloc>().add(
          SendEmoji(matchId: widget.matchId, emoji: emoji),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LudoBloc, LudoState>(
      listener: (context, state) {
        if (state is LudoGameOver) {
          context.go('/ludo/result/${widget.matchId}');
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
        // Extract game data from relevant states
        final gameState = _extractGameState(state);
        if (gameState == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final myPlayer = gameState.game.players
            .where((p) => p.userId == widget.myUserId)
            .firstOrNull;
        final opponentPlayer = gameState.game.players
            .where((p) => p.userId != widget.myUserId)
            .firstOrNull;

        final isConnected = gameState.isConnected;
        final isRolling = state is LudoDiceRolling;
        final diceValue = gameState.lastDiceValue ?? 1;
        final validMoves = gameState.validMoves;
        final myColor = myPlayer?.color ?? '';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            title: const Text(
              'Ludo Match',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected
                            ? AppColors.secondary
                            : Colors.yellow.shade600,
                        boxShadow: [
                          BoxShadow(
                            color: (isConnected
                                    ? AppColors.secondary
                                    : Colors.yellow.shade600)
                                .withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? 'Connected' : 'Reconnecting',
                      style: TextStyle(
                        color: isConnected
                            ? AppColors.secondary
                            : Colors.yellow.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Opponent panel
              if (opponentPlayer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: PlayerPanel(
                    username: opponentPlayer.username,
                    avatarUrl: opponentPlayer.avatar,
                    color: opponentPlayer.color,
                    piecesHome: opponentPlayer.piecesHome,
                    isMyTurn: gameState.game.turnUserId ==
                        opponentPlayer.userId,
                    isConnected: true,
                    prizeAmount: gameState.game.prizePool / 2,
                  ),
                ),
              // Emoji received overlay
              if (gameState.lastEmoji != null &&
                  gameState.lastEmojiUserId != widget.myUserId)
                _EmojiOverlay(emoji: gameState.lastEmoji!),
              // Board (65% of remaining height)
              Expanded(
                flex: 65,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: LudoBoardWidget(
                    players: gameState.game.players,
                    myColor: myColor,
                    validMoves: validMoves,
                    onPieceTap: _onPieceTap,
                  ),
                ),
              ),
              // My panel + dice + timer
              Expanded(
                flex: 35,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (myPlayer != null)
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(12, 4, 12, 8),
                        child: PlayerPanel(
                          username: myPlayer.username,
                          avatarUrl: myPlayer.avatar,
                          color: myPlayer.color,
                          piecesHome: myPlayer.piecesHome,
                          isMyTurn: gameState.isMyTurn,
                          isConnected: isConnected,
                          prizeAmount: gameState.game.prizePool / 2,
                        ),
                      ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          DiceWidget(
                            faceValue: diceValue,
                            isRolling: isRolling,
                            isMyTurn: gameState.isMyTurn,
                            onTap: gameState.isMyTurn && !isRolling
                                ? _onDiceTap
                                : null,
                          ),
                          GameTimerWidget(
                            secondsLeft: gameState.timerSeconds,
                            isActive: gameState.isMyTurn,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Emoji bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                        children: _emojis.map((emoji) {
                          return GestureDetector(
                            onTap: () => _onEmojiTap(emoji),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius:
                                    BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.border),
                              ),
                              child: Center(
                                child: Text(
                                  emoji,
                                  style:
                                      const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Extracts a unified [LudoInProgress] from any in-game state.
  LudoInProgress? _extractGameState(LudoState state) {
    if (state is LudoInProgress) return state;
    if (state is LudoSelectingPiece) {
      return LudoInProgress(
        game: state.game,
        myUserId: state.myUserId,
        isMyTurn: true,
        lastDiceValue: state.diceValue,
        validMoves: state.validMoves,
      );
    }
    if (state is LudoAnimatingMove) {
      return LudoInProgress(
        game: state.game,
        myUserId: state.myUserId,
        isMyTurn: false,
      );
    }
    if (state is LudoDiceRolling) {
      return LudoInProgress(
        game: state.game,
        myUserId: state.myUserId,
        isMyTurn: true,
      );
    }
    return null;
  }
}

// ── Emoji Overlay ─────────────────────────────────────────────────────────────

class _EmojiOverlay extends StatelessWidget {
  final String emoji;

  const _EmojiOverlay({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 4),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 28)),
        ),
      ),
    );
  }
}
