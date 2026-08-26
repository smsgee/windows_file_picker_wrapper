# windows_file_picker_wrapper

A rock-solid, deadlock-free native **Windows 10/11 File and Folder Picker** for Flutter Desktop applications.

---

## Why this package?

Existing Flutter Windows picker plugins (`file_picker`, `file_selector_windows`) invoke the synchronous Win32 `IFileDialog::Show(HWND)` API directly on Flutter's platform thread. This leads to well-known bugs on Windows:
- **Focus Drop / Hidden Dialogs**: On repeated calls, Windows places the dialog *behind* the active DirectX/OpenGL rendering window.
- **COM Deadlocks**: Cross-apartment proxy contention with background workers / DirectML / ONNX runtimes freezes the main message loop.
- **Main Thread UI Freezes**: The Flutter UI thread locks up while the modal dialog is open.

`windows_file_picker_wrapper` solves this by spawning native Windows 10/11 Explorer dialogs in an **isolated native Windows subprocess** (`-STA`).

### Benefits:
- **100% Native Windows 10/11 UI**: Uses the modern `IFileOpenDialog` (FOS_PICKFOLDERS), `OpenFileDialog`, and `SaveFileDialog`.
- **Always in Foreground**: Windows OS gives top-level foreground focus to the dialog window automatically.
- **Non-blocking**: Flutter UI keeps rendering smoothly at 60/120 FPS.
- **100% Reliable**: Open/close pickers 1,000 times consecutively without a single hang or freeze.

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  windows_file_picker_wrapper: ^1.0.1
```

---

## Usage

### 1. Modern Folder Picker
```dart
import 'package:windows_file_picker_wrapper/windows_file_picker_wrapper.dart';

final String? folderPath = await WindowsFilePickerWrapper.pickFolder(
  title: 'Select Image Directory',
  initialDirectory: r'C:\Photos',
);
```

### 2. Multi-File Picker
```dart
final List<String>? files = await WindowsFilePickerWrapper.pickFiles(
  title: 'Select Images',
  type: WindowsFileType.image,
  allowMultiple: true,
);
```

### 3. Single File Picker
```dart
final String? filePath = await WindowsFilePickerWrapper.pickFile(
  title: 'Select Document',
  type: WindowsFileType.custom,
  allowedExtensions: ['pdf', 'docx', 'xlsx'],
);
```

### 4. Save File Dialog
```dart
final String? savePath = await WindowsFilePickerWrapper.saveFile(
  title: 'Save Backup',
  fileName: 'backup_2026.json',
  allowedExtensions: ['json'],
);
```

---

## Example App
See the [example](example) directory for a complete iOS Cupertino-styled demo application.

---

## License
MIT License
