import 'dart:math' as math;

import 'package:app_screenshots/features/screenshot_editor/data/models/board_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/board_templates.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/board_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  BoardCubit makeCubit({SavedDesign? saved, int zoneCount = 3}) {
    return BoardCubit(
      displayType: 'APP_IPHONE_69',
      initialSavedDesign: saved,
      initialZoneCount: zoneCount,
    );
  }

  group('BoardCubit initialisation', () {
    test('a new board starts from the starter layout', () {
      final cubit = makeCubit();

      expect(cubit.state.board.cropZones, hasLength(3));
      expect(cubit.state.board.frames, hasLength(3));
      expect(cubit.state.showCropZones, isTrue);
      expect(cubit.state.canUndo, isFalse);
      expect(cubit.state.exportCount, 3);

      cubit.close();
    });

    test('an existing board design is adopted as-is', () {
      final board = BoardDesign.starter(
        displayType: 'APP_IPHONE_67',
        zoneCount: 1,
      );
      final cubit = makeCubit(
        saved: SavedDesign(
          id: 'saved-1',
          name: 'My board',
          lastModified: DateTime(2026, 1, 1),
          thumbnailPath: '',
          design: board.background,
          board: board,
        ),
      );

      expect(cubit.state.board.cropZones, hasLength(1));
      expect(cubit.state.savedDesignId, 'saved-1');
      expect(cubit.state.savedDesignName, 'My board');

      cubit.close();
    });
  });

  group('BoardCubit frames', () {
    test('addFrame selects the new frame and stacks it on top', () {
      final cubit = makeCubit(zoneCount: 1);
      final topBefore = cubit.state.board.frames
          .map((f) => f.zIndex)
          .reduce((a, b) => a > b ? a : b);

      cubit.addFrame(nearZone: cubit.state.board.cropZones.first);

      final added = cubit.state.board.frames.last;
      expect(cubit.state.selectedFrameId, added.id);
      expect(added.zIndex, greaterThan(topBefore));
      expect(cubit.state.selectedZoneId, isNull);

      cubit.close();
    });

    test('moveFrame offsets the frame position', () {
      final cubit = makeCubit(zoneCount: 1);
      final frame = cubit.state.board.frames.first;
      final start = frame.position;

      cubit.moveFrame(frame.id, const Offset(25, -10));

      expect(
        cubit.state.board.frameById(frame.id)!.position,
        start + const Offset(25, -10),
      );

      cubit.close();
    });

    test('removeFrame clears the selection when it was selected', () {
      final cubit = makeCubit(zoneCount: 1);
      final frame = cubit.state.board.frames.first;
      cubit.selectFrame(frame.id);

      cubit.removeFrame(frame.id);

      expect(cubit.state.board.frameById(frame.id), isNull);
      expect(cubit.state.selectedFrameId, isNull);

      cubit.close();
    });

    test('duplicateFrame offsets the copy and gives it a new id', () {
      final cubit = makeCubit(zoneCount: 1);
      final source = cubit.state.board.frames.first;

      cubit.duplicateFrame(source.id);
      final copy = cubit.state.board.frames.last;

      expect(copy.id, isNot(source.id));
      expect(copy.position, source.position + const Offset(60, 60));
      expect(cubit.state.selectedFrameId, copy.id);

      cubit.close();
    });
  });

  group('BoardCubit crop zones', () {
    test('addZone places the new zone to the right of the last one', () {
      final cubit = makeCubit(zoneCount: 1);
      final first = cubit.state.board.cropZones.first;

      cubit.addZone();
      final added = cubit.state.board.cropZones.last;

      expect(cubit.state.board.cropZones, hasLength(2));
      expect(added.position.dx, greaterThan(first.rect.right));
      expect(cubit.state.selectedZoneId, added.id);

      cubit.close();
    });

    test('adding a zone grows the board so the zone fits', () {
      final cubit = makeCubit(zoneCount: 1);
      cubit.addZone();

      expect(
        cubit.state.board.size.width,
        greaterThanOrEqualTo(cubit.state.board.cropZones.last.rect.right),
      );

      cubit.close();
    });

    test('the last zone cannot be removed', () {
      final cubit = makeCubit(zoneCount: 1);

      cubit.removeZone(cubit.state.board.cropZones.first.id);

      expect(cubit.state.board.cropZones, hasLength(1));

      cubit.close();
    });

    test('excluding a zone drops it from the export count', () {
      final cubit = makeCubit(zoneCount: 3);
      final zone = cubit.state.board.cropZones[1];

      cubit.setZoneIncluded(zone.id, false);

      expect(cubit.state.exportCount, 2);
      expect(cubit.state.board.cropZones, hasLength(3));

      cubit.close();
    });

    test('toggling zone visibility never touches the board itself', () {
      final cubit = makeCubit();
      final board = cubit.state.board;

      cubit.toggleCropZones();

      expect(cubit.state.showCropZones, isFalse);
      // Same instance — visibility is editor chrome, not design data.
      expect(identical(cubit.state.board, board), isTrue);
      expect(cubit.state.canUndo, isFalse);

      cubit.close();
    });

    test('autoArrangeZones re-lays zones in a row and fits the board', () {
      final cubit = makeCubit(zoneCount: 3);
      final scattered = cubit.state.board.cropZones
          .map((z) => z.copyWith(position: const Offset(4000, 4000)))
          .toList();
      cubit.updateZone(scattered.first);

      cubit.autoArrangeZones();

      final zones = cubit.state.board.cropZones;
      for (var i = 1; i < zones.length; i++) {
        expect(zones[i].position.dx, greaterThan(zones[i - 1].rect.right));
        expect(zones[i].position.dy, zones[i - 1].position.dy);
      }
      expect(
        cubit.state.board.size.width,
        greaterThanOrEqualTo(zones.last.rect.right),
      );

      cubit.close();
    });

    test('autoArrangeZones carries each zone\'s frame along with it', () {
      final cubit = makeCubit(zoneCount: 3);

      // The starter layout puts each frame inside its own zone. Arranging with
      // a wider gap than the starter's shifts every zone but the first, so a
      // frame left behind is measurable.
      final before = {
        for (final zone in cubit.state.board.cropZones)
          zone.id: (
            zone: zone,
            frame: cubit.state.board.frames.firstWhere(
              (f) => zone.rect.contains(f.center),
            ),
          ),
      };

      cubit.autoArrangeZones(gap: BoardDesign.defaultZoneGap + 400);

      var movedZones = 0;
      for (final entry in before.entries) {
        final zoneAfter = cubit.state.board.zoneById(entry.key)!;
        final frameAfter =
            cubit.state.board.frameById(entry.value.frame.id)!;
        if (zoneAfter.position != entry.value.zone.position) movedZones++;

        // Each frame keeps its offset within its zone instead of being left
        // at the old coordinates.
        expect(
          frameAfter.position - zoneAfter.position,
          entry.value.frame.position - entry.value.zone.position,
          reason: 'frame did not travel with zone ${entry.key}',
        );
        expect(zoneAfter.rect.contains(frameAfter.center), isTrue);
      }
      expect(movedZones, greaterThan(0), reason: 'no zone actually moved');

      cubit.close();
    });

    test('arranging never leaves content outside the canvas', () {
      final cubit = makeCubit(zoneCount: 3);
      cubit.autoArrangeZones();

      final board = cubit.state.board;
      for (final zone in board.cropZones) {
        expect(zone.rect.right, lessThanOrEqualTo(board.size.width));
        expect(zone.rect.bottom, lessThanOrEqualTo(board.size.height));
      }
      for (final frame in board.frames) {
        expect(frame.rect.right, lessThanOrEqualTo(board.size.width));
        expect(frame.rect.bottom, lessThanOrEqualTo(board.size.height));
      }

      cubit.close();
    });

    test('zones stop at the App Store limit', () {
      final cubit = makeCubit(zoneCount: 3);

      // Well past the cap — every call beyond it must be a no-op.
      for (var i = 0; i < 20; i++) {
        cubit.addZone();
      }

      expect(cubit.state.board.cropZones, hasLength(BoardDesign.maxZones));
      expect(cubit.state.board.canAddZone, isFalse);

      cubit.close();
    });

    test('duplicating a zone also respects the limit', () {
      final cubit = makeCubit(zoneCount: BoardDesign.maxZones);
      final id = cubit.state.board.cropZones.first.id;

      cubit.duplicateZone(id);

      expect(cubit.state.board.cropZones, hasLength(BoardDesign.maxZones));

      cubit.close();
    });

    test('a starter board cannot open over the limit', () {
      final cubit = makeCubit(zoneCount: 50);

      expect(cubit.state.board.cropZones, hasLength(BoardDesign.maxZones));

      cubit.close();
    });

    test('the Play limit is a warning, not a cap', () {
      final cubit = makeCubit(zoneCount: BoardDesign.maxPlayZones);
      expect(cubit.state.board.exceedsPlayLimit, isFalse);

      cubit.addZone();

      // Apple accepts more than Play, so the extra zone is allowed and only
      // flagged — an iOS-only board should not be held to Play's limit.
      expect(
        cubit.state.board.cropZones,
        hasLength(BoardDesign.maxPlayZones + 1),
      );
      expect(cubit.state.board.exceedsPlayLimit, isTrue);

      cubit.close();
    });

    test('excluded zones do not count toward the Play limit', () {
      final cubit = makeCubit(zoneCount: BoardDesign.maxPlayZones + 2);
      expect(cubit.state.board.exceedsPlayLimit, isTrue);

      // Only zones marked for export are uploaded.
      for (final zone in cubit.state.board.cropZones.take(2)) {
        cubit.setZoneIncluded(zone.id, false);
      }

      expect(cubit.state.board.exceedsPlayLimit, isFalse);

      cubit.close();
    });

    test('the store limits match what each store accepts', () {
      expect(BoardDesign.maxZones, 10, reason: 'App Store Connect limit');
      expect(BoardDesign.maxPlayZones, 8, reason: 'Google Play limit');
      expect(
        BoardDesign.maxPlayZones,
        lessThan(BoardDesign.maxZones),
        reason: 'the warning path only makes sense if Play is stricter',
      );
    });

    test('zero spacing butts the zones together with no seam', () {
      final cubit = makeCubit(zoneCount: 3);

      cubit.setZoneGap(0);

      final zones = cubit.state.board.cropZones;
      expect(cubit.state.board.zoneGap, 0);
      for (var i = 1; i < zones.length; i++) {
        // Exactly adjacent: any gap here would break a background meant to
        // span the screenshots as one continuous image.
        expect(zones[i].position.dx, zones[i - 1].rect.right);
      }

      cubit.close();
    });

    test('spacing round-trips through JSON', () {
      final cubit = makeCubit(zoneCount: 2);
      cubit.setZoneGap(0);

      final restored = BoardDesign.fromJson(cubit.state.board.toJson());
      expect(restored.zoneGap, 0);

      // A file written before spacing existed keeps the original layout.
      final legacy = Map<String, dynamic>.from(cubit.state.board.toJson())
        ..remove('zoneGap');
      expect(BoardDesign.fromJson(legacy).zoneGap, BoardDesign.defaultZoneGap);

      cubit.close();
    });

    test('the board has no trailing gap on the right at any spacing', () {
      for (final gap in [0.0, 120.0, 400.0]) {
        final cubit = makeCubit(zoneCount: 3);
        cubit.setZoneGap(gap);

        final board = cubit.state.board;
        final left = board.cropZones.first.position.dx;
        final right = board.size.width - board.cropZones.last.rect.right;
        expect(right, closeTo(left, 0.01), reason: 'margins differ at gap $gap');

        cubit.close();
      }
    });

    test('positions are pinned at the origin, never negative', () {
      final cubit = makeCubit(zoneCount: 1);

      cubit.moveFrame(cubit.state.board.frames.first.id, const Offset(-9e3, -9e3));
      cubit.moveZone(cubit.state.board.cropZones.first.id, const Offset(-9e3, -9e3));

      // Negative coordinates are outside every crop zone, so content there
      // would silently vanish from exports.
      expect(cubit.state.board.frames.first.position, Offset.zero);
      expect(cubit.state.board.cropZones.first.position, Offset.zero);

      cubit.close();
    });
  });

  group('BoardCubit history', () {
    test('undo and redo step through board edits', () {
      final cubit = makeCubit(zoneCount: 1);
      final frame = cubit.state.board.frames.first;
      final start = frame.position;

      cubit.moveFrame(frame.id, const Offset(100, 0));
      expect(cubit.state.canUndo, isTrue);

      cubit.undo();
      expect(cubit.state.board.frameById(frame.id)!.position, start);
      expect(cubit.state.canRedo, isTrue);

      cubit.redo();
      expect(
        cubit.state.board.frameById(frame.id)!.position,
        start + const Offset(100, 0),
      );

      cubit.close();
    });

    test('redo drops a selection the restored board no longer contains', () {
      final cubit = makeCubit(zoneCount: 1);
      final frame = cubit.state.board.frames.first;

      cubit.selectFrame(frame.id);
      cubit.removeFrame(frame.id);
      cubit.undo();
      expect(cubit.state.board.frameById(frame.id), isNotNull);

      // Redoing the delete must not leave the selection pointing at a frame
      // that is gone again.
      cubit.selectFrame(frame.id);
      cubit.redo();

      expect(cubit.state.board.frameById(frame.id), isNull);
      expect(cubit.state.selectedFrameId, isNull);
      expect(cubit.state.selectionKind, BoardSelectionKind.none);

      cubit.close();
    });

    test('an ended batch edit resumes recording history', () {
      final cubit = makeCubit(zoneCount: 1);
      final frame = cubit.state.board.frames.first;

      // A slider gesture: begin, several updates, end.
      cubit.beginBatchEdit();
      cubit.updateFrame(frame.copyWith(rotation: 0.1));
      cubit.updateFrame(frame.copyWith(rotation: 0.2));
      cubit.endBatchEdit();

      // A leaked batch flag used to disable undo recording for good, so the
      // next edit must still be individually undoable.
      final afterGesture = cubit.state.board.frameById(frame.id)!.rotation;
      cubit.moveFrame(frame.id, const Offset(50, 0));
      cubit.undo();

      expect(cubit.state.board.frameById(frame.id)!.rotation, afterGesture);
      expect(cubit.state.canUndo, isTrue);

      cubit.close();
    });

    test('a batched drag collapses into a single undo entry', () {
      final cubit = makeCubit(zoneCount: 1);
      final frame = cubit.state.board.frames.first;
      final start = frame.position;

      cubit.beginBatchEdit();
      cubit.moveFrame(frame.id, const Offset(10, 0));
      cubit.moveFrame(frame.id, const Offset(10, 0));
      cubit.moveFrame(frame.id, const Offset(10, 0));
      cubit.endBatchEdit();

      cubit.undo();

      expect(cubit.state.board.frameById(frame.id)!.position, start);
      expect(cubit.state.canUndo, isFalse);

      cubit.close();
    });

    test('editSeq advances on every board mutation', () {
      final cubit = makeCubit(zoneCount: 1);
      final before = cubit.state.editSeq;

      cubit.addZone();

      expect(cubit.state.editSeq, greaterThan(before));

      cubit.close();
    });
  });

  group('BoardCubit background sync', () {
    test('syncBackground stores the editor design without a history entry', () {
      final cubit = makeCubit();
      const background = ScreenshotDesign(
        backgroundColor: Color(0xFF00FF00),
      );

      cubit.syncBackground(background);

      expect(cubit.state.board.background, background);
      expect(cubit.state.canUndo, isFalse);

      cubit.close();
    });

    test('toSavedDesign carries the board and its background', () {
      final cubit = makeCubit(zoneCount: 2);
      const background = ScreenshotDesign(
        backgroundColor: Color(0xFF00FF00),
      );
      cubit.syncBackground(background);

      final saved = cubit.toSavedDesign(name: 'Board A');

      expect(saved.isBoard, isTrue);
      expect(saved.board!.cropZones, hasLength(2));
      expect(saved.design, background);
      expect(saved.name, 'Board A');

      cubit.close();
    });
  });

  group('BoardCubit board templates', () {
    test('applying a layout rotates frames and adopts its spacing', () {
      final cubit = makeCubit(zoneCount: 3);
      final template = BoardTemplates.alternatingLean;

      cubit.applyTemplate(template);

      final board = cubit.state.board;
      expect(board.zoneGap, template.zoneGap);
      expect(board.frames, hasLength(3));

      for (var i = 0; i < board.cropZones.length; i++) {
        final expected = template.placementFor(i).rotation * math.pi / 180;
        final frame = board.frames[i];
        expect(frame.rotation, closeTo(expected, 1e-9));
        // Each frame lands in the zone it belongs to.
        expect(board.cropZones[i].rect.contains(frame.center), isTrue);
      }
      // The pattern alternates, so neighbours must not share a rotation.
      expect(board.frames[0].rotation, isNot(board.frames[1].rotation));

      cubit.close();
    });

    test('applying a layout keeps imported screenshots', () {
      final cubit = makeCubit(zoneCount: 3);

      // Give every starter frame an image, as an import would.
      for (final frame in [...cubit.state.board.frames]) {
        cubit.updateFrame(frame.copyWith(imagePath: '/tmp/${frame.id}.png'));
      }
      final before = {
        for (final f in cubit.state.board.frames) f.id: f.imagePath,
      };

      cubit.applyTemplate(BoardTemplates.cascade);

      final after = {
        for (final f in cubit.state.board.frames) f.id: f.imagePath,
      };
      // Same frames, same images — a layout rearranges work, never erases it.
      expect(after.keys.toSet(), before.keys.toSet());
      expect(after, before);

      cubit.close();
    });

    test('the panorama layout leaves no seam between zones', () {
      final cubit = makeCubit(zoneCount: 3);

      cubit.applyTemplate(BoardTemplates.panoramaFlow);

      final zones = cubit.state.board.cropZones;
      expect(cubit.state.board.zoneGap, 0);
      for (var i = 1; i < zones.length; i++) {
        expect(zones[i].position.dx, zones[i - 1].rect.right);
      }

      cubit.close();
    });

    test('a layout fills empty zones rather than leaving them frameless', () {
      final cubit = makeCubit(zoneCount: 3);
      for (final frame in [...cubit.state.board.frames]) {
        cubit.removeFrame(frame.id);
      }
      expect(cubit.state.board.frames, isEmpty);

      cubit.applyTemplate(BoardTemplates.tiltedTrio);

      expect(cubit.state.board.frames, hasLength(3));

      cubit.close();
    });
  });
}
