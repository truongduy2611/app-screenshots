import 'package:app_screenshots/features/screenshot_editor/data/models/board_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/board_template.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/board_templates.dart';
import 'package:flutter_test/flutter_test.dart';

/// The template catalogue is hand-authored data with no compiler checking it.
/// A duplicated id, an empty pattern, or a frame sized past its zone all look
/// fine until someone applies the layout.
void main() {
  group('BoardTemplates catalogue', () {
    test('ids are unique and resolvable', () {
      final ids = BoardTemplates.all.map((t) => t.id).toList();
      expect(ids.toSet(), hasLength(ids.length), reason: 'duplicate id');

      for (final template in BoardTemplates.all) {
        expect(
          BoardTemplates.byId(template.id),
          same(template),
          reason: '${template.id} is not resolvable by id',
        );
      }
      expect(BoardTemplates.byId('nope'), isNull);
    });

    test('names and descriptions are present', () {
      for (final t in BoardTemplates.all) {
        expect(t.name.trim(), isNotEmpty, reason: '${t.id} has no name');
        expect(
          t.description.trim(),
          isNotEmpty,
          reason: '${t.id} has no description',
        );
        expect(t.thumbnailColors, isNotEmpty, reason: '${t.id} has no colours');
      }
    });

    test('every template has a usable frame pattern', () {
      for (final t in BoardTemplates.all) {
        expect(
          t.framePattern,
          isNotEmpty,
          reason: '${t.id} would place no frames',
        );
        for (final p in t.framePattern) {
          // A frame wider than its zone is deliberate for bleed layouts, but
          // past this it stops reading as a device in a screenshot.
          expect(
            p.widthFactor,
            inInclusiveRange(0.2, 1.2),
            reason: '${t.id} widthFactor out of range',
          );
          // Beyond a quarter turn a phone reads as broken, not styled.
          expect(
            p.rotation.abs(),
            lessThanOrEqualTo(45),
            reason: '${t.id} rotation is extreme',
          );
          // The centre may drift outside the zone so a frame straddles a seam,
          // but not so far that it lands in a different zone entirely.
          expect(p.centerX, inInclusiveRange(-0.5, 1.5), reason: t.id);
          expect(p.centerY, inInclusiveRange(-0.5, 1.5), reason: t.id);
        }
      }
    });

    test('spacing is non-negative and within the editor slider range', () {
      for (final t in BoardTemplates.all) {
        expect(t.zoneGap, greaterThanOrEqualTo(0), reason: t.id);
        expect(t.zoneGap, lessThanOrEqualTo(600), reason: '${t.id} off-slider');
      }
    });

    test('placementFor cycles the pattern across any zone count', () {
      for (final t in BoardTemplates.all) {
        final n = t.framePattern.length;
        expect(t.placementFor(0), t.framePattern.first);
        // Past the end it wraps, so a short pattern still fills a full board.
        expect(t.placementFor(n), t.framePattern.first);
        expect(t.placementFor(BoardDesign.maxZones - 1), isNotNull);
      }
    });

    test('offers both light and dark backgrounds', () {
      // Listings split roughly evenly between light and dark; a catalogue of
      // only one is only half useful.
      final luminances = BoardTemplates.all
          .map((t) => t.background.backgroundColor.computeLuminance())
          .toList();
      expect(
        luminances.where((l) => l < 0.2),
        isNotEmpty,
        reason: 'no dark templates',
      );
      expect(
        luminances.where((l) => l > 0.6),
        isNotEmpty,
        reason: 'no light templates',
      );
    });

    test('offers at least one seamless panorama layout', () {
      // Zero spacing is the layout a board can express and separate artboards
      // cannot, so the catalogue should show it off.
      expect(
        BoardTemplates.all.where((t) => t.zoneGap == 0),
        isNotEmpty,
        reason: 'no zero-gap template',
      );
    });

    test('offers rotated frames, not just upright ones', () {
      final rotated = BoardTemplates.all.where(
        (t) => t.framePattern.any((p) => p.rotation != 0),
      );
      expect(rotated, hasLength(greaterThan(BoardTemplates.all.length ~/ 2)));
    });

    test('a template with one placement leans every frame the same way', () {
      // Sanity on the cycling contract: a single-entry pattern must not
      // accidentally alternate.
      final uniform = BoardTemplates.all.firstWhere(
        (t) => t.framePattern.length == 1,
      );
      final rotations = List.generate(
        5,
        (i) => uniform.placementFor(i).rotation,
      ).toSet();
      expect(rotations, hasLength(1));
    });
  });

  group('FramePlacement', () {
    test('defaults place a frame inside its zone', () {
      const p = FramePlacement();
      expect(p.rotation, 0);
      expect(p.centerX, inInclusiveRange(0, 1));
      expect(p.centerY, inInclusiveRange(0, 1));
      expect(p.widthFactor, lessThan(1));
    });

    test('aspect derives a portrait frame', () {
      expect(FramePlacement.aspect, greaterThan(1));
    });
  });
}
