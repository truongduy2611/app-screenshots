import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'output/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('tr'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// App title shown in the app bar and share sheets
  ///
  /// In en, this message translates to:
  /// **'App Screenshots'**
  String get appTitle;

  /// Main section title on the home page
  ///
  /// In en, this message translates to:
  /// **'Screenshot Studio'**
  String get screenshotStudio;

  /// Subtitle shown on the empty state of the home page
  ///
  /// In en, this message translates to:
  /// **'Create beautiful App Store screenshots'**
  String get screenshotStudioSubtitle;

  /// Settings page/dialog title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Settings section header for theme options
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Settings section header for app info
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Theme mode label — follow device settings
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Theme mode label — always light
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme mode label — always dark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Subtitle for the System theme option
  ///
  /// In en, this message translates to:
  /// **'Follow device settings'**
  String get themeSystemSubtitle;

  /// Subtitle for the Light theme option
  ///
  /// In en, this message translates to:
  /// **'Always use light theme'**
  String get themeLightSubtitle;

  /// Subtitle for the Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Always use dark theme'**
  String get themeDarkSubtitle;

  /// Button label to create a new screenshot design
  ///
  /// In en, this message translates to:
  /// **'New Design'**
  String get newDesign;

  /// Generic save action label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Save as new copy action label
  ///
  /// In en, this message translates to:
  /// **'Save As'**
  String get saveAs;

  /// Export action label
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Share action label
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Delete action label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Rename action label
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Duplicate action label
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// Cancel action label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Undo the last action
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Redo the previously undone action
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// Confirm action label
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Done action label
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Label for 3D rotation on the X axis
  ///
  /// In en, this message translates to:
  /// **'Rotation X'**
  String get rotationX;

  /// Label for 3D rotation on the Y axis
  ///
  /// In en, this message translates to:
  /// **'Rotation Y'**
  String get rotationY;

  /// Label for 3D rotation on the Z axis
  ///
  /// In en, this message translates to:
  /// **'Rotation Z'**
  String get rotationZ;

  /// Edit action label
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Close action label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Label for the design name text field
  ///
  /// In en, this message translates to:
  /// **'Design Name'**
  String get designName;

  /// Hint text for the design name text field
  ///
  /// In en, this message translates to:
  /// **'Enter design name'**
  String get enterDesignName;

  /// Label for a folder
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folder;

  /// Button label for creating a new folder
  ///
  /// In en, this message translates to:
  /// **'New Folder'**
  String get newFolder;

  /// Label for the folder name text field
  ///
  /// In en, this message translates to:
  /// **'Folder Name'**
  String get folderName;

  /// Hint text for the folder name text field
  ///
  /// In en, this message translates to:
  /// **'Enter folder name'**
  String get enterFolderName;

  /// Action label for moving a design to a folder
  ///
  /// In en, this message translates to:
  /// **'Move to Folder'**
  String get moveToFolder;

  /// Option label for designs without a folder
  ///
  /// In en, this message translates to:
  /// **'No Folder'**
  String get noFolder;

  /// Empty state message for a folder
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get emptyFolder;

  /// Action label for deleting a folder
  ///
  /// In en, this message translates to:
  /// **'Delete Folder'**
  String get deleteFolder;

  /// Confirmation message when deleting a folder
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this folder? Designs will be moved to the root.'**
  String get deleteFolderConfirmation;

  /// Action to clone a design to a different device format
  ///
  /// In en, this message translates to:
  /// **'Clone to Device'**
  String get cloneToDevice;

  /// Action to save the current design as a reusable template
  ///
  /// In en, this message translates to:
  /// **'Save as Template'**
  String get saveAsTemplate;

  /// Action to reorder an item to the left
  ///
  /// In en, this message translates to:
  /// **'Move Left'**
  String get moveLeft;

  /// Action to reorder an item to the right
  ///
  /// In en, this message translates to:
  /// **'Move Right'**
  String get moveRight;

  /// Confirmation message when deleting selected items in bulk
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the selected items?'**
  String get deleteSelectedConfirmation;

  /// Header showing number of selected items
  ///
  /// In en, this message translates to:
  /// **'{count} Selected'**
  String selectedCount(int count);

  /// Snackbar message after exporting selected designs
  ///
  /// In en, this message translates to:
  /// **'Exported Designs'**
  String get exportedDesigns;

  /// Action to enter selection mode
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// Action to move items to a folder
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// Checkbox label to also delete all designs inside a folder
  ///
  /// In en, this message translates to:
  /// **'Also delete all designs inside'**
  String get alsoDeleteAllDesigns;

  /// Action label for renaming a folder
  ///
  /// In en, this message translates to:
  /// **'Rename Folder'**
  String get renameFolder;

  /// Action label for deleting a design
  ///
  /// In en, this message translates to:
  /// **'Delete Design'**
  String get deleteDesign;

  /// Confirmation message when deleting a design
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this design?'**
  String get deleteDesignConfirmation;

  /// Section label for background settings
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// Background type — single solid color
  ///
  /// In en, this message translates to:
  /// **'Solid Color'**
  String get solidColor;

  /// Background type — gradient
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get gradient;

  /// Action to add a gradient color stop
  ///
  /// In en, this message translates to:
  /// **'Add Stop'**
  String get addGradientStop;

  /// Action to remove a gradient color stop
  ///
  /// In en, this message translates to:
  /// **'Remove Stop'**
  String get removeGradientStop;

  /// Section label for device frame settings
  ///
  /// In en, this message translates to:
  /// **'Device Frame'**
  String get deviceFrame;

  /// Label for choosing a device frame
  ///
  /// In en, this message translates to:
  /// **'Select Device'**
  String get selectDevice;

  /// Option to display without a device frame
  ///
  /// In en, this message translates to:
  /// **'No Frame'**
  String get noFrame;

  /// iPhone device frame label
  ///
  /// In en, this message translates to:
  /// **'iPhone'**
  String get iphone;

  /// iPad device frame label
  ///
  /// In en, this message translates to:
  /// **'iPad'**
  String get ipad;

  /// Section label for text overlay controls
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textOverlay;

  /// Action to add a text overlay
  ///
  /// In en, this message translates to:
  /// **'Add Text'**
  String get addText;

  /// Default text for a new text overlay
  ///
  /// In en, this message translates to:
  /// **'New Text'**
  String get newText;

  /// Action to edit a text overlay
  ///
  /// In en, this message translates to:
  /// **'Edit Text'**
  String get editText;

  /// Label for the font size control
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// Label for the font weight control
  ///
  /// In en, this message translates to:
  /// **'Font Weight'**
  String get fontWeight;

  /// Label for the font family picker
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get fontFamily;

  /// Label for the text color picker
  ///
  /// In en, this message translates to:
  /// **'Text Color'**
  String get textColor;

  /// Label for text alignment options
  ///
  /// In en, this message translates to:
  /// **'Text Align'**
  String get textAlign;

  /// Label for text rotation control
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get textRotation;

  /// Label for text scale control
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get textScale;

  /// Label for text decoration options (underline, strikethrough)
  ///
  /// In en, this message translates to:
  /// **'Decoration'**
  String get textDecoration;

  /// Label for text background color control
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get textBackground;

  /// Label for text border/outline control
  ///
  /// In en, this message translates to:
  /// **'Border'**
  String get textBorder;

  /// Action to delete a text overlay
  ///
  /// In en, this message translates to:
  /// **'Delete Text'**
  String get deleteText;

  /// Section label for image overlay controls
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get imageOverlay;

  /// Action to add an image overlay
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get addImage;

  /// Action to delete an image overlay
  ///
  /// In en, this message translates to:
  /// **'Delete Image'**
  String get deleteImage;

  /// Section label for doodle pattern settings
  ///
  /// In en, this message translates to:
  /// **'Doodle'**
  String get doodle;

  /// Toggle label for enabling doodle icon pattern
  ///
  /// In en, this message translates to:
  /// **'Enable Doodle Pattern'**
  String get enableDoodle;

  /// Label for doodle icon source picker
  ///
  /// In en, this message translates to:
  /// **'Icon Source'**
  String get iconSource;

  /// Label for doodle icon size control
  ///
  /// In en, this message translates to:
  /// **'Icon Size'**
  String get iconSize;

  /// Label for doodle icon spacing control
  ///
  /// In en, this message translates to:
  /// **'Spacing'**
  String get iconSpacing;

  /// Label for doodle icon opacity control
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get iconOpacity;

  /// Label for doodle icon rotation control
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get iconRotation;

  /// Toggle label for random rotation on doodle icons
  ///
  /// In en, this message translates to:
  /// **'Randomize Rotation'**
  String get randomizeRotation;

  /// Section label for grid settings
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// Toggle to show grid lines
  ///
  /// In en, this message translates to:
  /// **'Show Grid'**
  String get showGrid;

  /// Toggle to snap elements to the grid
  ///
  /// In en, this message translates to:
  /// **'Snap to Grid'**
  String get snapToGrid;

  /// Label for the grid size slider
  ///
  /// In en, this message translates to:
  /// **'Grid Size'**
  String get gridSize;

  /// Toggle to show center alignment guides
  ///
  /// In en, this message translates to:
  /// **'Show Center Lines'**
  String get showCenterLines;

  /// Label for padding control
  ///
  /// In en, this message translates to:
  /// **'Padding'**
  String get padding;

  /// Label for corner radius control
  ///
  /// In en, this message translates to:
  /// **'Corner Radius'**
  String get cornerRadius;

  /// Label for device frame rotation control
  ///
  /// In en, this message translates to:
  /// **'Frame Rotation'**
  String get frameRotation;

  /// Label for orientation picker
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get orientation;

  /// Portrait orientation label
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get portrait;

  /// Landscape orientation label
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get landscape;

  /// Section label for editor tool bar
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// Action to pick an image from the file system
  ///
  /// In en, this message translates to:
  /// **'Pick Image'**
  String get pickImage;

  /// Action to import an image
  ///
  /// In en, this message translates to:
  /// **'Import Image'**
  String get importImage;

  /// Hint text shown in the drop zone
  ///
  /// In en, this message translates to:
  /// **'Drop image here'**
  String get dropImageHere;

  /// Action to replace an image
  ///
  /// In en, this message translates to:
  /// **'Replace Image'**
  String get replaceImage;

  /// Snackbar message after saving a design to the library
  ///
  /// In en, this message translates to:
  /// **'Saved to library'**
  String get savedToLibrary;

  /// Snackbar message after a successful export
  ///
  /// In en, this message translates to:
  /// **'Exported successfully'**
  String get exportedSuccessfully;

  /// Snackbar error message when export fails
  ///
  /// In en, this message translates to:
  /// **'Failed to export'**
  String get failedToExport;

  /// Toggle label for grid layout in the library
  ///
  /// In en, this message translates to:
  /// **'Grid View'**
  String get gridView;

  /// Toggle label for list layout in the library
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get listView;

  /// Empty state title in the design library
  ///
  /// In en, this message translates to:
  /// **'No designs yet'**
  String get emptyLibrary;

  /// Empty state subtitle in the design library
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first screenshot design'**
  String get emptyLibrarySubtitle;

  /// App version string in settings
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// Pluralized count of designs in a folder or library
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No designs} =1{1 design} other{{count} designs}}'**
  String designsCount(int count);

  /// Library section label
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// Empty state title when the library has no designs
  ///
  /// In en, this message translates to:
  /// **'No designs yet'**
  String get noDesignsYet;

  /// Empty state subtitle when the library has no designs
  ///
  /// In en, this message translates to:
  /// **'Create your first screenshot design'**
  String get createYourFirstDesign;

  /// Solid background type label
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get solid;

  /// Label for the background color picker
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get backgroundColor;

  /// Section label for gradient color stops
  ///
  /// In en, this message translates to:
  /// **'Gradient Colors'**
  String get gradientColors;

  /// Generic 'none' option label
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// Generic color label
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// Label for gradient stop location
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Label for gradient angle control
  ///
  /// In en, this message translates to:
  /// **'Angle'**
  String get angle;

  /// Action to remove a gradient stop
  ///
  /// In en, this message translates to:
  /// **'Remove Stop'**
  String get removeStop;

  /// Label for alignment control
  ///
  /// In en, this message translates to:
  /// **'Alignment'**
  String get alignment;

  /// Label for text decoration style picker
  ///
  /// In en, this message translates to:
  /// **'Decoration Style'**
  String get decorationStyle;

  /// Label for text decoration color picker
  ///
  /// In en, this message translates to:
  /// **'Decoration Color'**
  String get decorationColor;

  /// Section label for text border and fill settings
  ///
  /// In en, this message translates to:
  /// **'Border & Fill'**
  String get borderAndFill;

  /// Label for fill color picker
  ///
  /// In en, this message translates to:
  /// **'Fill Color'**
  String get fillColor;

  /// Label for border color picker
  ///
  /// In en, this message translates to:
  /// **'Border Color'**
  String get borderColor;

  /// Label for border width slider
  ///
  /// In en, this message translates to:
  /// **'Border Width'**
  String get borderWidth;

  /// Label for border radius slider
  ///
  /// In en, this message translates to:
  /// **'Border Radius'**
  String get borderRadius;

  /// Label for horizontal padding slider
  ///
  /// In en, this message translates to:
  /// **'Horizontal Padding'**
  String get horizontalPadding;

  /// Label for vertical padding slider
  ///
  /// In en, this message translates to:
  /// **'Vertical Padding'**
  String get verticalPadding;

  /// Label for generic rotation slider
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get rotation;

  /// Hint shown when no text overlay is selected
  ///
  /// In en, this message translates to:
  /// **'Select or add a text overlay'**
  String get selectOrAddText;

  /// Badge shown in text controls when a translation preview locale is active
  ///
  /// In en, this message translates to:
  /// **'Editing {locale} override'**
  String editingLocale(String locale);

  /// Action to copy the screenshot to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get copyToClipboard;

  /// Snackbar message after copying to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// Action to paste an image from clipboard
  ///
  /// In en, this message translates to:
  /// **'Paste from Clipboard'**
  String get pasteFromClipboard;

  /// Snackbar message when clipboard has no image
  ///
  /// In en, this message translates to:
  /// **'No image found in clipboard'**
  String get noImageInClipboard;

  /// Default share text when sharing a design
  ///
  /// In en, this message translates to:
  /// **'Check out my design!'**
  String get checkOutMyDesign;

  /// Templates section/button label
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// Overflow menu tooltip
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// Subtitle in the template picker
  ///
  /// In en, this message translates to:
  /// **'Pick a style for your screenshots'**
  String get pickAStyleForScreenshots;

  /// Section label for content controls in the editor
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// Placeholder text for the text overlay input
  ///
  /// In en, this message translates to:
  /// **'Enter text...'**
  String get enterText;

  /// Section label for typography controls
  ///
  /// In en, this message translates to:
  /// **'Typography'**
  String get typography;

  /// Section label for font size and weight controls
  ///
  /// In en, this message translates to:
  /// **'Size & Weight'**
  String get sizeAndWeight;

  /// Section label for transform controls (scale, rotation)
  ///
  /// In en, this message translates to:
  /// **'Transform'**
  String get transform;

  /// Label for the transparent background option
  ///
  /// In en, this message translates to:
  /// **'Transparent'**
  String get transparent;

  /// Action to add an icon overlay
  ///
  /// In en, this message translates to:
  /// **'Add Icon'**
  String get addIcon;

  /// Label for icon color picker
  ///
  /// In en, this message translates to:
  /// **'Icon Color'**
  String get iconColor;

  /// SF Symbols icon library label
  ///
  /// In en, this message translates to:
  /// **'SF Symbols'**
  String get sfSymbols;

  /// Material Icons library label
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get materialLabel;

  /// Emoji icon source label in the doodle icon style picker
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get emojiLabel;

  /// Hint text for the icon search field
  ///
  /// In en, this message translates to:
  /// **'Search icons...'**
  String get searchIcons;

  /// Icon style — rounded
  ///
  /// In en, this message translates to:
  /// **'Rounded'**
  String get roundedStyle;

  /// Icon style — sharp
  ///
  /// In en, this message translates to:
  /// **'Sharp'**
  String get sharpStyle;

  /// Icon style — outlined
  ///
  /// In en, this message translates to:
  /// **'Outlined'**
  String get outlinedStyle;

  /// Icon weight slider label
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightLabel;

  /// Display type picker label
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displayLabel;

  /// Grid toggle label in settings
  ///
  /// In en, this message translates to:
  /// **'Show Grid'**
  String get showGridLabel;

  /// Subtitle for the show grid toggle
  ///
  /// In en, this message translates to:
  /// **'Display grid lines on the canvas'**
  String get displayGridLines;

  /// Snap to grid toggle label in settings
  ///
  /// In en, this message translates to:
  /// **'Snap to Grid'**
  String get snapToGridLabel;

  /// Subtitle for the snap to grid toggle
  ///
  /// In en, this message translates to:
  /// **'Snap elements to the nearest grid line'**
  String get snapToGridSubtitle;

  /// Center alignment guides toggle label
  ///
  /// In en, this message translates to:
  /// **'Center Lines'**
  String get centerLines;

  /// Subtitle for the center lines toggle
  ///
  /// In en, this message translates to:
  /// **'Show center alignment guides'**
  String get centerLinesSubtitle;

  /// Grid size slider label in settings
  ///
  /// In en, this message translates to:
  /// **'Grid Size'**
  String get gridSizeLabel;

  /// Generic size label
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sizeLabel;

  /// Subtitle for the doodle pattern section
  ///
  /// In en, this message translates to:
  /// **'Scatter icon patterns behind content'**
  String get scatterIconPatterns;

  /// Label for the doodle icon style picker
  ///
  /// In en, this message translates to:
  /// **'Icon Style'**
  String get iconStyle;

  /// Presets section label in the icon picker
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get presetsLabel;

  /// Layout section label
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get layoutLabel;

  /// Opacity slider label
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get opacityLabel;

  /// Icon size slider label in doodle settings
  ///
  /// In en, this message translates to:
  /// **'Icon Size'**
  String get iconSizeLabel;

  /// Spacing slider label in doodle settings
  ///
  /// In en, this message translates to:
  /// **'Spacing'**
  String get spacingLabel;

  /// Label for the custom icons section in the icon picker
  ///
  /// In en, this message translates to:
  /// **'Custom Icons'**
  String get customIcons;

  /// Label for a screenshot by its index in the multi-screenshot editor
  ///
  /// In en, this message translates to:
  /// **'Screenshot {index}'**
  String screenshotLabel(int index);

  /// Hint text for the library search bar
  ///
  /// In en, this message translates to:
  /// **'Search designs and folders…'**
  String get searchDesignsAndFolders;

  /// Message shown when library search yields no results
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsFor(String query);

  /// Action to zoom the canvas to fit the screenshot
  ///
  /// In en, this message translates to:
  /// **'Zoom to Fit'**
  String get zoomToFit;

  /// Action to add another screenshot in multi-screenshot mode
  ///
  /// In en, this message translates to:
  /// **'Add Screenshot'**
  String get addScreenshot;

  /// Action to export only the currently active screenshot
  ///
  /// In en, this message translates to:
  /// **'Export Current'**
  String get exportCurrent;

  /// Action to export all screenshots at once
  ///
  /// In en, this message translates to:
  /// **'Export All'**
  String get exportAll;

  /// Dialog title for choosing the export directory
  ///
  /// In en, this message translates to:
  /// **'Select export folder'**
  String get selectExportFolder;

  /// Title showing the number of screenshots in the multi-editor
  ///
  /// In en, this message translates to:
  /// **'Screenshot Studio · {count} screenshots'**
  String screenshotStudioCount(int count);

  /// Section label for device frame options
  ///
  /// In en, this message translates to:
  /// **'Device Frames'**
  String get deviceFrames;

  /// Section label for gradient preset options
  ///
  /// In en, this message translates to:
  /// **'Gradients'**
  String get gradients;

  /// Section label for text overlay options
  ///
  /// In en, this message translates to:
  /// **'Text Overlays'**
  String get textOverlays;

  /// Section label for doodle pattern options
  ///
  /// In en, this message translates to:
  /// **'Doodles'**
  String get doodles;

  /// Short label for device frame
  ///
  /// In en, this message translates to:
  /// **'Frame'**
  String get frame;

  /// Short label for text
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// Pro upgrade banner title
  ///
  /// In en, this message translates to:
  /// **'✨ Unlock Pro'**
  String get unlockPro;

  /// Pro upgrade banner subtitle
  ///
  /// In en, this message translates to:
  /// **'Remove all creative limits'**
  String get removeAllCreativeLimits;

  /// Pro feature bullet — folders and unlimited saves
  ///
  /// In en, this message translates to:
  /// **'Folders & Unlimited Saves'**
  String get foldersUnlimitedSaves;

  /// Description for the folders and unlimited saves Pro feature
  ///
  /// In en, this message translates to:
  /// **'Stay organised with folders and save as many designs as you want'**
  String get foldersUnlimitedSavesSubtitle;

  /// Pro feature bullet — all devices and multi-screenshot
  ///
  /// In en, this message translates to:
  /// **'All Devices + Multi-Screenshot'**
  String get allDevicesMultiScreenshot;

  /// Description for the all devices and multi-screenshot Pro feature
  ///
  /// In en, this message translates to:
  /// **'Use every device frame and design multiple screenshots at once'**
  String get allDevicesMultiScreenshotSubtitle;

  /// Pro feature bullet — advanced design tools
  ///
  /// In en, this message translates to:
  /// **'Advanced Design Tools'**
  String get advancedDesignTools;

  /// Description for the advanced design tools Pro feature
  ///
  /// In en, this message translates to:
  /// **'Unlock text overlays, icons, doodles, and the full Google Fonts library'**
  String get advancedDesignToolsSubtitle;

  /// Pro feature bullet — unlimited multi-screenshot sets
  ///
  /// In en, this message translates to:
  /// **'Unlimited Multi-Screenshot Sets'**
  String get proUnlimitedMultiSets;

  /// Description for the unlimited multi-screenshot sets Pro feature
  ///
  /// In en, this message translates to:
  /// **'Create as many sets as you need'**
  String get proUnlimitedMultiSetsSubtitle;

  /// Pro feature bullet — all device frames in multi-screenshot mode
  ///
  /// In en, this message translates to:
  /// **'All Device Frames in Multi Mode'**
  String get proAllDevicesMultiMode;

  /// Description for the all devices in multi mode Pro feature
  ///
  /// In en, this message translates to:
  /// **'iPad, Apple Watch & more for batch screenshots'**
  String get proAllDevicesMultiModeSubtitle;

  /// Pro feature bullet — AI translation for all locales
  ///
  /// In en, this message translates to:
  /// **'AI Translation — All Locales'**
  String get proAiTranslationAllLocales;

  /// Description for the AI translation all locales Pro feature
  ///
  /// In en, this message translates to:
  /// **'Translate to every App Store language at once'**
  String get proAiTranslationSubtitle;

  /// Pro feature bullet — all doodle presets and custom icons
  ///
  /// In en, this message translates to:
  /// **'All Doodle Presets & Custom Icons'**
  String get proAllDoodlePresets;

  /// Description for the all doodle presets Pro feature
  ///
  /// In en, this message translates to:
  /// **'Full creative freedom with unlimited patterns'**
  String get proAllDoodlePresetsSubtitle;

  /// Short 'Pro' label used on locked feature badges
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get proLabel;

  /// CTA button label on the Pro upgrade sheet
  ///
  /// In en, this message translates to:
  /// **'Continue with Pro'**
  String get continueWithPro;

  /// Action to restore previous Pro purchases
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// Settings section header for support links
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Settings section header for legal links
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// Settings tile — rate the app on the App Store
  ///
  /// In en, this message translates to:
  /// **'Rate on App Store'**
  String get rateOnAppStore;

  /// Settings tile — send feedback via email
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// Settings tile — redeem a promo code
  ///
  /// In en, this message translates to:
  /// **'Redeem Code'**
  String get redeemCode;

  /// Settings tile — view terms of service
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Settings tile — view privacy policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Review prompt card title
  ///
  /// In en, this message translates to:
  /// **'Enjoying App Screenshots?'**
  String get enjoyingApp;

  /// Review prompt card subtitle
  ///
  /// In en, this message translates to:
  /// **'Tap to let us know how we\'re doing'**
  String get enjoyingAppSubtitle;

  /// Action label for restoring with a code
  ///
  /// In en, this message translates to:
  /// **'Restore Code'**
  String get restoreCode;

  /// CTA button label to upgrade to Pro
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get upgradeNow;

  /// Selling point on the Pro upgrade sheet
  ///
  /// In en, this message translates to:
  /// **'One-time purchase — forever yours'**
  String get oneTimePurchase;

  /// Singular form — action to restore a purchase
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get restorePurchase;

  /// Badge label when Pro is active
  ///
  /// In en, this message translates to:
  /// **'Pro Active'**
  String get proActive;

  /// Subtitle when Pro is active
  ///
  /// In en, this message translates to:
  /// **'All features unlocked'**
  String get allFeaturesUnlocked;

  /// Settings tile title to upgrade to Pro
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// Settings tile subtitle describing Pro benefits
  ///
  /// In en, this message translates to:
  /// **'Unlock folders, all devices, multi-screenshot, advanced design tools & more.'**
  String get upgradeToProDescription;

  /// Short restore action label
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// Settings section header for app icon selection
  ///
  /// In en, this message translates to:
  /// **'App Icon'**
  String get appIcon;

  /// Label for the default app icon
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// Label for the purple app icon
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get purpleLabel;

  /// Progress message while screenshots are being exported
  ///
  /// In en, this message translates to:
  /// **'Exporting screenshots…'**
  String get exportingScreenshots;

  /// Tab or section label for images
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// Tab or section label for icons
  ///
  /// In en, this message translates to:
  /// **'Icons'**
  String get icons;

  /// Title of the font picker dialog
  ///
  /// In en, this message translates to:
  /// **'Select Font'**
  String get selectFont;

  /// Hint text for the font search field
  ///
  /// In en, this message translates to:
  /// **'Search fonts…'**
  String get searchFonts;

  /// Label for the gradient stops section
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get stops;

  /// Hint for adding gradient stops by tapping the bar
  ///
  /// In en, this message translates to:
  /// **'Tap bar to add'**
  String get tapBarToAdd;

  /// Label for the currently selected gradient stop
  ///
  /// In en, this message translates to:
  /// **'Selected Stop'**
  String get selectedStop;

  /// Pluralized item count displayed in the library
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemCount(int count);

  /// Subtitle in the new design screen size picker
  ///
  /// In en, this message translates to:
  /// **'Choose a screen size for your design'**
  String get chooseScreenSize;

  /// Mode label for multi-screenshot editing
  ///
  /// In en, this message translates to:
  /// **'Multi-Screenshot'**
  String get multiScreenshot;

  /// Description for multi-screenshot mode
  ///
  /// In en, this message translates to:
  /// **'Create up to 10 screenshots'**
  String get createUpTo10Screenshots;

  /// Subtitle in the multi-screenshot screen size picker
  ///
  /// In en, this message translates to:
  /// **'Pick a screen size for your screenshots'**
  String get pickScreenSize;

  /// Alternative hint to pick a device screen size
  ///
  /// In en, this message translates to:
  /// **'or pick a device size'**
  String get orPickDeviceSize;

  /// Drop zone hint on desktop
  ///
  /// In en, this message translates to:
  /// **'Drag screenshots into this area'**
  String get dragScreenshotsHint;

  /// Drop zone secondary hint on desktop
  ///
  /// In en, this message translates to:
  /// **'or click here to import'**
  String get tapImportHint;

  /// Import hint on mobile devices
  ///
  /// In en, this message translates to:
  /// **'Tap Import to add a screenshot'**
  String get tapImportHintMobile;

  /// Action to share a .design file
  ///
  /// In en, this message translates to:
  /// **'Share Design File'**
  String get shareDesignFile;

  /// Action to import a .design file
  ///
  /// In en, this message translates to:
  /// **'Import Design'**
  String get importDesign;

  /// Snackbar message after exporting a design file
  ///
  /// In en, this message translates to:
  /// **'Design exported successfully'**
  String get designExportedSuccessfully;

  /// Snackbar message after importing a design file
  ///
  /// In en, this message translates to:
  /// **'Design imported successfully'**
  String get designImportedSuccessfully;

  /// Snackbar error message when design import fails
  ///
  /// In en, this message translates to:
  /// **'Failed to import design'**
  String get failedToImportDesign;

  /// Snackbar message after saving a design to a file
  ///
  /// In en, this message translates to:
  /// **'Saved to file'**
  String get savedToFile;

  /// Action to save a design to the library
  ///
  /// In en, this message translates to:
  /// **'Save to Library'**
  String get saveToLibrary;

  /// Settings section header for iCloud backup
  ///
  /// In en, this message translates to:
  /// **'iCloud Backup'**
  String get icloudBackup;

  /// Action to trigger an iCloud backup
  ///
  /// In en, this message translates to:
  /// **'Backup Now'**
  String get backupNow;

  /// Action to restore from an iCloud backup
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get restoreFromBackup;

  /// Label showing the last backup date
  ///
  /// In en, this message translates to:
  /// **'Last backup'**
  String get lastBackup;

  /// Info text about automatic backups
  ///
  /// In en, this message translates to:
  /// **'Backups are created automatically'**
  String get backupsAutomatic;

  /// Message when no iCloud backups exist
  ///
  /// In en, this message translates to:
  /// **'No backups available'**
  String get noBackupsAvailable;

  /// Warning message before restoring from backup
  ///
  /// In en, this message translates to:
  /// **'Restoring will replace all current designs. This cannot be undone.'**
  String get restoreWarning;

  /// Snackbar message after a successful restore
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully'**
  String get backupRestoredSuccessfully;

  /// Snackbar message after a successful backup
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get backupCreatedSuccessfully;

  /// Snackbar error message when backup fails
  ///
  /// In en, this message translates to:
  /// **'Backup failed'**
  String get backupFailed;

  /// Snackbar error message when iCloud is not available
  ///
  /// In en, this message translates to:
  /// **'iCloud is not available'**
  String get icloudNotAvailable;

  /// Label for the gradient type picker (linear, radial, sweep, mesh)
  ///
  /// In en, this message translates to:
  /// **'Gradient Type'**
  String get gradientType;

  /// Linear gradient type label
  ///
  /// In en, this message translates to:
  /// **'Linear'**
  String get linear;

  /// Radial gradient type label
  ///
  /// In en, this message translates to:
  /// **'Radial'**
  String get radial;

  /// Sweep gradient type label
  ///
  /// In en, this message translates to:
  /// **'Sweep'**
  String get sweep;

  /// Mesh gradient type label
  ///
  /// In en, this message translates to:
  /// **'Mesh'**
  String get mesh;

  /// Section label for radial gradient configuration
  ///
  /// In en, this message translates to:
  /// **'Radial Settings'**
  String get radialSettings;

  /// Label for the radial gradient radius slider
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get radius;

  /// Section label for sweep gradient configuration
  ///
  /// In en, this message translates to:
  /// **'Sweep Settings'**
  String get sweepSettings;

  /// Label for sweep gradient start angle slider
  ///
  /// In en, this message translates to:
  /// **'Start Angle'**
  String get startAngle;

  /// Label for sweep gradient end angle slider
  ///
  /// In en, this message translates to:
  /// **'End Angle'**
  String get endAngle;

  /// Section label for mesh gradient point list
  ///
  /// In en, this message translates to:
  /// **'Mesh Points'**
  String get meshPoints;

  /// Section label for mesh gradient configuration
  ///
  /// In en, this message translates to:
  /// **'Mesh Options'**
  String get meshOptions;

  /// Label for mesh gradient blend control
  ///
  /// In en, this message translates to:
  /// **'Blend'**
  String get blend;

  /// Label for mesh gradient noise control
  ///
  /// In en, this message translates to:
  /// **'Noise'**
  String get noise;

  /// Toggle label for showing dots on the editor canvas
  ///
  /// In en, this message translates to:
  /// **'Canvas Dots'**
  String get showDotGrid;

  /// Subtitle for the canvas dots toggle
  ///
  /// In en, this message translates to:
  /// **'Show dot pattern on the editor background'**
  String get showDotGridSubtitle;

  /// Action to add a mesh gradient point
  ///
  /// In en, this message translates to:
  /// **'Add Point'**
  String get addPoint;

  /// Action to remove a mesh gradient point
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removePoint;

  /// Label for the X-axis center position slider
  ///
  /// In en, this message translates to:
  /// **'Center X'**
  String get centerX;

  /// Label for the Y-axis center position slider
  ///
  /// In en, this message translates to:
  /// **'Center Y'**
  String get centerY;

  /// Pluralized mesh point count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 point} other{{count} points}}'**
  String pointCount(int count);

  /// Label for a mesh gradient point by index
  ///
  /// In en, this message translates to:
  /// **'Point {index}'**
  String pointLabel(int index);

  /// Short label for the X axis
  ///
  /// In en, this message translates to:
  /// **'X'**
  String get xAxis;

  /// Short label for the Y axis
  ///
  /// In en, this message translates to:
  /// **'Y'**
  String get yAxis;

  /// ASC upload sheet header title
  ///
  /// In en, this message translates to:
  /// **'Upload to App Store Connect'**
  String get uploadToAppStoreConnect;

  /// Loading state text while fetching apps from ASC
  ///
  /// In en, this message translates to:
  /// **'Loading apps...'**
  String get loadingApps;

  /// Loading state text while fetching the app version
  ///
  /// In en, this message translates to:
  /// **'Loading version for {appName}...'**
  String loadingVersionForApp(String appName);

  /// Generic fallback error message
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// Title shown when no ASC API key is set up
  ///
  /// In en, this message translates to:
  /// **'No API Key Configured'**
  String get noApiKeyConfigured;

  /// Description text for the no-API-key prompt
  ///
  /// In en, this message translates to:
  /// **'Set up your App Store Connect API key to upload screenshots.'**
  String get ascApiKeySetupHint;

  /// Button label to open the API key configuration
  ///
  /// In en, this message translates to:
  /// **'Configure API Key'**
  String get configureApiKey;

  /// Title for the app picker in the ASC upload sheet
  ///
  /// In en, this message translates to:
  /// **'Select App'**
  String get selectApp;

  /// Hint text for the app search field
  ///
  /// In en, this message translates to:
  /// **'Search apps...'**
  String get searchApps;

  /// Empty state title when no apps are returned
  ///
  /// In en, this message translates to:
  /// **'No apps found'**
  String get noAppsFound;

  /// Subtitle for the no-apps-found empty state
  ///
  /// In en, this message translates to:
  /// **'Check your API key permissions.'**
  String get checkApiKeyPermissions;

  /// Message when searching apps yields no results
  ///
  /// In en, this message translates to:
  /// **'No apps match \"{query}\"'**
  String noAppsMatchQuery(String query);

  /// Action label to re-select the target ASC app
  ///
  /// In en, this message translates to:
  /// **'Change app'**
  String get changeApp;

  /// Section label for choosing replace vs append mode
  ///
  /// In en, this message translates to:
  /// **'Screenshot Display Type'**
  String get screenshotDisplayType;

  /// Upload mode — replace existing screenshots
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// Upload mode — append to existing screenshots
  ///
  /// In en, this message translates to:
  /// **'Append'**
  String get append;

  /// Toggle label to persist app selection for the design
  ///
  /// In en, this message translates to:
  /// **'Remember for this design'**
  String get rememberForThisDesign;

  /// Tooltip when remember-for-design is enabled
  ///
  /// In en, this message translates to:
  /// **'Will skip app selection next time'**
  String get willSkipAppSelectionNextTime;

  /// Tooltip when remember-for-design is disabled
  ///
  /// In en, this message translates to:
  /// **'You\'ll pick the app each time'**
  String get youllPickTheAppEachTime;

  /// Section header for the locale checklist in the upload sheet
  ///
  /// In en, this message translates to:
  /// **'LOCALES'**
  String get localesHeader;

  /// Action to deselect all locales
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// Action to select all locales
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// Hint text when no locales are selected
  ///
  /// In en, this message translates to:
  /// **'Select locales to upload'**
  String get selectLocalesToUpload;

  /// Upload button label with selected locale count
  ///
  /// In en, this message translates to:
  /// **'Upload {count} {count, plural, =1{Locale} other{Locales}}'**
  String uploadNLocales(int count);

  /// Pluralized screenshot count in upload summary
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{screenshot} other{screenshots}}'**
  String nScreenshots(int count);

  /// Connective word in 'X screenshots across Y locales'
  ///
  /// In en, this message translates to:
  /// **'across'**
  String get across;

  /// Pluralized locale count in upload summary
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{locale} other{locales}}'**
  String nLocales(int count);

  /// Pluralized file count
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{file} other{files}}'**
  String nFiles(int count);

  /// Title shown when all uploads fail
  ///
  /// In en, this message translates to:
  /// **'Upload Failed'**
  String get uploadFailed;

  /// Title shown when some uploads succeed and some fail
  ///
  /// In en, this message translates to:
  /// **'Completed with Issues'**
  String get completedWithIssues;

  /// Title shown when all uploads succeed
  ///
  /// In en, this message translates to:
  /// **'Upload Complete!'**
  String get uploadComplete;

  /// Success count chip in the upload-done view
  ///
  /// In en, this message translates to:
  /// **'{count} succeeded'**
  String nSucceeded(int count);

  /// Failure count chip in the upload-done view
  ///
  /// In en, this message translates to:
  /// **'{count} failed'**
  String nFailed(int count);

  /// Progress label showing the locale currently being uploaded
  ///
  /// In en, this message translates to:
  /// **'Uploading {locale}'**
  String uploadingLocale(String locale);

  /// Progress counter showing current/total screenshots
  ///
  /// In en, this message translates to:
  /// **'{current} of {total} screenshots'**
  String nOfTotalScreenshots(int current, int total);

  /// Status label while upload is being prepared
  ///
  /// In en, this message translates to:
  /// **'Preparing upload...'**
  String get preparingUpload;

  /// Upload status — waiting to start
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// Upload status — in progress
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get statusUploading;

  /// Upload status — finished successfully
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// Upload status — failed
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// Generic error title
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// Action to retry a failed operation
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Title of the ASC credentials dialog
  ///
  /// In en, this message translates to:
  /// **'App Store Connect API Key'**
  String get appStoreConnectApiKey;

  /// Help text explaining where to generate an ASC API key
  ///
  /// In en, this message translates to:
  /// **'Generate an API key in App Store Connect → Users & Access → Integrations → Keys'**
  String get ascApiKeyGenerateHint;

  /// Label for the ASC Key ID field
  ///
  /// In en, this message translates to:
  /// **'Key ID'**
  String get keyId;

  /// Hint text for the Key ID field
  ///
  /// In en, this message translates to:
  /// **'e.g. ABC1234DEF'**
  String get keyIdHint;

  /// Label for the ASC Issuer ID field
  ///
  /// In en, this message translates to:
  /// **'Issuer ID'**
  String get issuerId;

  /// Hint text for the Issuer ID field
  ///
  /// In en, this message translates to:
  /// **'e.g. 12345678-1234-1234-1234-123456789012'**
  String get issuerIdHint;

  /// Label for the ASC private key field
  ///
  /// In en, this message translates to:
  /// **'Private Key (.p8 file content)'**
  String get privateKeyLabel;

  /// Hint when a private key already exists
  ///
  /// In en, this message translates to:
  /// **'••••••• (leave blank to keep existing)'**
  String get privateKeyExistingHint;

  /// Hint text for entering a new private key
  ///
  /// In en, this message translates to:
  /// **'-----BEGIN PRIVATE KEY-----\n...'**
  String get privateKeyNewHint;

  /// Action to clear credentials
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Title of the clear-credentials confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Clear Credentials?'**
  String get clearCredentialsTitle;

  /// Body text of the clear-credentials confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This will remove your saved API key. You\'ll need to re-enter it for future uploads.'**
  String get clearCredentialsMessage;

  /// Settings tile title for the ASC API key
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKeySettingsTitle;

  /// Subtitle shown while API key status is loading
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get apiKeyLoading;

  /// Subtitle showing the masked API Key ID when configured
  ///
  /// In en, this message translates to:
  /// **'Key ID: {maskedKeyId}'**
  String apiKeyConfigured(String maskedKeyId);

  /// Subtitle shown when no API key is configured
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get apiKeyNotConfigured;

  /// Label for the translation provider selector
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// Label for the app context description field
  ///
  /// In en, this message translates to:
  /// **'App Context'**
  String get appContext;

  /// Hint text for the app context field
  ///
  /// In en, this message translates to:
  /// **'Add context...'**
  String get addContext;

  /// Label for the source language picker
  ///
  /// In en, this message translates to:
  /// **'Source Language'**
  String get sourceLanguage;

  /// Label for the target languages section
  ///
  /// In en, this message translates to:
  /// **'Target Languages'**
  String get targetLanguages;

  /// Button label to translate all text overlays
  ///
  /// In en, this message translates to:
  /// **'Translate All'**
  String get translateAll;

  /// Progress label during batch translation
  ///
  /// In en, this message translates to:
  /// **'Translating {completed} / {total}'**
  String translatingProgress(int completed, int total);

  /// Button label for the manual copy-paste translation flow
  ///
  /// In en, this message translates to:
  /// **'Manual (Copy-Paste)'**
  String get manualCopyPaste;

  /// Menu item label to upload screenshots to App Store Connect
  ///
  /// In en, this message translates to:
  /// **'Upload to ASC'**
  String get uploadToAsc;

  /// Action to upload an existing folder of screenshots to ASC without rendering
  ///
  /// In en, this message translates to:
  /// **'Upload Existing Folder...'**
  String get uploadExistingFolderToAsc;

  /// Error message when the selected folder for ASC upload contains no valid images
  ///
  /// In en, this message translates to:
  /// **'No valid screenshot images found in selected folder'**
  String get noImagesFoundInFolder;

  /// Action to add more target languages
  ///
  /// In en, this message translates to:
  /// **'Add more languages'**
  String get addMoreLanguages;

  /// Action to edit existing translations
  ///
  /// In en, this message translates to:
  /// **'Edit Translations'**
  String get editTranslations;

  /// Snackbar message when trying to translate without text overlays
  ///
  /// In en, this message translates to:
  /// **'Add text overlays to your screenshots first'**
  String get addTextOverlaysFirst;

  /// Snackbar message when no target language is selected
  ///
  /// In en, this message translates to:
  /// **'Select at least one target language'**
  String get selectAtLeastOneTargetLanguage;

  /// Snackbar error when locale screenshot capture fails
  ///
  /// In en, this message translates to:
  /// **'Failed to capture locale screenshots'**
  String get failedToCaptureLocaleScreenshots;

  /// Title of the translation settings sheet
  ///
  /// In en, this message translates to:
  /// **'Translation Provider'**
  String get translationProvider;

  /// Subtitle of the translation settings sheet
  ///
  /// In en, this message translates to:
  /// **'Choose how your text gets translated'**
  String get chooseHowTextGetsTranslated;

  /// Label for the translation provider API key field
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// Security note about API key storage
  ///
  /// In en, this message translates to:
  /// **'API keys are stored securely in the macOS Keychain'**
  String get apiKeysStoredSecurely;

  /// Label for the custom translation endpoint URL field
  ///
  /// In en, this message translates to:
  /// **'Endpoint URL'**
  String get endpointUrl;

  /// Label for the AI model name field
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// Translation provider name — Apple on-device
  ///
  /// In en, this message translates to:
  /// **'Apple (On-Device)'**
  String get providerApple;

  /// Translation provider name — OpenAI
  ///
  /// In en, this message translates to:
  /// **'OpenAI'**
  String get providerOpenai;

  /// Translation provider name — Google Gemini
  ///
  /// In en, this message translates to:
  /// **'Google Gemini'**
  String get providerGemini;

  /// Translation provider name — DeepL
  ///
  /// In en, this message translates to:
  /// **'DeepL'**
  String get providerDeepl;

  /// Translation provider name — custom endpoint
  ///
  /// In en, this message translates to:
  /// **'Custom Endpoint'**
  String get providerCustom;

  /// Translation provider name — manual copy-paste
  ///
  /// In en, this message translates to:
  /// **'Manual (Copy-Paste)'**
  String get providerManual;

  /// Subtitle for the Apple on-device provider
  ///
  /// In en, this message translates to:
  /// **'Free, private — requires Apple Intelligence'**
  String get providerAppleSubtitle;

  /// Subtitle for the OpenAI provider
  ///
  /// In en, this message translates to:
  /// **'GPT-4o Mini — bring your own API key'**
  String get providerOpenaiSubtitle;

  /// Subtitle for the Google Gemini provider
  ///
  /// In en, this message translates to:
  /// **'Gemini 2.0 Flash — bring your own API key'**
  String get providerGeminiSubtitle;

  /// Subtitle for the DeepL provider
  ///
  /// In en, this message translates to:
  /// **'Professional translation — bring your own API key'**
  String get providerDeeplSubtitle;

  /// Subtitle for the custom endpoint provider
  ///
  /// In en, this message translates to:
  /// **'Ollama, Together AI, LM Studio, etc.'**
  String get providerCustomSubtitle;

  /// Subtitle for the manual copy-paste provider
  ///
  /// In en, this message translates to:
  /// **'Copy prompt → paste into any AI → paste response back'**
  String get providerManualSubtitle;

  /// Title of the manual translation dialog showing target locales
  ///
  /// In en, this message translates to:
  /// **'Manual Translate → {locales}'**
  String manualTranslateTitle(String locales);

  /// Section label in the manual translation dialog
  ///
  /// In en, this message translates to:
  /// **'Step 1: Copy this prompt'**
  String get step1CopyPrompt;

  /// Section label in the manual translation dialog
  ///
  /// In en, this message translates to:
  /// **'Step 2: Paste AI response'**
  String get step2PasteResponse;

  /// Tooltip shown after text is copied
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copied;

  /// Button label to copy the translation prompt
  ///
  /// In en, this message translates to:
  /// **'Copy Prompt'**
  String get copyPrompt;

  /// Button label to paste from clipboard
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// Hint text for the AI response paste field
  ///
  /// In en, this message translates to:
  /// **'Paste the JSON response from ChatGPT, Claude, Gemini, or any other AI.'**
  String get pasteJsonHint;

  /// Button label to apply pasted translations
  ///
  /// In en, this message translates to:
  /// **'Apply Translations'**
  String get applyTranslations;

  /// Error message when AI response JSON is invalid
  ///
  /// In en, this message translates to:
  /// **'Could not parse JSON. Please check the response format and try again.'**
  String get couldNotParseJson;

  /// Error when pasted translations are missing some locales
  ///
  /// In en, this message translates to:
  /// **'Missing locales: {locales}'**
  String missingLocalesError(String locales);

  /// Error when a locale's translations are missing some keys
  ///
  /// In en, this message translates to:
  /// **'{locale} is missing keys: {keys}'**
  String localeMissingKeysError(String locale, String keys);

  /// Pluralized text count on locale translation cards
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{text} other{texts}}'**
  String nTexts(int count);

  /// Title of the app context edit dialog
  ///
  /// In en, this message translates to:
  /// **'App Context'**
  String get appContextDialogTitle;

  /// Description text in the app context dialog
  ///
  /// In en, this message translates to:
  /// **'Describe your app so translations match its tone and domain.'**
  String get appContextDescription;

  /// Hint text for the app context text area
  ///
  /// In en, this message translates to:
  /// **'e.g. A fitness tracking app for runners. Use energetic and motivational language.'**
  String get appContextHint;

  /// Title of the add-languages dialog
  ///
  /// In en, this message translates to:
  /// **'Add Languages'**
  String get addLanguages;

  /// Hint text for the language search field
  ///
  /// In en, this message translates to:
  /// **'Search language...'**
  String get searchLanguage;

  /// Empty state when language search yields no results
  ///
  /// In en, this message translates to:
  /// **'No languages found'**
  String get noLanguagesFound;

  /// Button label when no languages are checked
  ///
  /// In en, this message translates to:
  /// **'Select languages'**
  String get selectLanguages;

  /// Button label showing how many languages will be added
  ///
  /// In en, this message translates to:
  /// **'Add {count} {count, plural, =1{language} other{languages}}'**
  String addNLanguages(int count);

  /// Settings section header for App Store Connect configuration
  ///
  /// In en, this message translates to:
  /// **'App Store Connect'**
  String get appStoreConnect;

  /// Label for the AI template generation button/card
  ///
  /// In en, this message translates to:
  /// **'✨ AI Generate'**
  String get aiGenerate;

  /// Subtitle for the AI template generation dialog
  ///
  /// In en, this message translates to:
  /// **'Describe your style and let AI create a template'**
  String get aiGenerateSubtitle;

  /// Hint text for the AI template description text field
  ///
  /// In en, this message translates to:
  /// **'e.g., Dark elegant style for a fitness app'**
  String get aiTemplatePromptHint;

  /// Loading text shown while AI generates a template
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get aiTemplateGenerating;

  /// Error message when AI template generation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to generate template'**
  String get aiTemplateError;

  /// Message when no API key is configured for AI template generation
  ///
  /// In en, this message translates to:
  /// **'Set up a Gemini API key in Settings to use AI templates'**
  String get aiTemplateNoApiKey;

  /// Generate action button label
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// Title for the apply template confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Apply Template'**
  String get applyTemplate;

  /// Confirmation message when applying a template to existing screenshots
  ///
  /// In en, this message translates to:
  /// **'This will replace the design of all your current screenshots with the selected template.'**
  String get applyTemplateConfirm;

  /// Confirmation message when applying a template that will add new screenshots
  ///
  /// In en, this message translates to:
  /// **'This template has {templateCount} designs but you currently have {currentCount}. Missing screenshots will be created automatically, and all designs will be replaced.'**
  String applyTemplateConfirmExpand(int templateCount, int currentCount);

  /// Apply action button label
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Title for the AI provider settings section
  ///
  /// In en, this message translates to:
  /// **'AI Provider'**
  String get aiProviderSettings;

  /// Label for the AI provider selector
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get aiProvider;

  /// Hint text for the AI API key input field
  ///
  /// In en, this message translates to:
  /// **'Paste your API key here'**
  String get aiApiKeyHint;

  /// Helper text for obtaining a Gemini API key
  ///
  /// In en, this message translates to:
  /// **'Get your API key from Google AI Studio (aistudio.google.com).'**
  String get aiGeminiKeyHelp;

  /// Helper text for obtaining an OpenAI API key
  ///
  /// In en, this message translates to:
  /// **'Get your API key from the OpenAI dashboard (platform.openai.com).'**
  String get aiOpenaiKeyHelp;

  /// Info text explaining Apple FM requires no key
  ///
  /// In en, this message translates to:
  /// **'Apple Foundation Models run on-device. No API key or internet connection needed.'**
  String get aiAppleFmInfo;

  /// Subtitle when no AI API key is set
  ///
  /// In en, this message translates to:
  /// **'No API key configured'**
  String get aiKeyNotConfigured;

  /// Title for the AI design assistant sidebar tab
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// Subtitle in AI assistant empty state
  ///
  /// In en, this message translates to:
  /// **'Describe design changes and let AI apply them'**
  String get aiAssistantSubtitle;

  /// Placeholder text in the AI assistant input field
  ///
  /// In en, this message translates to:
  /// **'Describe what you\'d like to change...'**
  String get aiAssistantHint;

  /// Label above suggestion chips in AI assistant
  ///
  /// In en, this message translates to:
  /// **'Try these'**
  String get aiAssistantSuggestions;

  /// Shown while AI processes a design request
  ///
  /// In en, this message translates to:
  /// **'Thinking...'**
  String get aiAssistantThinking;

  /// Button to revert to the design before the AI change
  ///
  /// In en, this message translates to:
  /// **'Undo AI change'**
  String get aiAssistantUndo;

  /// Tooltip for the clear chat button in AI assistant
  ///
  /// In en, this message translates to:
  /// **'Clear chat'**
  String get aiAssistantClearChat;

  /// Checkbox label for applying AI changes to all screenshots
  ///
  /// In en, this message translates to:
  /// **'Apply to all screenshots'**
  String get aiAssistantApplyToAll;

  /// Success message after bulk AI operation
  ///
  /// In en, this message translates to:
  /// **'Applied changes to {count} screenshots.'**
  String aiAssistantAppliedToAll(int count);

  /// Partial success message after bulk AI operation
  ///
  /// In en, this message translates to:
  /// **'Applied to {success}/{total} screenshots. {failed} failed.'**
  String aiAssistantPartialSuccess(int success, int total, int failed);

  /// Generic error message in AI assistant
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String aiAssistantUnexpectedError(String error);

  /// Contextual suggestion chip for adding gradient
  ///
  /// In en, this message translates to:
  /// **'Add a gradient background'**
  String get aiSuggestionAddGradient;

  /// Contextual suggestion chip for light mode
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get aiSuggestionLightMode;

  /// Contextual suggestion chip for dark mode
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get aiSuggestionDarkMode;

  /// Contextual suggestion chip for adding headline
  ///
  /// In en, this message translates to:
  /// **'Add a catchy headline'**
  String get aiSuggestionAddHeadline;

  /// Contextual suggestion chip for larger title
  ///
  /// In en, this message translates to:
  /// **'Make title bigger'**
  String get aiSuggestionBiggerTitle;

  /// Contextual suggestion chip for adding subtitle
  ///
  /// In en, this message translates to:
  /// **'Add a subtitle'**
  String get aiSuggestionAddSubtitle;

  /// Contextual suggestion chip for tilting frame
  ///
  /// In en, this message translates to:
  /// **'Tilt device frame'**
  String get aiSuggestionTiltFrame;

  /// Contextual suggestion chip for rounding corners
  ///
  /// In en, this message translates to:
  /// **'Round the corners'**
  String get aiSuggestionRoundCorners;

  /// Contextual suggestion chip for AI copywriting
  ///
  /// In en, this message translates to:
  /// **'Write a catchy headline'**
  String get aiSuggestionWriteHeadline;

  /// Contextual suggestion chip for color palette
  ///
  /// In en, this message translates to:
  /// **'Suggest a color palette'**
  String get aiSuggestionColorPalette;

  /// Contextual suggestion chip for adding doodle pattern
  ///
  /// In en, this message translates to:
  /// **'Add a doodle pattern background'**
  String get aiSuggestionAddDoodle;

  /// Contextual suggestion chip for emoji doodle
  ///
  /// In en, this message translates to:
  /// **'Use emoji doodle pattern'**
  String get aiSuggestionEmojiDoodle;

  /// Contextual suggestion chip for 3D frame rotation
  ///
  /// In en, this message translates to:
  /// **'Add 3D perspective tilt'**
  String get aiSuggestionAdd3DTilt;

  /// Contextual suggestion chip for transparent background
  ///
  /// In en, this message translates to:
  /// **'Make background transparent'**
  String get aiSuggestionTransparentBg;

  /// Contextual suggestion chip for landscape orientation
  ///
  /// In en, this message translates to:
  /// **'Switch to landscape mode'**
  String get aiSuggestionLandscapeMode;

  /// Section label for magnifier shape picker
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get magnifierShapeLabel;

  /// Magnifier shape option
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get magnifierShapeCircle;

  /// Magnifier shape option — rounded rectangle
  ///
  /// In en, this message translates to:
  /// **'Rounded'**
  String get magnifierShapeRounded;

  /// Magnifier shape option
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get magnifierShapeStar;

  /// Magnifier shape option
  ///
  /// In en, this message translates to:
  /// **'Hexagon'**
  String get magnifierShapeHexagon;

  /// Magnifier shape option
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get magnifierShapeDiamond;

  /// Magnifier shape option
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get magnifierShapeHeart;

  /// Label for magnifier corner radius slider
  ///
  /// In en, this message translates to:
  /// **'Corner: {value}'**
  String magnifierCorner(int value);

  /// Label for magnifier star points slider
  ///
  /// In en, this message translates to:
  /// **'Points: {value}'**
  String magnifierPoints(int value);

  /// Label for magnifier zoom level slider
  ///
  /// In en, this message translates to:
  /// **'Zoom: {value}×'**
  String magnifierZoom(String value);

  /// Label for magnifier width slider
  ///
  /// In en, this message translates to:
  /// **'Width: {value}'**
  String magnifierWidth(int value);

  /// Label for magnifier height slider
  ///
  /// In en, this message translates to:
  /// **'Height: {value}'**
  String magnifierHeight(int value);

  /// Label for magnifier border width slider
  ///
  /// In en, this message translates to:
  /// **'Border: {value}'**
  String magnifierBorder(String value);

  /// Label for magnifier source offset X slider
  ///
  /// In en, this message translates to:
  /// **'Source X: {value}'**
  String magnifierSourceX(int value);

  /// Label for magnifier source offset Y slider
  ///
  /// In en, this message translates to:
  /// **'Source Y: {value}'**
  String magnifierSourceY(int value);

  /// Label for magnifier opacity slider
  ///
  /// In en, this message translates to:
  /// **'Opacity: {value}%'**
  String magnifierOpacity(int value);

  /// Tooltip for bring-forward action on overlays
  ///
  /// In en, this message translates to:
  /// **'Bring Forward'**
  String get bringForward;

  /// Tooltip for send-backward action on overlays
  ///
  /// In en, this message translates to:
  /// **'Send Backward'**
  String get sendBackward;

  /// Tooltip when magnifier is behind frame and will move in front
  ///
  /// In en, this message translates to:
  /// **'In Front of Frame'**
  String get inFrontOfFrame;

  /// Tooltip when magnifier is in front of frame and will move behind
  ///
  /// In en, this message translates to:
  /// **'Behind Frame'**
  String get behindFrame;

  /// Subtitle in the locale picker dialog explaining rendering optimization
  ///
  /// In en, this message translates to:
  /// **'Only selected locales will be rendered'**
  String get onlySelectedLocalesWillBeRendered;

  /// Button label showing how many locales will be rendered for upload
  ///
  /// In en, this message translates to:
  /// **'Render {count} {count, plural, =1{Locale} other{Locales}}'**
  String renderNLocales(int count);

  /// Badge label for the source locale in locale picker
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// Title for the support me card in settings
  ///
  /// In en, this message translates to:
  /// **'Support the Developer'**
  String get supportTheDeveloper;

  /// Description for the support me card in settings
  ///
  /// In en, this message translates to:
  /// **'Love the app? Treat me to a coffee! {price}'**
  String supportTheDeveloperDescription(String price);

  /// Toggle title to enable or disable the CLI server
  ///
  /// In en, this message translates to:
  /// **'Enable CLI Server'**
  String get enableCliServer;

  /// Description for the CLI server toggle
  ///
  /// In en, this message translates to:
  /// **'Start the local loopback server to use the CLI tool.'**
  String get enableCliServerDescription;

  /// Button text to open the CLI documentation
  ///
  /// In en, this message translates to:
  /// **'Read Documentation'**
  String get cliLearnMoreButton;

  /// Title for the companion CLI tool section in settings
  ///
  /// In en, this message translates to:
  /// **'Command-Line Tool'**
  String get cliCompanionTitle;

  /// Description of the companion CLI tool, directing users to documentation
  ///
  /// In en, this message translates to:
  /// **'Automate screenshots from the terminal with the companion CLI tool. See the documentation for setup instructions.'**
  String get cliCompanionDescription;

  /// Settings label for the master iCloud sync toggle
  ///
  /// In en, this message translates to:
  /// **'iCloud Sync'**
  String get icloudSync;

  /// Subtitle explaining iCloud sync functionality
  ///
  /// In en, this message translates to:
  /// **'Sync designs across your devices via iCloud'**
  String get icloudSyncSubtitle;

  /// Message shown when iCloud sync is turned off
  ///
  /// In en, this message translates to:
  /// **'iCloud sync is disabled'**
  String get icloudSyncDisabled;

  /// Message telling user to restart the app after changing iCloud settings
  ///
  /// In en, this message translates to:
  /// **'Restart the app for changes to take effect'**
  String get restartRequired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'ko',
    'nl',
    'pt',
    'ru',
    'th',
    'tr',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
