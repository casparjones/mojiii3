import 'package:flutter/material.dart';

import '../game/game_state_manager.dart';
import '../main.dart';

/// Settings screen with toggles, stats display, and reset option.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gsm = GameStateManagerProvider.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: gsm,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('Audio & Haptics'),
              const SizedBox(height: 8),
              _buildToggle(
                key: const Key('sound_toggle'),
                icon: Icons.volume_up,
                label: 'Sound',
                value: gsm.settings.soundEnabled,
                onChanged: (_) => gsm.toggleSound(),
              ),
              _buildToggle(
                key: const Key('music_toggle'),
                icon: Icons.music_note,
                label: 'Music',
                value: gsm.settings.musicEnabled,
                onChanged: (_) => gsm.toggleMusic(),
              ),
              _buildToggle(
                key: const Key('vibration_toggle'),
                icon: Icons.vibration,
                label: 'Vibration',
                value: gsm.settings.vibrationEnabled,
                onChanged: (_) => gsm.toggleVibration(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Statistics'),
              const SizedBox(height: 8),
              _buildStatRow('Levels Played', '${gsm.stats.levelsPlayed}'),
              _buildStatRow(
                  'Levels Completed', '${gsm.stats.levelsCompleted}'),
              _buildStatRow('Best Combo', '${gsm.stats.bestCombo}x'),
              _buildStatRow(
                  'Total Gems Matched', '${gsm.stats.totalGemsMatched}'),
              _buildStatRow(
                  'Total Coins Earned', '${gsm.stats.totalCoinsEarned}'),
              _buildStatRow('Best Move Score', '${gsm.stats.bestMoveScore}'),
              _buildStatRow('Play Time',
                  _formatPlayTime(gsm.stats.totalPlayTimeSeconds)),
              _buildStatRow(
                  '3-Star Completions', '${gsm.stats.threeStarCount}'),
              _buildStatRow('Total Stars', '${gsm.totalStars}'),
              _buildStatRow('Current Coins', '${gsm.coins}'),
              const SizedBox(height: 32),
              _buildSectionHeader('Credits'),
              const SizedBox(height: 8),
              _buildCreditRow(
                'Emoji Graphics',
                'Google Noto Color Emoji',
                'Apache License 2.0',
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Developer'),
              const SizedBox(height: 8),
              _buildToggle(
                key: const Key('debug_toggle'),
                icon: Icons.bug_report,
                label: 'Debug Mode',
                value: gsm.settings.debugMode,
                onChanged: (_) => gsm.toggleDebugMode(),
              ),
              if (gsm.settings.debugMode) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        label: '+200 Coins',
                        color: Colors.amber,
                        onTap: () => gsm.saveState.coins += 200,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        label: '+20 Moves',
                        color: Colors.lightBlue,
                        onTap: () {
                          gsm.saveState.bonusMoves =
                              (gsm.saveState.bonusMoves + 20)
                                  .clamp(0, gsm.saveState.maxBonusMoves + 20);
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              _buildSectionHeader('Danger Zone'),
              const SizedBox(height: 8),
              _buildResetButton(context, gsm),
            ],
          );
        },
      ),
    );
  }

  String _formatPlayTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildToggle({
    required Key key,
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Switch(
            key: key,
            value: value,
            onChanged: onChanged,
            activeColor: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditRow(String category, String name, String license) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            license,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _resetProgress(BuildContext context, GameStateManager gsm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'Reset Progress?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will erase all your progress, coins, and unlocked items. This action cannot be undone!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirm_reset'),
            onPressed: () {
              Navigator.pop(ctx);
              gsm.reset();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Progress reset!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, GameStateManager gsm) {
    return GestureDetector(
      key: const Key('reset_button'),
      onTap: () => _resetProgress(context, gsm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_forever, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text(
              'Reset All Progress',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
