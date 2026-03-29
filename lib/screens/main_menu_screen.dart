import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../game/music_manager.dart';
import '../main.dart';
import '../models/emoji_theme.dart';
import '../widgets/daily_chest.dart';
import '../widgets/emoji_text.dart';
import 'level_select_screen.dart';
import 'shop_screen.dart';
import 'settings_screen.dart';

/// A floating emoji that drifts around the background.
class _FloatingEmoji {
  double x;
  double y;
  double size;
  double speed;
  double angle;
  String emoji;
  double opacity;

  _FloatingEmoji({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    required this.emoji,
    required this.opacity,
  });
}

/// Main menu screen with animated floating emojis and navigation buttons.
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  List<String> get _emojis => EmojiTheme.active.emojiList;

  late final AnimationController _floatController;
  late final AnimationController _logoEmojiController;
  late final Animation<double> _logoEmojiAnimation;
  final List<_FloatingEmoji> _floatingEmojis = [];
  final Random _rng = Random();
  MusicManager? _musicManager;

  int _logoEmojiIndex = 0;

  @override
  void initState() {
    super.initState();

    // Floating emoji background animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _floatController.addListener(() {
      _updateFloatingEmojis();
      if (mounted) setState(() {});
    });

    // Logo emoji bounce animation
    _logoEmojiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _logoEmojiAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -12.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -12.0, end: 0.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: 50,
      ),
    ]).animate(_logoEmojiController);

    // Cycle logo emoji
    _logoEmojiController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _logoEmojiIndex = (_logoEmojiIndex + 1) % _emojis.length;
        });
      }
    });

    // Generate initial floating emojis
    _generateFloatingEmojis();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start background music when the main menu is shown.
    _musicManager ??= MusicManagerProvider.read(context);
    _musicManager?.play();
  }


  void _generateFloatingEmojis() {
    for (int i = 0; i < 15; i++) {
      _floatingEmojis.add(_FloatingEmoji(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 20.0 + _rng.nextDouble() * 20.0,
        speed: 0.0002 + _rng.nextDouble() * 0.0005,
        angle: _rng.nextDouble() * 2 * pi,
        emoji: _emojis[_rng.nextInt(_emojis.length)],
        opacity: 0.15 + _rng.nextDouble() * 0.25,
      ));
    }
  }

  void _updateFloatingEmojis() {
    for (final e in _floatingEmojis) {
      e.x += cos(e.angle) * e.speed;
      e.y += sin(e.angle) * e.speed;

      // Wrap around edges
      if (e.x < -0.1) e.x = 1.1;
      if (e.x > 1.1) e.x = -0.1;
      if (e.y < -0.1) e.y = 1.1;
      if (e.y > 1.1) e.y = -0.1;

      // Slight angle drift
      e.angle += (_rng.nextDouble() - 0.5) * 0.02;
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _logoEmojiController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Stack(
        children: [
          // Floating emojis background
          ..._floatingEmojis.map((e) => Positioned(
                left: e.x * size.width,
                top: e.y * size.height,
                child: Opacity(
                  opacity: e.opacity,
                  child: EmojiText(
                    e.emoji,
                    fontSize: e.size,
                  ),
                ),
              )),

          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  _buildLogo(),
                  const Spacer(flex: 1),
                  // Coin & moves display (updated key comment)
                  Builder(builder: (context) {
                    final gsm = GameStateManagerProvider.of(context);
                    final ss = gsm.saveState;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          key: const Key('main_menu_coins'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const EmojiText('🪙',
                                  fontSize: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${gsm.coins}',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          key: const Key('main_menu_moves'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions_walk,
                                  color: Colors.lightBlueAccent, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                '${ss.bonusMoves}/${ss.maxBonusMoves}',
                                style: const TextStyle(
                                  color: Colors.lightBlueAccent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),
                  _buildMenuButton(
                    key: const Key('play_button'),
                    icon: Icons.play_arrow_rounded,
                    label: 'Play',
                    color: const Color(0xFF4CAF50),
                    onTap: () => _navigateTo(const LevelSelectScreen()),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuButton(
                    key: const Key('shop_button'),
                    icon: Icons.store_rounded,
                    label: 'Shop',
                    color: const Color(0xFFFF9800),
                    onTap: () => _navigateTo(const ShopScreen()),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuButton(
                    key: const Key('settings_button'),
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    color: const Color(0xFF9E9E9E),
                    onTap: () => _navigateTo(const SettingsScreen()),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),

          // Debug buttons — top right (when debug mode enabled in settings)
          Builder(builder: (context) {
            final gsm = GameStateManagerProvider.of(context);
            if (!gsm.settings.debugMode) return const SizedBox.shrink();
            return Positioned(
              right: 12,
              top: 12,
              child: SafeArea(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDebugButton(
                        label: '+200 Coins',
                        onTap: () => setState(() => gsm.saveState.coins += 200),
                      ),
                      const SizedBox(height: 8),
                      _buildDebugButton(
                        label: '+20 Moves',
                        onTap: () => setState(() {
                          gsm.saveState.bonusMoves = (gsm.saveState.bonusMoves + 20)
                              .clamp(0, gsm.saveState.maxBonusMoves + 20);
                        }),
                      ),
                    ],
                  ),
              ),
            );
          }),

          // Daily Chest — bottom right
          Positioned(
            right: 20,
            bottom: 24,
            child: SafeArea(
              child: const DailyChestButton(),
            ),
          ),

          // Ko-fi support — bottom left
          Positioned(
            left: 20,
            bottom: 24,
            child: SafeArea(
              child: _buildKofiButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.redAccent,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildKofiButton() {
    return GestureDetector(
      onTap: () => _showKofiDialog(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF5E5B), Color(0xFFFF9966)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5E5B).withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Center(
              child: EmojiText('\u2615', fontSize: 30), // ☕
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Support',
            style: TextStyle(
              color: Color(0xFFFF9966),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showKofiDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2a1a4e), Color(0xFF1a1a2e)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFF5E5B).withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EmojiText('\u2615', fontSize: 48),
              const SizedBox(height: 16),
              const Text(
                'Mojiii 3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This game is free & open source.\n'
                'If you enjoy it, consider buying me a coffee!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  launchUrl(
                    Uri.parse('https://ko-fi.com/casparjones'),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5E5B), Color(0xFFFF9966)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5E5B).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EmojiText('\u2615', fontSize: 20),
                      SizedBox(width: 10),
                      Text(
                        'Buy me a Coffee',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Maybe later',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _logoEmojiAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _logoEmojiAnimation.value),
              child: EmojiText(
                EmojiTheme.active.id == 'theme_fruit'
                    ? '🍓'
                    : _emojis[_logoEmojiIndex],
                fontSize: 64,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              shadows: [
                Shadow(color: Color(0xFF9C27B0), blurRadius: 20),
                Shadow(color: Color(0xFF7C4DFF), blurRadius: 40),
              ],
            ),
            children: [
              const TextSpan(text: 'M'),
              TextSpan(
                text: '🍓',
                style: EmojiText.emojiStyle(fontSize: 44),
              ),
              const TextSpan(text: 'jiii 3'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required Key key,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
