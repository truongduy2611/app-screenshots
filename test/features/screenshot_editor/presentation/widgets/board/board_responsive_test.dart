import 'package:app_screenshots/features/screenshot_editor/data/models/board_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/board_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/board/board_template_picker_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/board_controls.dart';
import 'package:app_screenshots/l10n/output/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Board UI has to survive small screens, not just the desktop layout it was
/// designed against. A RenderFlex overflow throws in debug, so pumping at real
/// device sizes catches what eyeballing the desktop build cannot.
void main() {
  /// Common logical sizes: small phone, standard phone, small tablet.
  const sizes = <String, Size>{
    'small phone (iPhone SE)': Size(320, 568),
    'phone (iPhone 13)': Size(390, 844),
    'large phone': Size(430, 932),
    'small tablet': Size(600, 960),
    'tablet': Size(768, 1024),
  };

  Future<void> pumpAt(
    WidgetTester tester,
    Size size,
    Widget child,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('BoardTemplatePickerDialog', () {
    for (final entry in sizes.entries) {
      testWidgets('lays out without overflow on ${entry.key}', (tester) async {
        await pumpAt(tester, entry.value, const BoardTemplatePickerDialog());

        // An overflowing RenderFlex records an exception rather than throwing
        // out of pump, so check explicitly.
        expect(
          tester.takeException(),
          isNull,
          reason: 'overflow at ${entry.value}',
        );
      });
    }

    testWidgets('every template card is reachable by scrolling', (
      tester,
    ) async {
      await pumpAt(tester, const Size(320, 568), const BoardTemplatePickerDialog());

      // The grid must scroll — 15 layouts never fit a phone screen at once.
      expect(find.byType(GridView), findsOneWidget);
      await tester.drag(find.byType(GridView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('BoardControls', () {
    // The controls panel is the board surface that actually lives on a phone,
    // inside the mobile bottom sheet — so it has to hold up at the narrowest
    // width the sheet can be.
    BoardCubit makeCubit({int zoneCount = 3}) => BoardCubit(
          displayType: 'APP_IPHONE_69',
          initialZoneCount: zoneCount,
        );

    for (final entry in sizes.entries) {
      testWidgets('lays out without overflow on ${entry.key}', (tester) async {
        final cubit = makeCubit();
        addTearDown(cubit.close);

        await pumpAt(
          tester,
          entry.value,
          Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const BoardControls(),
            ),
          ),
        );

        expect(
          tester.takeException(),
          isNull,
          reason: 'overflow at ${entry.value}',
        );
      });
    }

    testWidgets('the zone list scrolls rather than clipping at the limit', (
      tester,
    ) async {
      final cubit = makeCubit(zoneCount: BoardDesign.maxZones);
      addTearDown(cubit.close);

      await pumpAt(
        tester,
        const Size(320, 568),
        Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: const BoardControls(),
          ),
        ),
      );

      // Ten zones plus frames never fit a phone panel; the list has to carry
      // them rather than the column overflowing.
      await tester.drag(find.byType(ListView), const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the Play-limit warning fits a small phone', (tester) async {
      // The widest string in the panel, on the narrowest screen — it only
      // appears past 8 zones, so it is easy to never see while developing.
      final cubit = makeCubit(zoneCount: BoardDesign.maxZones);
      addTearDown(cubit.close);

      await pumpAt(
        tester,
        const Size(320, 568),
        Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: const BoardControls(),
          ),
        ),
      );

      expect(cubit.state.board.exceedsPlayLimit, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
