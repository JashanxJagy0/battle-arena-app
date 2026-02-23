import 'package:flutter/material.dart';

import '../../domain/entities/ludo_player.dart';
import '../../engine/board_logic.dart';
import '../../engine/move_validator.dart';

class LudoBoardWidget extends StatefulWidget {
  final List<LudoPlayer> players;
  final String? myColor;
  final List<ValidMove> validMoves;
  final Function(int pieceId, int toPos) onPieceTap;

  const LudoBoardWidget({
    required this.players,
    required this.myColor,
    required this.validMoves,
    required this.onPieceTap,
    super.key,
  });

  @override
  State<LudoBoardWidget> createState() => _LudoBoardWidgetState();
}

class _LudoBoardWidgetState extends State<LudoBoardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Color _playerColor(String color) {
    switch (color.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'blue':
        return Colors.blue.shade600;
      default:
        return Colors.grey;
    }
  }

  void _handleTap(Offset localPosition, double cellSize) {
    final col = (localPosition.dx / cellSize).floor();
    final row = (localPosition.dy / cellSize).floor();

    final boardLogic = BoardLogic();
    for (final player in widget.players) {
      if (player.color != widget.myColor) continue;
      for (int i = 0; i < player.pieces.length; i++) {
        final pos = player.pieces[i];
        final gridPos = boardLogic.logicalToGrid(pos, player.color);
        if (gridPos.dx.toInt() == row && gridPos.dy.toInt() == col) {
          final matching =
              widget.validMoves.where((m) => m.pieceId == i).toList();
          if (matching.isNotEmpty) {
            widget.onPieceTap(i, matching.first.toPos);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          final cellSize = size / 15;
          return AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, _) {
              return GestureDetector(
                onTapUp: (d) => _handleTap(d.localPosition, cellSize),
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _LudoBoardPainter(
                    players: widget.players,
                    validMoves: widget.validMoves,
                    glowOpacity: _glowAnimation.value,
                    playerColorFn: _playerColor,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LudoBoardPainter extends CustomPainter {
  final List<LudoPlayer> players;
  final List<ValidMove> validMoves;
  final double glowOpacity;
  final Color Function(String) playerColorFn;

  static final _boardLogic = BoardLogic();

  // Safe zone shared-path indices (matches BoardLogic._safeZones).
  static const Set<int> _safeZones = {0, 8, 13, 21, 26, 34, 39, 47};

  _LudoBoardPainter({
    required this.players,
    required this.validMoves,
    required this.glowOpacity,
    required this.playerColorFn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 15;
    _drawBackground(canvas, size);
    _drawHomeQuadrants(canvas, cellSize);
    _drawPathCells(canvas, cellSize);
    _drawHomeColumns(canvas, cellSize);
    _drawCenterArea(canvas, cellSize);
    _drawBorderGrid(canvas, cellSize, size);
    _drawPieces(canvas, cellSize);
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0A0E21),
    );
  }

  void _drawHomeQuadrants(Canvas canvas, double cellSize) {
    final quadrants = [
      _Quadrant(
          rowStart: 0,
          rowEnd: 5,
          colStart: 0,
          colEnd: 5,
          color: Colors.red.shade700),
      _Quadrant(
          rowStart: 0,
          rowEnd: 5,
          colStart: 9,
          colEnd: 14,
          color: Colors.green.shade700),
      _Quadrant(
          rowStart: 9,
          rowEnd: 14,
          colStart: 9,
          colEnd: 14,
          color: Colors.yellow.shade700),
      _Quadrant(
          rowStart: 9,
          rowEnd: 14,
          colStart: 0,
          colEnd: 5,
          color: Colors.blue.shade700),
    ];

    for (final q in quadrants) {
      final rect = Rect.fromLTWH(
        q.colStart * cellSize,
        q.rowStart * cellSize,
        (q.colEnd - q.colStart + 1) * cellSize,
        (q.rowEnd - q.rowStart + 1) * cellSize,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..color = q.color,
      );
      // Inner white area where pieces sit
      final innerRect = rect.deflate(cellSize * 0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(innerRect, const Radius.circular(4)),
        Paint()..color = const Color(0xFF1A1F3D),
      );
    }
  }

  void _drawPathCells(Canvas canvas, double cellSize) {
    final path = _boardLogic.getBoardPath();
    final pathPaint = Paint()..color = Colors.white.withOpacity(0.88);
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < path.length; i++) {
      final cell = path[i];
      final rect = _cellRect(cell.dx.toInt(), cell.dy.toInt(), cellSize);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(2)),
        pathPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(2)),
        borderPaint,
      );
      if (_safeZones.contains(i)) {
        _drawStar(canvas, rect.center, cellSize * 0.32);
      }
    }
  }

  void _drawHomeColumns(Canvas canvas, double cellSize) {
    final colors = {
      'red': Colors.red.shade300,
      'green': Colors.green.shade300,
      'yellow': Colors.yellow.shade300,
      'blue': Colors.blue.shade300,
    };
    for (final entry in colors.entries) {
      final col = _boardLogic.getHomeColumn(entry.key);
      final paint = Paint()..color = entry.value;
      for (final cell in col) {
        final rect = _cellRect(cell.dx.toInt(), cell.dy.toInt(), cellSize);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(2)),
          paint,
        );
      }
    }
  }

  void _drawCenterArea(Canvas canvas, double cellSize) {
    // Draw 4 triangles for the center 3×3 area.
    final centerLeft = 6 * cellSize;
    final centerTop = 6 * cellSize;
    final centerSize = 3 * cellSize;

    final triangleColors = [
      Colors.red.shade400,
      Colors.green.shade400,
      Colors.yellow.shade400,
      Colors.blue.shade400,
    ];

    final cx = centerLeft + centerSize / 2;
    final cy = centerTop + centerSize / 2;

    final corners = [
      Offset(centerLeft, centerTop), // top-left
      Offset(centerLeft + centerSize, centerTop), // top-right
      Offset(centerLeft + centerSize, centerTop + centerSize), // bottom-right
      Offset(centerLeft, centerTop + centerSize), // bottom-left
    ];

    for (int t = 0; t < 4; t++) {
      final tri = Path()
        ..moveTo(cx, cy)
        ..lineTo(corners[t].dx, corners[t].dy)
        ..lineTo(corners[(t + 1) % 4].dx, corners[(t + 1) % 4].dy)
        ..close();
      canvas.drawPath(tri, Paint()..color = triangleColors[t]);
    }

    // White star in the very center.
    _drawStar(canvas, Offset(cx, cy), cellSize * 0.55);
  }

  void _drawBorderGrid(Canvas canvas, double cellSize, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFF2D3462)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 15; i++) {
      canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, size.height), borderPaint);
      canvas.drawLine(Offset(0, i * cellSize), Offset(size.width, i * cellSize), borderPaint);
    }
  }

  void _drawPieces(Canvas canvas, double cellSize) {
    final boardLogic = BoardLogic();
    // Track valid-move piece ids for current player.
    final validPieceIds = validMoves.map((m) => m.pieceId).toSet();

    for (final player in players) {
      final basePositions = boardLogic.getHomeBasePositions(player.color);
      int baseIdx = 0;
      for (int i = 0; i < player.pieces.length; i++) {
        final pos = player.pieces[i];
        final Offset gridCell;
        if (pos == -1) {
          // Place in home base slot.
          gridCell = basePositions[baseIdx % basePositions.length];
          baseIdx++;
        } else {
          gridCell = boardLogic.logicalToGrid(pos, player.color);
        }

        final center = Offset(
          (gridCell.dy + 0.5) * cellSize,
          (gridCell.dx + 0.5) * cellSize,
        );
        final radius = cellSize * 0.33;
        final pieceColor = playerColorFn(player.color);

        final isValidMove = validPieceIds.contains(i);

        if (isValidMove) {
          // Glow ring.
          canvas.drawCircle(
            center,
            radius + cellSize * 0.15,
            Paint()
              ..color = pieceColor.withOpacity(glowOpacity * 0.7)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );
        }

        // Outer shadow.
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = Colors.black.withOpacity(0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );

        // Fill circle.
        canvas.drawCircle(center, radius, Paint()..color = pieceColor);

        // Inner highlight.
        canvas.drawCircle(
          Offset(center.dx - radius * 0.25, center.dy - radius * 0.25),
          radius * 0.35,
          Paint()..color = Colors.white.withOpacity(0.45),
        );

        // Border.
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = Colors.white.withOpacity(0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '★',
        style: TextStyle(
          fontSize: radius * 2,
          color: const Color(0xFFFFD700),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2),
    );
  }

  Rect _cellRect(int row, int col, double cellSize) {
    return Rect.fromLTWH(
      col * cellSize,
      row * cellSize,
      cellSize,
      cellSize,
    );
  }

  @override
  bool shouldRepaint(_LudoBoardPainter old) =>
      old.players != players ||
      old.validMoves != validMoves ||
      old.glowOpacity != glowOpacity;
}

class _Quadrant {
  final int rowStart, rowEnd, colStart, colEnd;
  final Color color;
  const _Quadrant({
    required this.rowStart,
    required this.rowEnd,
    required this.colStart,
    required this.colEnd,
    required this.color,
  });
}
