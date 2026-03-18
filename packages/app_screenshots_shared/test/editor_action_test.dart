import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'package:test/test.dart';

void main() {
  group('EditorAction', () {
    group('actionName', () {
      test('converts camelCase to kebab-case', () {
        expect(EditorAction.setBackground.actionName, 'set-background');
        expect(EditorAction.setGradient.actionName, 'set-gradient');
        expect(EditorAction.setMeshGradient.actionName, 'set-mesh-gradient');
        expect(EditorAction.setImagePosition.actionName, 'set-image-position');
        expect(EditorAction.setImageBase64.actionName, 'set-image-base64');
        expect(EditorAction.addText.actionName, 'add-text');
        expect(EditorAction.addMagnifier.actionName, 'add-magnifier');
        expect(EditorAction.bringForward.actionName, 'bring-forward');
        expect(EditorAction.sendBackward.actionName, 'send-backward');
      });

      test('simple names stay lowercase', () {
        expect(EditorAction.state.actionName, 'state');
        expect(EditorAction.undo.actionName, 'undo');
        expect(EditorAction.redo.actionName, 'redo');
      });

      test('strips trailing underscore from export_', () {
        expect(EditorAction.export_.actionName, 'export');
      });
    });

    group('path', () {
      test('has correct /api/editor/ prefix', () {
        expect(EditorAction.state.path, '/api/editor/state');
        expect(
          EditorAction.setBackground.path,
          '/api/editor/set-background',
        );
        expect(EditorAction.export_.path, '/api/editor/export');
      });
    });

    group('fromActionName', () {
      test('round-trips all enum values', () {
        for (final action in EditorAction.values) {
          final restored = EditorAction.fromActionName(action.actionName);
          expect(restored, action, reason: 'Failed for ${action.name}');
        }
      });

      test('returns null for unknown name', () {
        expect(EditorAction.fromActionName('nonexistent'), isNull);
        expect(EditorAction.fromActionName(''), isNull);
      });
    });
  });
}
