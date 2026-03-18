import 'package:device_frame/src/info/info.dart';
import 'package:device_frame/src/devices/watch/device.dart' as i_watch;

/// A set of Apple Watch devices.
class WatchDevices {
  const WatchDevices();

  // Defaults
  DeviceInfo get watchS11_42mm => i_watch.s11_42mm_jetBlack;
  DeviceInfo get watchS11_46mm => i_watch.s11_46mm_jetBlack;
  DeviceInfo get watchUltra3 => i_watch.ultra3_oceanBandBlack;

  // All variants by size
  List<DeviceInfo> get all42mm => i_watch.all42mm;
  List<DeviceInfo> get all46mm => i_watch.all46mm;
  List<DeviceInfo> get allUltra3 => i_watch.allUltra3;

  /// All default devices (one per size).
  List<DeviceInfo> get all => i_watch.allDevices;
}
