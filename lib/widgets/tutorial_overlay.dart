import 'package:flutter/material.dart';

/// A single step in the tutorial.
class TutorialStep {
  /// The title text shown prominently.
  final String title;

  /// The description text with more detail.
  final String description;

  /// An emoji or icon to display.
  final String emoji;

  /// Relative position of the spotlight highlight (0.0 - 1.0).
  /// null means no specific spotlight (centered message).
  final Alignment? spotlightAlignment;

  const TutorialStep({
    required this.title,
    required this.description,
    required this.emoji,
    this.spotlightAlignment,
  });
}

/// The default tutorial steps for new players.
const List<TutorialStep> defaultTutorialSteps = [
  TutorialStep(
    title: 'Tap to select',
    description: 'Tippe auf ein Emoji um es auszuwählen',
    emoji: '\uD83D\uDC46', // 👆
    spotlightAlignment: Alignment.center,
  ),
  TutorialStep(
    title: 'Swap with neighbor',
    description: 'Tippe auf ein Nachbar-Emoji zum Tauschen',
    emoji: '\u2194\uFE0F', // ↔️
    spotlightAlignment: Alignment.centerRight,
  ),
  TutorialStep(
    title: '3 in a row = Match!',
    description: '3 gleiche = Match! Punkte!',
    emoji: '\u2B50', // ⭐
    spotlightAlignment: Alignment.centerLeft,
  ),
  TutorialStep(
    title: 'Have fun!',
    description: 'Viel Spass!',
    emoji: '\uD83C\uDF89', // 🎉
  ),
];

/// Overlay widget that shows a step-by-step tutorial for new players.
///
/// Shows a dark backdrop with a spotlight effect on the relevant area
/// and tutorial text. Tap anywhere to advance to the next step.
class TutorialOverlay extends StatefulWidget {
  /// The tutorial steps to display.
  final List<TutorialStep> steps;

  /// Called when the tutorial is complete (all steps dismissed).
  final VoidCallback? onComplete;

  const TutorialOverlay({
    super.key,
    this.steps = defaultTutorialSteps,
    this.onComplete,
  });

  @override
  State<TutorialOverlay> createState() => TutorialOverlayState();
}

@visibleForTesting
class TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// The current step index (for testing).
  @visibleForTesting
  int get currentStep => _currentStep;

  /// Whether the tutorial is complete.
  bool get isComplete => _currentStep >= widget.steps.length;

  /// Advance to the next step, or dismiss if on the last step.
  void _nextStep() {
    if (_currentStep >= widget.steps.length - 1) {
      // Last step - complete the tutorial.
      _animController.reverse().then((_) {
        widget.onComplete?.call();
      });
    } else {
      _animController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _currentStep++;
          });
          _animController.forward();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isComplete) return const SizedBox.shrink();

    final step = widget.steps[_currentStep];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        key: const Key('tutorial_overlay'),
        onTap: _nextStep,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black.withValues(alpha: 0.75),
          child: Stack(
            children: [
              // Spotlight effect
              if (step.spotlightAlignment != null)
                Align(
                  alignment: step.spotlightAlignment!,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.amberAccent.withValues(alpha: 0.8),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amberAccent.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),

              // Tutorial content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Emoji
                      Text(
                        step.emoji,
                        style: const TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        step.title,
                        key: const Key('tutorial_title'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Text(
                        step.description,
                        key: const Key('tutorial_description'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Step indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(widget.steps.length, (i) {
                          return Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _currentStep
                                  ? Colors.amberAccent
                                  : Colors.white24,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Tap to continue hint
                      Text(
                        _currentStep < widget.steps.length - 1
                            ? 'Tap to continue'
                            : 'Tap to start playing',
                        key: const Key('tutorial_tap_hint'),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
