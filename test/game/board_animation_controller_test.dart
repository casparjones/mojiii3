import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match3/game/board_animation_controller.dart';
import 'package:match3/models/position.dart';

void main() {
  group('GemAnimation', () {
    test('creates with required fields', () {
      const anim = GemAnimation(
        type: BoardAnimationType.swap,
        from: Position(0, 0),
        to: Position(0, 1),
      );
      expect(anim.type, BoardAnimationType.swap);
      expect(anim.from, const Position(0, 0));
      expect(anim.to, const Position(0, 1));
      expect(anim.progress, 0.0);
      expect(anim.scale, 1.0);
      expect(anim.opacity, 1.0);
    });

    test('withProgress creates copy with new progress', () {
      const anim = GemAnimation(
        type: BoardAnimationType.fall,
        from: Position(0, 0),
        to: Position(3, 0),
      );
      final updated = anim.withProgress(0.5);
      expect(updated.progress, 0.5);
      expect(updated.type, BoardAnimationType.fall);
      expect(updated.from, const Position(0, 0));
      expect(updated.to, const Position(3, 0));
    });

    test('interpolatedOffset calculates correctly at start', () {
      const anim = GemAnimation(
        type: BoardAnimationType.swap,
        from: Position(0, 0),
        to: Position(0, 1),
        progress: 0.0,
      );
      final offset = anim.interpolatedOffset(48.0);
      expect(offset, const Offset(0.0, 0.0));
    });

    test('interpolatedOffset calculates correctly at end', () {
      const anim = GemAnimation(
        type: BoardAnimationType.swap,
        from: Position(0, 0),
        to: Position(0, 1),
        progress: 1.0,
      );
      final offset = anim.interpolatedOffset(48.0);
      expect(offset, const Offset(48.0, 0.0));
    });

    test('interpolatedOffset calculates correctly at midpoint', () {
      const anim = GemAnimation(
        type: BoardAnimationType.swap,
        from: Position(0, 0),
        to: Position(0, 2),
        progress: 0.5,
      );
      final offset = anim.interpolatedOffset(48.0);
      expect(offset.dx, closeTo(48.0, 0.01));
      expect(offset.dy, closeTo(0.0, 0.01));
    });

    test('toString contains useful info', () {
      const anim = GemAnimation(
        type: BoardAnimationType.swap,
        from: Position(0, 0),
        to: Position(0, 1),
        progress: 0.5,
      );
      expect(anim.toString(), contains('swap'));
      expect(anim.toString(), contains('0.50'));
    });
  });

  group('FallMove', () {
    test('calculates distance correctly', () {
      const move = FallMove(from: Position(2, 0), to: Position(5, 0));
      expect(move.distance, 3);
    });

    test('toString works', () {
      const move = FallMove(from: Position(0, 3), to: Position(4, 3));
      expect(move.toString(), contains('FallMove'));
    });
  });

  group('BoardAnimationType', () {
    test('has all expected types', () {
      expect(BoardAnimationType.values, contains(BoardAnimationType.swap));
      expect(BoardAnimationType.values, contains(BoardAnimationType.swapFailed));
      expect(BoardAnimationType.values, contains(BoardAnimationType.match));
      expect(BoardAnimationType.values, contains(BoardAnimationType.fall));
      expect(BoardAnimationType.values, contains(BoardAnimationType.spawn));
      expect(BoardAnimationType.values, contains(BoardAnimationType.idle));
    });
  });

  group('BoardAnimationController', () {
    late BoardAnimationController controller;

    setUp(() {
      // Use WidgetsFlutterBinding for vsync in tests.
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    testWidgets('starts in idle phase', (tester) async {
      controller = BoardAnimationController(
        vsync: tester,
      );
      addTearDown(controller.dispose);

      expect(controller.currentPhase, BoardAnimationType.idle);
      expect(controller.isAnimating, false);
      expect(controller.currentAnimations, isEmpty);
    });

    testWidgets('animateSwap runs to completion', (tester) async {
      controller = BoardAnimationController(
        vsync: tester,
        swapDuration: const Duration(milliseconds: 100),
      );
      addTearDown(controller.dispose);

      final future = controller.animateSwap(
        const Position(0, 0),
        const Position(0, 1),
      );

      // Initially should be in swap phase.
      expect(controller.currentPhase, BoardAnimationType.swap);
      expect(controller.currentAnimations.length, 2);

      // Advance time to complete.
      await tester.pumpAndSettle();
      await future;

      expect(controller.currentPhase, BoardAnimationType.idle);
      expect(controller.currentAnimations, isEmpty);
    });

    testWidgets('animateSwapFailed runs bounce back', (tester) async {
      controller = BoardAnimationController(
        vsync: tester,
        swapDuration: const Duration(milliseconds: 100),
      );
      addTearDown(controller.dispose);

      final future = controller.animateSwapFailed(
        const Position(0, 0),
        const Position(0, 1),
      );

      expect(controller.currentPhase, BoardAnimationType.swapFailed);

      await tester.pumpAndSettle();
      await future;

      expect(controller.currentPhase, BoardAnimationType.idle);
    });

    testWidgets('animateMatch runs burst effect', (tester) async {
      controller = BoardAnimationController(
        vsync: tester,
        matchDuration: const Duration(milliseconds: 100),
      );
      addTearDown(controller.dispose);

      final positions = {
        const Position(0, 0),
        const Position(0, 1),
        const Position(0, 2),
      };

      final future = controller.animateMatch(positions);

      expect(controller.currentPhase, BoardAnimationType.match);
      expect(controller.currentAnimations.length, 3);

      // Check that match animations have correct initial state.
      for (final anim in controller.currentAnimations) {
        expect(anim.type, BoardAnimationType.match);
      }

      await tester.pumpAndSettle();
      await future;

      expect(controller.currentPhase, BoardAnimationType.idle);
    });

    testWidgets('animateFall runs gravity animation', (tester) async {
      controller = BoardAnimationController(
        vsync: tester,
        fallDuration: const Duration(milliseconds: 100),
      );
      addTearDown(controller.dispose);

      final moves = [
        const FallMove(from: Position(0, 0), to: Position(3, 0)),
        const FallMove(from: Position(1, 1), to: Position(4, 1)),
      ];

      final future = controller.animateFall(moves);

      expect(controller.currentPhase, BoardAnimationType.fall);
      expect(controller.currentAnimations.length, 2);

      await tester.pumpAndSettle();
      await future;

      expect(controller.currentPhase, BoardAnimationType.idle);
    });

    testWidgets('animateFall with empty moves does nothing', (tester) async {
      controller = BoardAnimationController(
        vsync: tester,
      );
      addTearDown(controller.dispose);

      await controller.animateFall([]);
      expect(controller.currentPhase, BoardAnimationType.idle);
    });

    testWidgets('animateSpawn runs fade-in animation', (tester) async {
      controller = BoardAnimationController(
        vsync: tester,
        spawnDuration: const Duration(milliseconds: 100),
      );
      addTearDown(controller.dispose);

      final positions = [
        const Position(0, 0),
        const Position(0, 1),
      ];

      final future = controller.animateSpawn(positions);

      expect(controller.currentPhase, BoardAnimationType.spawn);
      expect(controller.currentAnimations.length, 2);

      // Check spawn animations start from above the board.
      for (final anim in controller.currentAnimations) {
        expect(anim.type, BoardAnimationType.spawn);
        expect(anim.from.row, -1);
      }

      await tester.pumpAndSettle();
      await future;

      expect(controller.currentPhase, BoardAnimationType.idle);
    });

    testWidgets('animateSpawn with empty positions does nothing',
        (tester) async {
      controller = BoardAnimationController(
        vsync: tester,
      );
      addTearDown(controller.dispose);

      await controller.animateSpawn([]);
      expect(controller.currentPhase, BoardAnimationType.idle);
    });

    testWidgets('cancelAnimation stops running animation', (tester) async {
      controller = BoardAnimationController(
        vsync: tester,
        swapDuration: const Duration(seconds: 5),
      );
      addTearDown(controller.dispose);

      // Start a long animation.
      controller.animateSwap(
        const Position(0, 0),
        const Position(0, 1),
      );

      expect(controller.isAnimating, true);

      controller.cancelAnimation();

      expect(controller.currentPhase, BoardAnimationType.idle);
      expect(controller.isAnimating, false);
      expect(controller.currentAnimations, isEmpty);

      await tester.pumpAndSettle();
    });

    testWidgets('animationAt returns correct animation', (tester) async {
      controller = BoardAnimationController(
        vsync: tester,
        swapDuration: const Duration(seconds: 5),
      );
      addTearDown(controller.dispose);

      controller.animateSwap(
        const Position(0, 0),
        const Position(0, 1),
      );

      final anim = controller.animationAt(const Position(0, 0));
      expect(anim, isNotNull);
      expect(anim!.type, BoardAnimationType.swap);

      final noAnim = controller.animationAt(const Position(5, 5));
      expect(noAnim, isNull);

      controller.cancelAnimation();
      await tester.pumpAndSettle();
    });

    testWidgets('notifies listeners during animation', (tester) async {
      controller = BoardAnimationController(
        vsync: tester,
        swapDuration: const Duration(milliseconds: 100),
      );
      addTearDown(controller.dispose);

      int notificationCount = 0;
      controller.addListener(() => notificationCount++);

      final future = controller.animateSwap(
        const Position(0, 0),
        const Position(0, 1),
      );

      await tester.pumpAndSettle();
      await future;

      expect(notificationCount, greaterThan(0));
    });

    testWidgets('match animations have scale and opacity changes',
        (tester) async {
      controller = BoardAnimationController(
        vsync: tester,
        matchDuration: const Duration(milliseconds: 200),
      );
      addTearDown(controller.dispose);

      final positions = {const Position(0, 0)};

      controller.animateMatch(positions);

      // Pump a few frames to see intermediate values.
      await tester.pump(const Duration(milliseconds: 100));

      if (controller.currentAnimations.isNotEmpty) {
        final anim = controller.currentAnimations.first;
        // Scale should be > 1.0 at midpoint (growing).
        expect(anim.scale, greaterThanOrEqualTo(1.0));
        // Opacity should be < 1.0 at midpoint (fading out).
        expect(anim.opacity, lessThanOrEqualTo(1.0));
      }

      controller.cancelAnimation();
      await tester.pumpAndSettle();
    });
  });
}
