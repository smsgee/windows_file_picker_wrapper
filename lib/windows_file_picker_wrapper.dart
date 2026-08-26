/// A rock-solid, deadlock-free native Windows 10/11 File and Folder Picker for Flutter desktop.
library windows_file_picker_wrapper;

import 'dart:convert';
import 'dart:io';

/// Pre-configured file type filters for [WindowsFilePickerWrapper].
enum WindowsFileType {
  /// All files (*.*)
  any,

  /// Common image file formats (jpg, png, webp, bmp, gif, avif, heic, tiff, raw)
  image,

  /// Common video file formats (mp4, mov, avi, mkv, webm, flv, wmv)
  video,

  /// Common audio file formats (mp3, wav, aac, flac, ogg, m4a, wma)
  audio,

  /// Common media files (images + videos)
  media,

  /// Custom file extensions provided via `allowedExtensions`
  custom,
}

/// A rock-solid, deadlock-free native Windows 10/11 File and Folder Picker for Flutter desktop.
///
/// Spawns native Windows Explorer modal dialogs in an isolated STA sub-process.
/// This completely eliminates in-process COM apartment deadlocks, DirectX/Impeller
/// Z-order foreground locks, and platform thread message pump freezes.
class WindowsFilePickerWrapper {
  /// Private constructor to prevent direct instantiation of utility class.
  const WindowsFilePickerWrapper._();

  /// Opens the modern Windows 10/11 File Explorer Folder Dialog (`IFileOpenDialog` with `FOS_PICKFOLDERS`).
  ///
  /// Returns the absolute path of the selected folder, or `null` if cancelled.
  static Future<String?> pickFolder({
    String? title,
    String? initialDirectory,
  }) async {
    if (!Platform.isWindows) {
      return null;
    }

    final sanitizedTitle = (title ?? 'Select Folder').replaceAll('"', '`"');
    final sanitizedInitDir = (initialDirectory ?? '').replaceAll('"', '`"');

    final script = '''
\$code = @"
using System;
using System.Runtime.InteropServices;

[ComImport, Guid("d57c7288-d4ad-4768-be02-9d969532d960"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IFileOpenDialog {
    [PreserveSig] int Show(IntPtr parent);
    void SetFileTypes();
    void SetFileTypeIndex();
    void GetFileTypeIndex();
    void Advise();
    void Unadvise();
    void SetOptions(uint fos);
    void GetOptions(out uint fos);
    void SetDefaultFolder(IShellItem psi);
    void SetFolder(IShellItem psi);
    void GetFolder(out IShellItem ppsi);
    void GetCurrentSelection(out IShellItem ppsi);
    void SetFileName([MarshalAs(UnmanagedType.LPWStr)] string pszName);
    void GetFileName([MarshalAs(UnmanagedType.LPWStr)] out string pszName);
    void SetTitle([MarshalAs(UnmanagedType.LPWStr)] string pszTitle);
    void SetOkButtonLabel([MarshalAs(UnmanagedType.LPWStr)] string pszText);
    void SetFileNameLabel([MarshalAs(UnmanagedType.LPWStr)] string pszLabel);
    void GetResult(out IShellItem ppsi);
}

[ComImport, Guid("43826d1e-e718-42ee-bc55-a1e261c37bfe"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IShellItem {
    void BindToHandler(IntPtr pbc, ref Guid bhid, ref Guid riid, out IntPtr ppv);
    void GetParent(out IShellItem ppsi);
    void GetDisplayName(uint sigdnName, [MarshalAs(UnmanagedType.LPWStr)] out string ppszName);
    void GetAttributes(uint sfgaoMask, out uint psfgaoAttribs);
    void Compare(IShellItem psi, uint hint, out int piOrder);
}

[ComImport, Guid("DC1C5A9C-E88A-4dde-A5A1-60F82A20AEF7"), ClassInterface(ClassInterfaceType.None)]
public class FileOpenDialogRCW {}

public class ModernFolderPicker {
    [DllImport("shell32.dll", CharSet = CharSet.Unicode, PreserveSig = false)]
    private static extern void SHCreateItemFromParsingName(
        [MarshalAs(UnmanagedType.LPWStr)] string pszPath,
        IntPtr pbc,
        [MarshalAs(UnmanagedType.LPStruct)] Guid riid,
        out IShellItem ppv);

    public static string Pick(string title, string initialDir) {
        var dialog = (IFileOpenDialog)new FileOpenDialogRCW();
        uint options;
        dialog.GetOptions(out options);
        dialog.SetOptions(options | 0x20 | 0x40);
        if (!string.IsNullOrEmpty(title)) {
            dialog.SetTitle(title);
        }
        if (!string.IsNullOrEmpty(initialDir) && System.IO.Directory.Exists(initialDir)) {
            try {
                IShellItem folderItem;
                Guid iidShellItem = new Guid("43826d1e-e718-42ee-bc55-a1e261c37bfe");
                SHCreateItemFromParsingName(initialDir, IntPtr.Zero, iidShellItem, out folderItem);
                if (folderItem != null) {
                    dialog.SetFolder(folderItem);
                }
            } catch {}
        }
        int hr = dialog.Show(IntPtr.Zero);
        if (hr == 0) {
            IShellItem result;
            dialog.GetResult(out result);
            string path;
            result.GetDisplayName(0x80058000, out path);
            return path;
        }
        return null;
    }
}
"@
Add-Type -TypeDefinition \$code -IgnoreWarnings
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
\$picked = [ModernFolderPicker]::Pick("$sanitizedTitle", "$sanitizedInitDir")
if (\$picked) {
  Write-Output \$picked
}
''';

    try {
      final result = await Process.run(
        'powershell',
        ['-NoProfile', '-STA', '-Command', script],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode == 0) {
        final path = result.stdout.toString().trim();
        if (path.isNotEmpty && Directory(path).existsSync()) {
          return path;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Opens the modern Windows 10/11 File Explorer Open File Dialog.
  ///
  /// Set [allowMultiple] to `true` to allow selecting multiple files.
  /// Returns a list of absolute file paths, or `null` if cancelled.
  static Future<List<String>?> pickFiles({
    String? title,
    String? initialDirectory,
    WindowsFileType type = WindowsFileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    if (!Platform.isWindows) {
      return null;
    }

    final sanitizedTitle = (title ?? (allowMultiple ? 'Select Files' : 'Select File'))
        .replaceAll('"', '`"');
    final sanitizedInitDir = (initialDirectory ?? '').replaceAll('"', '`"');
    final filter = _buildWindowsFilter(type: type, allowedExtensions: allowedExtensions);

    final script = '''
Add-Type -AssemblyName System.Windows.Forms
\$dialog = New-Object System.Windows.Forms.OpenFileDialog
\$dialog.Title = "$sanitizedTitle"
\$dialog.Multiselect = ${allowMultiple ? '\$true' : '\$false'}
\$dialog.Filter = "$filter"
\$dialog.AutoUpgradeEnabled = \$true
if ("$sanitizedInitDir" -ne "" -and (Test-Path "$sanitizedInitDir")) {
  \$dialog.InitialDirectory = "$sanitizedInitDir"
}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if (\$dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  foreach (\$file in \$dialog.FileNames) {
    Write-Output \$file
  }
}
''';

    try {
      final result = await Process.run(
        'powershell',
        ['-NoProfile', '-STA', '-Command', script],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        if (output.isNotEmpty) {
          final lines = const LineSplitter().convert(output);
          final validPaths = <String>[];
          for (final line in lines) {
            final path = line.trim();
            if (path.isNotEmpty && File(path).existsSync()) {
              validPaths.add(path);
            }
          }
          if (validPaths.isNotEmpty) {
            return validPaths;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Opens the modern Windows 10/11 File Explorer Open File Dialog for a single file.
  ///
  /// Returns the selected absolute file path, or `null` if cancelled.
  static Future<String?> pickFile({
    String? title,
    String? initialDirectory,
    WindowsFileType type = WindowsFileType.any,
    List<String>? allowedExtensions,
  }) async {
    final files = await pickFiles(
      title: title,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
      allowMultiple: false,
    );
    return files != null && files.isNotEmpty ? files.first : null;
  }

  /// Opens the modern Windows 10/11 File Explorer Save File Dialog.
  ///
  /// Returns the target save file path, or `null` if cancelled.
  static Future<String?> saveFile({
    String? title,
    String? fileName,
    String? initialDirectory,
    WindowsFileType type = WindowsFileType.any,
    List<String>? allowedExtensions,
  }) async {
    if (!Platform.isWindows) {
      return null;
    }

    final sanitizedTitle = (title ?? 'Save File').replaceAll('"', '`"');
    final sanitizedInitDir = (initialDirectory ?? '').replaceAll('"', '`"');
    final sanitizedFileName = (fileName ?? '').replaceAll('"', '`"');
    final filter = _buildWindowsFilter(type: type, allowedExtensions: allowedExtensions);

    final script = '''
Add-Type -AssemblyName System.Windows.Forms
\$dialog = New-Object System.Windows.Forms.SaveFileDialog
\$dialog.Title = "$sanitizedTitle"
\$dialog.Filter = "$filter"
\$dialog.AutoUpgradeEnabled = \$true
if ("$sanitizedFileName" -ne "") {
  \$dialog.FileName = "$sanitizedFileName"
}
if ("$sanitizedInitDir" -ne "" -and (Test-Path "$sanitizedInitDir")) {
  \$dialog.InitialDirectory = "$sanitizedInitDir"
}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if (\$dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  Write-Output \$dialog.FileName
}
''';

    try {
      final result = await Process.run(
        'powershell',
        ['-NoProfile', '-STA', '-Command', script],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode == 0) {
        final path = result.stdout.toString().trim();
        if (path.isNotEmpty) {
          return path;
        }
      }
    } catch (_) {}
    return null;
  }

  static String _buildWindowsFilter({
    WindowsFileType type = WindowsFileType.any,
    List<String>? allowedExtensions,
  }) {
    if (type == WindowsFileType.custom && allowedExtensions != null && allowedExtensions.isNotEmpty) {
      final patterns = allowedExtensions
          .map((e) => '*.${e.startsWith('.') ? e.substring(1).toLowerCase() : e.toLowerCase()}')
          .join(';');
      return 'Supported Files ($patterns)|$patterns|All Files (*.*)|*.*';
    }
    if (type == WindowsFileType.image) {
      const imgPatterns =
          '*.jpg;*.jpeg;*.png;*.webp;*.bmp;*.gif;*.avif;*.heic;*.tiff;*.tif;*.arw;*.cr2;*.cr3;*.nef;*.rw2;*.orf;*.raf;*.rwl;*.dng';
      return 'Image Files ($imgPatterns)|$imgPatterns|All Files (*.*)|*.*';
    }
    if (type == WindowsFileType.video) {
      const vidPatterns = '*.mp4;*.mov;*.avi;*.mkv;*.webm;*.flv;*.wmv';
      return 'Video Files ($vidPatterns)|$vidPatterns|All Files (*.*)|*.*';
    }
    if (type == WindowsFileType.audio) {
      const audPatterns = '*.mp3;*.wav;*.aac;*.flac;*.ogg;*.m4a;*.wma';
      return 'Audio Files ($audPatterns)|$audPatterns|All Files (*.*)|*.*';
    }
    if (type == WindowsFileType.media) {
      const medPatterns =
          '*.jpg;*.jpeg;*.png;*.webp;*.bmp;*.gif;*.avif;*.heic;*.tiff;*.mp4;*.mov;*.avi;*.mkv;*.webm';
      return 'Media Files ($medPatterns)|$medPatterns|All Files (*.*)|*.*';
    }
    return 'All Files (*.*)|*.*';
  }
}
