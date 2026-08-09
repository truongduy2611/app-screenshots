import 'dart:math' as math;

import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/board/board_frame_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A frame is stored as an axis-aligned rect that is rotated about its centre
/// at paint time, so resizing it also moves the centre. Unless the origin is
/// derived from the opposite corner, dragging a handle on a rotated frame
/// swings the whole thing away from the cursor.
void main() {
  /// Where a rect's [corner] actually appears once rotated about its centre.
  Offset visualCorner(Offset position, Size size, double angle, Alignment c) {
    final centre = position + Offset(size.width / 2, size.height / 2);
    final local = Offset(c.x * size.width / 2, c.y * size.height / 2);
    return centre + BoardFrameWidget.rotateVector(local, angle);
  }

  const corners = [
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
  ];

  Alignment opposite(Alignment c) => Alignment(-c.x, -c.y);

  group('BoardFrameWidget.resizeFromCorner', () {
    test('unrotated: dragging the top-left pins the bottom-right', () {
      final result = BoardFrameWidget.resizeFromCorner(
        position: const Offset(100, 100),
        size: const Size(400, 800),
        angle: 0,
        corner: Alignment.topLeft,
        delta: const Offset(50, 30),
      )!;

      // Dragging the top-left inward shrinks the rect and moves its origin.
      expect(result.$2, const Size(350, 770));
      expect(result.$1, const Offset(150, 130));
      // Bottom-right is exactly where it was.
      expect(result.$1 + Offset(result.$2.width, result.$2.height),
          const Offset(500, 900));
    });

    test('unrotated: dragging the bottom-right leaves the origin alone', () {
      final result = BoardFrameWidget.resizeFromCorner(
        position: const Offset(100, 100),
        size: const Size(400, 800),
        angle: 0,
        corner: Alignment.bottomRight,
        delta: const Offset(60, 40),
      )!;

      expect(result.$1, const Offset(100, 100));
      expect(result.$2, const Size(460, 840));
    });

    test('rotated: the opposite corner stays put on screen', () {
      const position = Offset(300, 200);
      const size = Size(400, 800);

      for (final angle in [0.0, 0.25, -0.6, 1.2, math.pi / 2]) {
        for (final corner in corners) {
          for (final delta in [
            const Offset(40, 25),
            const Offset(-30, 15),
            const Offset(70, -20),
          ]) {
            final before = visualCorner(
              position,
              size,
              angle,
              opposite(corner),
            );

            final result = BoardFrameWidget.resizeFromCorner(
              position: position,
              size: size,
              angle: angle,
              corner: corner,
              delta: delta,
            )!;

            final after = visualCorner(
              result.$1,
              result.$2,
              angle,
              opposite(corner),
            );

            expect(
              (after - before).distance,
              lessThan(1e-9),
              reason: 'opposite corner drifted at angle $angle, '
                  'corner $corner, delta $delta',
            );
          }
        }
      }
    });

    test('rotated: the dragged corner follows the pointer in frame axes', () {
      const position = Offset(0, 0);
      const size = Size(400, 800);
      const angle = 0.5;
      const delta = Offset(50, 30);

      final before = visualCorner(position, size, angle, Alignment.bottomRight);
      final result = BoardFrameWidget.resizeFromCorner(
        position: position,
        size: size,
        angle: angle,
        corner: Alignment.bottomRight,
        delta: delta,
      )!;
      final after = visualCorner(
        result.$1,
        result.$2,
        angle,
        Alignment.bottomRight,
      );

      // The handle moves by the drag, expressed in the frame's own axes —
      // which is the direction the rotated handle was actually pulled.
      expect(
        (after - before - BoardFrameWidget.rotateVector(delta, angle)).distance,
        lessThan(1e-9),
      );
    });

    test('the chrome margin fully contains the corner rotate pads', () {
      // Flutter does not hit-test a child positioned outside its parent's
      // bounds — it paints, but takes no pointer. The rotate pads straddle
      // each corner, so the box must extend at least half a pad past the frame
      // or their outer halves become invisible-to-pointer dead zones.
      expect(
        BoardFrameWidget.chromeMargin,
        greaterThanOrEqualTo(BoardFrameWidget.rotateCornerSize / 2),
      );
      // Edge bands sit in the margin too, just outside their edge.
      expect(
        BoardFrameWidget.chromeMargin,
        greaterThanOrEqualTo(BoardFrameWidget.rotateBand),
      );
      // The corner handle must stay inside the pad it shares a centre with,
      // otherwise resize and rotate stop being distinguishable.
      expect(
        BoardFrameWidget.handleSize,
        lessThan(BoardFrameWidget.rotateCornerSize),
      );
    });

    test('each corner gets its own glyph, sweeping around that corner', () {
      // A single shared icon can only point one way. Every corner must get a
      // distinct arc, or three of them read as pointing into the frame.
      final starts = {
        for (final c in corners) c: BoardFrameWidget.rotateGlyphStartAngle(c),
      };
      final normalised = starts.values
          .map((a) => (a % (2 * math.pi)).toStringAsFixed(6))
          .toSet();
      expect(normalised, hasLength(4), reason: 'corners share a glyph angle');

      for (final corner in corners) {
        final start = starts[corner]!;
        // Sample the arc, including both endpoints.
        for (var t = 0.0; t <= 1.0; t += 0.05) {
          final angle = start + BoardFrameWidget.rotateGlyphSweep * t;
          final point = Offset(math.cos(angle), math.sin(angle));

          // The arc is drawn from the frame's corner, so staying on the
          // corner's side of both axes is what puts it outside the border
          // rather than over the artwork.
          expect(
            point.dx * corner.x,
            greaterThan(-1e-9),
            reason: 'glyph for $corner crosses inside on x at t=$t',
          );
          expect(
            point.dy * corner.y,
            greaterThan(-1e-9),
            reason: 'glyph for $corner crosses inside on y at t=$t',
          );
        }
      }
    });

    test('a drag that would go below the minimum is refused', () {
      final result = BoardFrameWidget.resizeFromCorner(
        position: Offset.zero,
        size: const Size(400, 800),
        angle: 0.3,
        corner: Alignment.bottomRight,
        // Far more shrink than the frame has width.
        delta: const Offset(-9999, 0),
      );

      expect(result, isNull);
    });
  });
}
