import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/board/board_frame_widget.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/board/board_viewport_scale.dart';
import 'package:flutter_test/flutter_test.dart';

/// Board coordinates are screenshot-resolution, so the canvas sits at a very
/// low zoom by default and anything sized in board pixels shrinks with it.
/// Chrome divides by the zoom to hold a constant on-screen size; if that ever
/// regresses, handles quietly become untappable rather than visibly broken.
void main() {
  /// Zoom levels for a three-zone iPhone board (~4520 x 3188 board px) fitted
  /// into each viewport.
  const fitZoom = <String, double>{
    'phone': 0.079,
    'tablet': 0.156,
    'desktop': 0.251,
  };

  /// Minimum comfortable touch target, in logical pixels.
  const touchTarget = 44.0;

  group('BoardViewportScale.size', () {
    test('is the identity at 1:1', () {
      expect(BoardViewportScale.size(44, 1.0), 44);
    });

    test('grows as the canvas zooms out, so screen size holds', () {
      for (final zoom in fitZoom.values) {
        final board = BoardViewportScale.size(44, zoom);
        // board px * zoom = screen px, which is the whole point.
        expect(board * zoom, closeTo(44, 1e-9));
      }
    });

    test('shrinks when zoomed past 1:1', () {
      final board = BoardViewportScale.size(44, 2.0);
      expect(board, 22);
      expect(board * 2.0, 44);
    });

    test('clamps rather than exploding on a degenerate zoom', () {
      // A reciprocal of zero would produce an infinite handle and take the
      // layout down with it.
      for (final bad in [0.0, -1.0, double.nan]) {
        final result = BoardViewportScale.size(44, bad);
        expect(result.isFinite, isTrue, reason: 'zoom $bad');
        expect(result, greaterThan(0));
      }
      // Below the floor the divisor stops shrinking.
      expect(
        BoardViewportScale.size(44, 0.000001),
        BoardViewportScale.size(44, BoardViewportScale.minScale),
      );
    });
  });

  group('frame handles at fit zoom', () {
    test('resize handles clear the touch target on every device', () {
      // Before scaling these were 3.5px on a phone and 11px on desktop.
      for (final entry in fitZoom.entries) {
        final onScreen =
            BoardViewportScale.size(BoardFrameWidget.handleSize, entry.value) *
                entry.value;
        expect(
          onScreen,
          greaterThanOrEqualTo(touchTarget),
          reason: '${entry.key} resize handle is only ${onScreen}px',
        );
      }
    });

    test('the rotate ring and chrome margin scale with them', () {
      const zoom = 0.079; // phone
      double onScreen(double base) =>
          BoardViewportScale.size(base, zoom) * zoom;

      expect(onScreen(BoardFrameWidget.rotateCornerSize), closeTo(128, 1e-9));
      expect(onScreen(BoardFrameWidget.rotateBand), closeTo(40, 1e-9));
      expect(onScreen(BoardFrameWidget.chromeMargin), closeTo(96, 1e-9));
    });

    test('the margin still contains the corner pads once scaled', () {
      // The invariant that keeps the outer half of each pad hit-testable has
      // to survive scaling, not just hold at 1:1.
      for (final zoom in [...fitZoom.values, 1.0, 4.0]) {
        final margin =
            BoardViewportScale.size(BoardFrameWidget.chromeMargin, zoom);
        final pad =
            BoardViewportScale.size(BoardFrameWidget.rotateCornerSize, zoom);
        expect(margin, greaterThanOrEqualTo(pad / 2), reason: 'zoom $zoom');
      }
    });
  });
}
