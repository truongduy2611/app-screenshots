# 📱 Simulator Screenshot Capture — Development Documentation

## Architecture

Clean Architecture with `flutter_bloc` for state management. New feature module at `lib/features/screenshot_capture/`, integrated with the existing `screenshot_editor` feature.

```
lib/features/screenshot_capture/
├── data/
│   ├── models/
│   │   ├── simulator_device.dart           # Booted simulator info (name, UDID, OS, state)
│   │   ├── capture_request.dart            # Capture parameters (UDID, bundleID, outputDir, name)
│   │   ├── capture_result.dart             # Result (path, width, height, UDID)
│   │   ├── capture_plan.dart               # Plan model (app config + steps list)
│   │   └── plan_step.dart                  # Step action enum + fields
│   └── services/
│       ├── simctl_service.dart             # xcrun simctl wrapper (list, launch, capture)
│       ├── capture_provider.dart           # Abstract capture provider interface
│       ├── simctl_capture_provider.dart    # simctl io screenshot implementation
│       └── plan_runner_service.dart        # Sequential step executor
├── presentation/
│   ├── cubit/
│   │   ├── simulator_cubit.dart            # Simulator list + selection state
│   │   ├── simulator_state.dart            # State classes
│   │   ├── capture_cubit.dart              # Single capture flow state
│   │   ├── capture_state.dart              # State classes
│   │   ├── plan_runner_cubit.dart          # Plan execution state
│   │   └── plan_runner_state.dart          # State classes
│   ├── pages/
│   │   └── capture_page.dart               # Main capture UI (simulator picker + capture button)
│   └── widgets/
│       ├── simulator_picker.dart           # Simulator dropdown with device info
│       ├── capture_preview.dart            # Captured image preview + keep/retake
│       ├── bundle_id_field.dart            # Bundle ID input field
│       ├── plan_step_tile.dart             # Individual step in plan editor
│       └── plan_progress.dart              # Execution progress indicator
└── utils/
    └── display_type_matcher.dart           # Match screenshot dimensions to ASC display types
```

---

## Key Models

### `SimulatorDevice`

Model parsed from `xcrun simctl list devices -j` JSON output.

| Field | Type | Description |
|---|---|---|
| `name` | `String` | Device name (e.g. "iPhone 16 Pro Max") |
| `udid` | `String` | Unique device identifier |
| `state` | `String` | "Booted", "Shutdown", etc. |
| `runtime` | `String` | iOS runtime identifier |
| `osVersion` | `String` | Parsed OS version (e.g. "18.2") |
| `deviceType` | `String` | Device type identifier |
| `isAvailable` | `bool` | Whether the simulator is available |

### `CaptureRequest`

| Field | Type | Description |
|---|---|---|
| `udid` | `String` | Target simulator UDID |
| `bundleId` | `String?` | Optional app to launch before capture |
| `outputDir` | `String` | Directory to write PNG |
| `name` | `String` | Output file name (without extension) |

### `CaptureResult`

| Field | Type | Description |
|---|---|---|
| `path` | `String` | Absolute path to captured PNG |
| `width` | `int` | Image width in pixels |
| `height` | `int` | Image height in pixels |
| `udid` | `String` | Simulator UDID used |
| `deviceName` | `String` | Human-readable device name |

### `CapturePlan`

JSON-compatible with the reference CLI's `.asc/screenshots.json` format.

| Field | Type | Description |
|---|---|---|
| `version` | `int` | Plan format version (always 1) |
| `app` | `PlanApp` | Bundle ID, UDID, output dir defaults |
| `defaults` | `PlanDefaults` | `postActionDelayMs` between steps |
| `steps` | `List<PlanStep>` | Ordered list of automation steps |

### `PlanStep`

| Field | Type | Description |
|---|---|---|
| `action` | `StepAction` | Enum: launch, tap, type, keySequence, wait, waitFor, screenshot |
| `name` | `String?` | Screenshot file name (for screenshot action) |
| `label` | `String?` | UI element label (for tap/waitFor) |
| `id` | `String?` | UI element accessibility ID (for tap/waitFor) |
| `text` | `String?` | Text to type (for type action) |
| `x` / `y` | `double?` | Coordinates (for tap action) |
| `durationMs` | `int?` | Wait duration (for wait action) |
| `timeoutMs` | `int?` | Polling timeout (for waitFor action) |

---

## Key Services

### `SimctlService`

Wraps `xcrun simctl` commands via `Process.run()`.

```dart
class SimctlService {
  /// Lists booted simulators.
  /// Runs: xcrun simctl list devices booted -j
  /// Parses JSON output → List<SimulatorDevice>
  Future<List<SimulatorDevice>> listBootedDevices();

  /// Lists all available simulators (booted + shutdown).
  /// Runs: xcrun simctl list devices available -j
  Future<List<SimulatorDevice>> listAllDevices();

  /// Launches an app on the specified simulator.
  /// Runs: xcrun simctl launch {udid} {bundleId}
  Future<void> launchApp(String udid, String bundleId);

  /// Captures a screenshot from the specified simulator.
  /// Runs: xcrun simctl io {udid} screenshot {outputPath}
  Future<File> captureScreenshot(String udid, String outputPath);

  /// Terminates an app on the specified simulator.
  /// Runs: xcrun simctl terminate {udid} {bundleId}
  Future<void> terminateApp(String udid, String bundleId);

  /// Checks if xcrun simctl is available in PATH.
  Future<bool> isAvailable();
}
```

### `CaptureProvider` (Abstract)

```dart
abstract class CaptureProvider {
  Future<CaptureResult> capture(CaptureRequest request);
}

/// Default provider using xcrun simctl io screenshot.
/// No external dependencies beyond Xcode CLI Tools.
class SimctlCaptureProvider implements CaptureProvider {
  final SimctlService _simctl;

  @override
  Future<CaptureResult> capture(CaptureRequest request) async {
    // 1. Optionally launch app: simctl launch
    // 2. Brief delay for app to render
    // 3. Capture: simctl io {udid} screenshot {path}
    // 4. Read image dimensions
    // 5. Return CaptureResult
  }
}
```

### `PlanRunnerService`

```dart
class PlanRunnerService {
  final SimctlService _simctl;

  /// Executes a plan step-by-step, yielding progress updates.
  Stream<PlanStepResult> runPlan(CapturePlan plan) async* {
    for (final (index, step) in plan.steps.indexed) {
      yield PlanStepResult(index: index, action: step.action, status: StepStatus.running);

      switch (step.action) {
        case StepAction.launch:
          await _simctl.launchApp(plan.app.udid, plan.app.bundleId);
        case StepAction.tap:
          // Requires AXe CLI: axe tap --label {label} --udid {udid}
          await _runExternal('axe', ['tap', '--label', step.label!, '--udid', plan.app.udid]);
        case StepAction.wait:
          await Future.delayed(Duration(milliseconds: step.durationMs!));
        case StepAction.screenshot:
          await _simctl.captureScreenshot(plan.app.udid, '${plan.app.outputDir}/${step.name}.png');
        // ... other actions
      }

      yield PlanStepResult(index: index, action: step.action, status: StepStatus.completed);

      if (plan.defaults.postActionDelayMs > 0 && step.action != StepAction.wait) {
        await Future.delayed(Duration(milliseconds: plan.defaults.postActionDelayMs));
      }
    }
  }
}
```

---

## Key Cubits

### `SimulatorCubit`

Manages the simulator list and selected device.

| Method | Description |
|---|---|
| `loadDevices()` | Calls `simctl list devices booted -j`, parses JSON |
| `selectDevice(udid)` | Sets the active simulator |
| `refreshDevices()` | Re-fetches the device list |

**State:**
```dart
sealed class SimulatorState {
  const SimulatorState();
}
class SimulatorInitial extends SimulatorState {}
class SimulatorLoading extends SimulatorState {}
class SimulatorLoaded extends SimulatorState {
  final List<SimulatorDevice> devices;
  final SimulatorDevice? selected;
}
class SimulatorError extends SimulatorState {
  final String message; // e.g. "xcrun not found"
}
```

### `CaptureCubit`

Manages the single-capture workflow.

| Method | Description |
|---|---|
| `capture(request)` | Runs capture, manages preview state |
| `keepCapture()` | Imports captured image into editor |
| `retake()` | Discards capture, resets to ready state |
| `launchApp(udid, bundleId)` | Launches app before capture |

**State:**
```dart
sealed class CaptureState {
  const CaptureState();
}
class CaptureReady extends CaptureState {}
class CaptureInProgress extends CaptureState {}
class CapturePreview extends CaptureState {
  final CaptureResult result;
}
class CaptureError extends CaptureState {
  final String message;
}
```

---

## Integration with Existing Feature

### Import Captured Screenshots to Editor

After a successful capture, the image is imported into the existing `MultiScreenshotCubit`:

```dart
// In CaptureCubit.keepCapture():
void keepCapture() {
  final result = (state as CapturePreview).result;
  final file = File(result.path);

  // Import into multi-screenshot editor via the existing mechanism
  multiScreenshotCubit.addDesignFromImage(file);

  emit(CaptureReady());
}
```

### Entry Points

1. **Toolbar button** in `MultiScreenshotPage` — "Capture from Simulator" opens `CapturePage` as a dialog/sheet
2. **Add Screenshot Placeholder** — option to "Capture from Simulator" alongside "Import Image"
3. **Standalone page** (future) — accessible from the main navigation for batch capture workflows

---

## simctl JSON Output Parsing

`xcrun simctl list devices -j` returns:

```json
{
  "devices": {
    "com.apple.CoreSimulator.SimRuntime.iOS-18-2": [
      {
        "name": "iPhone 16 Pro Max",
        "udid": "A1B2C3D4-E5F6-7890-ABCD-EF1234567890",
        "state": "Booted",
        "isAvailable": true,
        "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro-Max"
      }
    ]
  }
}
```

The `SimctlService` parses this by iterating over runtime keys, extracting the OS version from the runtime identifier, and flattening all devices into a single list.

---

## Capture Command Details

### Single Capture
```bash
# Screenshot from booted simulator
xcrun simctl io {udid} screenshot {output_path.png}

# With app launch first
xcrun simctl launch {udid} {bundle_id}
sleep 2  # wait for app to render
xcrun simctl io {udid} screenshot {output_path.png}
```

### Automation Steps (requires AXe)
```bash
# Launch app
xcrun simctl launch {udid} {bundle_id}

# Tap by label
axe tap --label "Settings" --udid {udid}

# Type text
axe type "Hello World" --udid {udid}

# Wait for element
axe describe-ui --udid {udid}  # poll + parse JSON for element
```

---

## Image Dimension Reading

After capture, read dimensions using the `image` package (already a dependency):

```dart
Future<(int width, int height)> readImageDimensions(String path) async {
  final bytes = await File(path).readAsBytes();
  final image = img.decodeImage(bytes);
  return (image!.width, image.height);
}
```

---

## Display Type Matching

Match captured dimensions to App Store Connect display types:

| Display Type | Width × Height |
|---|---|
| `APP_IPHONE_69` | 1320 × 2868 |
| `APP_IPHONE_67` | 1290 × 2796 |
| `APP_IPHONE_61` | 1179 × 2556 |
| `APP_IPHONE_55` | 1242 × 2208 |
| `APP_DESKTOP` | 2880 × 1800 |

> **Note:** Simulator screenshots are captured at device resolution. After framing, the final output must match these exact dimensions.

---

## Error Handling

| Error | Handling |
|---|---|
| `xcrun` not in PATH | Show "Install Xcode Command Line Tools" message |
| No booted simulators | Show empty state with "Open Simulator" shortcut |
| `simctl launch` fails | Show error with bundle ID validation hint |
| Capture timeout | Cancel after 30s, show retry option |
| Image file not found | Show "Capture failed" with retry option |
| Plan step failure | Stop execution, highlight failed step, preserve prior captures |

---

## Dependencies

| Package | Purpose | Status |
|---|---|---|
| `image` | Read captured image dimensions | ✅ Already in project |
| `path_provider` | Output directory for captures | ✅ Already in project |
| `flutter_bloc` | State management for cubits | ✅ Already in project |
| `file_picker` | Select plan JSON files | ✅ Already in project |

> No new dependencies required for The feature uses `Process.run()` from `dart:io` to shell out to `xcrun simctl`.

---

## Test Strategy

### Unit Tests

| Test | What to Test |
|---|---|
| `SimctlService` | JSON parsing of `simctl list devices` output, edge cases (empty, no booted) |
| `SimulatorDevice` | Model serialization/deserialization |
| `CaptureRequest` / `CaptureResult` | Validation logic |
| `CapturePlan` | JSON parse + validate (compatible with CLI format) |
| `PlanStep` | Action enum mapping, required field validation |

### Integration Tests

| Test | What to Test |
|---|---|
| `SimulatorCubit` | State transitions: initial → loading → loaded/error |
| `CaptureCubit` | State transitions: ready → inProgress → preview → ready |
| Import to editor | Captured file appears as new design entry in `MultiScreenshotCubit` |

### Manual Verification

1. Boot an iPhone 16 Pro Max simulator → open capture page → verify device appears
2. Capture a screenshot → verify PNG saved and dimensions match device
3. Keep the capture → verify it appears in the multi-screenshot editor
4. Enter invalid bundle ID → verify error message shown
5. Run with no Xcode CLI tools → verify helpful error message


