part of '../asc_upload_sheet.dart';

/// iOS display type options for screenshot upload.
const _iosDisplayTypes = <String, String>{
  'APP_IPHONE_69': 'iPhone 6.9"',
  'APP_IPHONE_67': 'iPhone 6.7"',
  'APP_IPHONE_65': 'iPhone 6.5"',
  'APP_IPHONE_61': 'iPhone 6.1"',
  'APP_IPHONE_55': 'iPhone 5.5"',
  'APP_IPAD_PRO_3GEN_129': 'iPad Pro 12.9"',
  'APP_IPAD_PRO_3GEN_11': 'iPad Pro 11"',
  'APP_IPAD_105': 'iPad 10.5"',
  'APP_IPAD_97': 'iPad 9.7"',
};

/// iMessage display type options for screenshot upload.
///
/// These use the IMESSAGE_APP_ prefix required by App Store Connect.
const _iMessageDisplayTypes = <String, String>{
  'IMESSAGE_APP_IPHONE_67': 'iPhone 6.7"',
  'IMESSAGE_APP_IPHONE_65': 'iPhone 6.5"',
  'IMESSAGE_APP_IPHONE_61': 'iPhone 6.1"',
  'IMESSAGE_APP_IPHONE_58': 'iPhone 5.8"',
  'IMESSAGE_APP_IPHONE_55': 'iPhone 5.5"',
  'IMESSAGE_APP_IPHONE_47': 'iPhone 4.7"',
  'IMESSAGE_APP_IPHONE_40': 'iPhone 4.0"',
  'IMESSAGE_APP_IPAD_PRO_3GEN_129': 'iPad Pro 12.9"',
  'IMESSAGE_APP_IPAD_PRO_3GEN_11': 'iPad Pro 11"',
  'IMESSAGE_APP_IPAD_PRO_129': 'iPad Pro 12.9" (2nd)',
  'IMESSAGE_APP_IPAD_105': 'iPad 10.5"',
  'IMESSAGE_APP_IPAD_97': 'iPad 9.7"',
};

/// macOS display type options for screenshot upload.
const _macDisplayTypes = <String, String>{'APP_DESKTOP': 'Mac'};

/// watchOS display type options for screenshot upload.
const _watchDisplayTypes = <String, String>{
  'APP_WATCH_ULTRA': 'Watch Ultra',
  'APP_WATCH_SERIES_10': 'Watch Series 10',
  'APP_WATCH_SERIES_7': 'Watch Series 7',
  'APP_WATCH_SERIES_4': 'Watch Series 4',
  'APP_WATCH_SERIES_3': 'Watch Series 3',
};
