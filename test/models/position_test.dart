import 'package:flutter_test/flutter_test.dart';
import 'package:match3/models/position.dart';

void main() {
  group('Position', () {
    test('equality works', () {
      const a = Position(2, 3);
      const b = Position(2, 3);
      const c = Position(3, 2);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      const a = Position(2, 3);
      const b = Position(2, 3);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('isAdjacentTo detects horizontal neighbors', () {
      const pos = Position(3, 3);
      expect(pos.isAdjacentTo(const Position(3, 4)), isTrue);
      expect(pos.isAdjacentTo(const Position(3, 2)), isTrue);
    });

    test('isAdjacentTo detects vertical neighbors', () {
      const pos = Position(3, 3);
      expect(pos.isAdjacentTo(const Position(4, 3)), isTrue);
      expect(pos.isAdjacentTo(const Position(2, 3)), isTrue);
    });

    test('isAdjacentTo rejects diagonal', () {
      const pos = Position(3, 3);
      expect(pos.isAdjacentTo(const Position(4, 4)), isFalse);
      expect(pos.isAdjacentTo(const Position(2, 2)), isFalse);
    });

    test('isAdjacentTo rejects same position', () {
      const pos = Position(3, 3);
      expect(pos.isAdjacentTo(const Position(3, 3)), isFalse);
    });

    test('isAdjacentTo rejects distant positions', () {
      const pos = Position(3, 3);
      expect(pos.isAdjacentTo(const Position(3, 5)), isFalse);
      expect(pos.isAdjacentTo(const Position(5, 3)), isFalse);
    });

    test('directional getters work', () {
      const pos = Position(3, 3);
      expect(pos.up, const Position(2, 3));
      expect(pos.down, const Position(4, 3));
      expect(pos.left, const Position(3, 2));
      expect(pos.right, const Position(3, 4));
    });

    test('toString works', () {
      const pos = Position(2, 5);
      expect(pos.toString(), 'Position(2, 5)');
    });
  });
}
