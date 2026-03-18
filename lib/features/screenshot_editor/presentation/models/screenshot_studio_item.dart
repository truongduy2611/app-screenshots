import 'package:app_screenshots/features/screenshot_editor/data/models/design_folder.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';

class ScreenshotStudioItem {
  final DesignFolder? folder;
  final SavedDesign? design;
  final int depth;

  bool get isFolder => folder != null;

  ScreenshotStudioItem.folder(this.folder, {this.depth = 0}) : design = null;
  ScreenshotStudioItem.design(this.design, {this.depth = 0}) : folder = null;
}
