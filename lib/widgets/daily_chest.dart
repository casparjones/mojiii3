import 'package:flutter/material.dart';

import '../game/game_state_manager.dart';
import '../main.dart';
import 'emoji_text.dart';

/// Describes a reward the player received from the daily chest.
class _RewardDisplay {
  final String emoji;
  final String title;
  final String subtitle;

  const _RewardDisplay({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
}

/// A tappable daily chest button shown on the main menu.
///
/// When the chest is available it glows and wobbles. After claiming, it shows
/// a countdown until the next day.
class DailyChestButton extends StatefulWidget {
  const DailyChestButton({super.key});

  @override
  State<DailyChestButton> createState() => _DailyChestButtonState();
}

class _DailyChestButtonState extends State<DailyChestButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wobbleController;
  late final Animation<double> _wobbleAnimation;

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _wobbleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.06)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.06, end: -0.06)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.06, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_wobbleController);
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    super.dispose();
  }

  String _timeUntilMidnight() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  void _openChest(BuildContext context) {
    final gsm = GameStateManagerProvider.read(context);
    if (!gsm.canClaimDailyChest) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DailyChestDialog(gameStateManager: gsm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gsm = GameStateManagerProvider.of(context);
    final canClaim = gsm.canClaimDailyChest;

    return GestureDetector(
      onTap: canClaim ? () => _openChest(context) : null,
      child: AnimatedBuilder(
        animation: _wobbleAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: canClaim ? _wobbleAnimation.value : 0.0,
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: canClaim
                      ? [const Color(0xFFFFD700), const Color(0xFFFF8C00)]
                      : [Colors.grey.shade700, Colors.grey.shade800],
                ),
                boxShadow: canClaim
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: EmojiText(
                  canClaim ? '\uD83C\uDF81' : '\uD83D\uDD12',
                  fontSize: 30,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              canClaim ? 'Daily Chest' : _timeUntilMidnight(),
              style: TextStyle(
                color: canClaim ? const Color(0xFFFFD700) : Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The chest opening dialog with animation and reward reveal.
class _DailyChestDialog extends StatefulWidget {
  final GameStateManager gameStateManager;

  const _DailyChestDialog({required this.gameStateManager});

  @override
  State<_DailyChestDialog> createState() => _DailyChestDialogState();
}

class _DailyChestDialogState extends State<_DailyChestDialog>
    with TickerProviderStateMixin {
  /// Phases: 0 = chest shown, 1 = opening anim, 2 = reward revealed
  int _phase = 0;
  Map<String, dynamic>? _reward;
  _RewardDisplay? _display;

  late final AnimationController _openController;
  late final Animation<double> _shakeAnimation;
  late final AnimationController _revealController;
  late final Animation<double> _revealScale;

  @override
  void initState() {
    super.initState();

    _openController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.1),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.1, end: -0.1),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.1, end: 0.12),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.12, end: -0.12),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.12, end: 0.15),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.15, end: -0.15),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.15, end: 0.0),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: 30,
      ),
    ]).animate(_openController);

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _revealScale = CurvedAnimation(
      parent: _revealController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _openController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  void _onTapChest() {
    if (_phase != 0) return;
    setState(() => _phase = 1);
    _openController.forward().then((_) {
      // Claim the reward
      _reward = widget.gameStateManager.claimDailyChest();
      _display = _rewardToDisplay(_reward);
      setState(() => _phase = 2);
      _revealController.forward();
    });
  }

  _RewardDisplay _rewardToDisplay(Map<String, dynamic>? reward) {
    if (reward == null) {
      return const _RewardDisplay(
          emoji: '\u2753', title: 'No reward', subtitle: 'Already claimed');
    }
    switch (reward['type'] as String) {
      case 'coins':
        final amount = reward['amount'] as int;
        return _RewardDisplay(
          emoji: '\uD83E\uDE99',
          title: '+$amount Coins',
          subtitle: 'Added to your balance!',
        );
      case 'powerup':
        final id = reward['id'] as String;
        final names = {
          'powerup_extra_moves': ('Extra Moves', '\uD83D\uDC8A'),
          'powerup_shuffle': ('Shuffle', '\uD83D\uDD00'),
          'powerup_color_bomb': ('Color Bomb', '\uD83D\uDCA3\uD83C\uDF08'),
        };
        final info = names[id] ?? ('Power-Up', '\u2728');
        return _RewardDisplay(
          emoji: info.$2,
          title: '1x ${info.$1}',
          subtitle: 'Added to your inventory!',
        );
      case 'theme':
        final name = reward['name'] as String? ?? 'Theme';
        return _RewardDisplay(
          emoji: '\uD83C\uDFA8',
          title: name,
          subtitle: 'New theme unlocked!',
        );
      case 'bonus_moves':
        final amount = reward['amount'] as int;
        return _RewardDisplay(
          emoji: '\uD83D\uDEB6',
          title: '+$amount Bonus Moves',
          subtitle: 'Added to your reserves!',
        );
      default:
        return const _RewardDisplay(
            emoji: '\u2728', title: 'Reward', subtitle: '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2a1a4e), Color(0xFF1a1a2e)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.2),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Daily Chest',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _phase < 2 ? 'Tap to open!' : 'You received:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            // Chest or reward
            SizedBox(
              height: 120,
              child: _phase < 2 ? _buildChest() : _buildReward(),
            ),
            const SizedBox(height: 24),
            // Close button (only after reward)
            if (_phase == 2)
              ScaleTransition(
                scale: _revealScale,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Collect!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChest() {
    return GestureDetector(
      onTap: _onTapChest,
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _phase == 1 ? _shakeAnimation.value : 0.0,
            child: child,
          );
        },
        child: AnimatedScale(
          scale: _phase == 0 ? 1.0 : 1.2,
          duration: const Duration(milliseconds: 400),
          child: const EmojiText('\uD83C\uDF81', fontSize: 80),
        ),
      ),
    );
  }

  Widget _buildReward() {
    final d = _display;
    if (d == null) return const SizedBox.shrink();

    return ScaleTransition(
      scale: _revealScale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmojiText(d.emoji, fontSize: 48),
          const SizedBox(height: 8),
          Text(
            d.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            d.subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
