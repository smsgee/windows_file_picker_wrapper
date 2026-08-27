// ignore_for_file: non_constant_identifier_names, constant_identifier_names, unnecessary_library_name, unused_element, camel_case_types
/// A rock-solid, high-performance native Windows File and Folder Picker for Flutter desktop.
/// Uses modern Windows 10/11 COM Common Item Dialogs (IFileOpenDialog / IFileSaveDialog)
/// and classic Win32 APIs via dart:ffi in worker isolates for instantaneous response.
library windows_file_picker_wrapper;

import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

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

// ─── Win32 Structs and COM Signatures ────────────────────────────────────────

final class _GUID extends ffi.Struct {
  @ffi.Uint32()
  external int Data1;
  @ffi.Uint16()
  external int Data2;
  @ffi.Uint16()
  external int Data3;
  @ffi.Array(8)
  external ffi.Array<ffi.Uint8> Data4;
}

final class _COMDLG_FILTERSPEC extends ffi.Struct {
  external ffi.Pointer<Utf16> pszName;
  external ffi.Pointer<Utf16> pszSpec;
}

final class _BROWSEINFOW extends ffi.Struct {
  @ffi.IntPtr()
  external int hwndOwner;
  @ffi.IntPtr()
  external int pidlRoot;
  external ffi.Pointer<Utf16> pszDisplayName;
  external ffi.Pointer<Utf16> lpszTitle;
  @ffi.Uint32()
  external int ulFlags;
  @ffi.IntPtr()
  external int lpfn;
  @ffi.IntPtr()
  external int lParam;
  @ffi.Int32()
  external int iImage;
}

final class _OPENFILENAMEW extends ffi.Struct {
  @ffi.Uint32()
  external int lStructSize;
  @ffi.IntPtr()
  external int hwndOwner;
  @ffi.IntPtr()
  external int hInstance;
  external ffi.Pointer<Utf16> lpstrFilter;
  external ffi.Pointer<Utf16> lpstrCustomFilter;
  @ffi.Uint32()
  external int nMaxCustFilter;
  @ffi.Uint32()
  external int nFilterIndex;
  external ffi.Pointer<Utf16> lpstrFile;
  @ffi.Uint32()
  external int nMaxFile;
  external ffi.Pointer<Utf16> lpstrFileTitle;
  @ffi.Uint32()
  external int nMaxFileTitle;
  external ffi.Pointer<Utf16> lpstrInitialDir;
  external ffi.Pointer<Utf16> lpstrTitle;
  @ffi.Uint32()
  external int Flags;
  @ffi.Uint16()
  external int nFileOffset;
  @ffi.Uint16()
  external int nFileExtension;
  external ffi.Pointer<Utf16> lpstrDefExt;
  @ffi.IntPtr()
  external int lCustData;
  @ffi.IntPtr()
  external int lpfnHook;
  external ffi.Pointer<Utf16> lpTemplateName;
  @ffi.IntPtr()
  external int pvReserved;
  @ffi.Uint32()
  external int dwReserved;
  @ffi.Uint32()
  external int FlagsEx;
}

// ─── Native Function Typedefs ───────────────────────────────────────────────

typedef _CoInitializeExNative = ffi.Int32 Function(ffi.Pointer, ffi.Uint32);
typedef _CoInitializeExDart = int Function(ffi.Pointer, int);

typedef _CoUninitializeNative = ffi.Void Function();
typedef _CoUninitializeDart = void Function();

typedef _CoCreateInstanceNative = ffi.Int32 Function(
  ffi.Pointer<_GUID>,
  ffi.Pointer,
  ffi.Uint32,
  ffi.Pointer<_GUID>,
  ffi.Pointer<ffi.Pointer>,
);
typedef _CoCreateInstanceDart = int Function(
  ffi.Pointer<_GUID>,
  ffi.Pointer,
  int,
  ffi.Pointer<_GUID>,
  ffi.Pointer<ffi.Pointer>,
);

typedef _CoTaskMemFreeNative = ffi.Void Function(ffi.IntPtr);
typedef _CoTaskMemFreeDart = void Function(int);

typedef _SHCreateItemFromParsingNameNative = ffi.Int32 Function(
  ffi.Pointer<Utf16>,
  ffi.Pointer,
  ffi.Pointer<_GUID>,
  ffi.Pointer<ffi.Pointer>,
);
typedef _SHCreateItemFromParsingNameDart = int Function(
  ffi.Pointer<Utf16>,
  ffi.Pointer,
  ffi.Pointer<_GUID>,
  ffi.Pointer<ffi.Pointer>,
);

typedef _SHBrowseForFolderWNative = ffi.IntPtr Function(ffi.Pointer<_BROWSEINFOW>);
typedef _SHBrowseForFolderWDart = int Function(ffi.Pointer<_BROWSEINFOW>);
typedef _SHGetPathFromIDListWNative = ffi.Int32 Function(ffi.IntPtr, ffi.Pointer<Utf16>);
typedef _SHGetPathFromIDListWDart = int Function(int, ffi.Pointer<Utf16>);

typedef _GetOpenFileNameWNative = ffi.Int32 Function(ffi.Pointer<_OPENFILENAMEW>);
typedef _GetOpenFileNameWDart = int Function(ffi.Pointer<_OPENFILENAMEW>);
typedef _GetSaveFileNameWNative = ffi.Int32 Function(ffi.Pointer<_OPENFILENAMEW>);
typedef _GetSaveFileNameWDart = int Function(ffi.Pointer<_OPENFILENAMEW>);

// ─── COM Constants ──────────────────────────────────────────────────────────

const int _COINIT_APARTMENTTHREADED = 0x2;
const int _COINIT_DISABLE_OLE1DDE = 0x4;
const int _CLSCTX_INPROC_SERVER = 0x1;
const int _S_OK = 0;

const int _FOS_OVERWRITEPROMPT = 0x00000002;
const int _FOS_NOCHANGEDIR = 0x00000008;
const int _FOS_PICKFOLDERS = 0x00000020;
const int _FOS_FORCEFILESYSTEM = 0x00000040;
const int _FOS_ALLOWMULTISELECT = 0x00000200;
const int _FOS_PATHMUSTEXIST = 0x00000800;
const int _FOS_FILEMUSTEXIST = 0x00001000;

const int _SIGDN_FILESYSPATH = 0x80058000;

// Win32 Classic Constants
const int _OFN_ALLOWMULTISELECT = 0x00000200;
const int _OFN_PATHMUSTEXIST = 0x00000800;
const int _OFN_FILEMUSTEXIST = 0x00001000;
const int _OFN_EXPLORER = 0x00080000;
const int _OFN_NOCHANGEDIR = 0x00000008;
const int _OFN_OVERWRITEPROMPT = 0x00000002;
const int _OFN_ENABLESIZING = 0x00800000;

const int _BIF_RETURNONLYFSDIRS = 0x00000001;
const int _BIF_NEWDIALOGSTYLE = 0x00000040;
const int _BIF_USENEWUI = _BIF_NEWDIALOGSTYLE | 0x00000080;

/// A high-performance native Windows File and Folder Picker for Flutter desktop.
class WindowsFilePickerWrapper {
  const WindowsFilePickerWrapper._();

  /// Opens the modern Windows 10/11 Open File Dialog (IFileOpenDialog).
  ///
  /// Supports single or multiple file selections, pre-configured file type filters,
  /// and custom allowed extensions. Runs asynchronously in a worker isolate.
  static Future<List<String>?> pickFiles({
    String? title,
    String? initialDirectory,
    WindowsFileType type = WindowsFileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    if (!Platform.isWindows) return null;

    return compute(_nativePickFilesComInternal, _PickParams(
      title: title ?? (allowMultiple ? 'Select Files' : 'Select File'),
      initialDirectory: initialDirectory ?? '',
      type: type,
      allowedExtensions: allowedExtensions,
      allowMultiple: allowMultiple,
    ));
  }

  /// Opens the modern Windows 10/11 Open File Dialog for a single file.
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

  /// Opens the modern Windows 10/11 Save File Dialog (IFileSaveDialog).
  static Future<String?> saveFile({
    String? title,
    String? fileName,
    String? initialDirectory,
    WindowsFileType type = WindowsFileType.any,
    List<String>? allowedExtensions,
  }) async {
    if (!Platform.isWindows) return null;

    return compute(_nativeSaveFileComInternal, _PickParams(
      title: title ?? 'Save File',
      fileName: fileName ?? '',
      initialDirectory: initialDirectory ?? '',
      type: type,
      allowedExtensions: allowedExtensions,
      allowMultiple: false,
    ));
  }

  /// Opens the modern Windows 10/11 Explorer-style Folder Dialog (IFileOpenDialog with FOS_PICKFOLDERS).
  ///
  /// Provides the sleek modern Windows 10/11 folder selection interface with
  /// Explorer navigation, breadcrumbs, search, and "Select Folder" button.
  static Future<String?> pickModernFolder({
    String? title,
    String? initialDirectory,
  }) async {
    if (!Platform.isWindows) return null;

    return compute(_nativePickModernFolderInternal, _FolderParams(
      title: title ?? 'Select Folder',
      initialDirectory: initialDirectory ?? '',
    ));
  }

  /// Opens the classic Win32 Tree-view Folder Dialog (SHBrowseForFolderW).
  ///
  /// Preserved for backward compatibility and lightweight tree-view workflows.
  static Future<String?> pickClassicFolder({
    String? title,
    String? initialDirectory,
  }) async {
    if (!Platform.isWindows) return null;

    return compute(_nativePickClassicFolderInternal, _FolderParams(
      title: title ?? 'Select Folder',
      initialDirectory: initialDirectory ?? '',
    ));
  }

  /// Universal folder picker. Defaults to the modern Windows 10/11 Explorer dialog ([useModern] = true).
  /// Set [useModern] to false to invoke the classic tree-view folder dialog.
  static Future<String?> pickFolder({
    String? title,
    String? initialDirectory,
    bool useModern = true,
  }) async {
    if (useModern) {
      return pickModernFolder(
        title: title,
        initialDirectory: initialDirectory,
      );
    } else {
      return pickClassicFolder(
        title: title,
        initialDirectory: initialDirectory,
      );
    }
  }
}

// ─── Worker Isolate Parameter Objects ───────────────────────────────────────

class _PickParams {
  const _PickParams({
    required this.title,
    this.fileName = '',
    required this.initialDirectory,
    this.type = WindowsFileType.any,
    this.allowedExtensions,
    required this.allowMultiple,
  });
  final String title;
  final String fileName;
  final String initialDirectory;
  final WindowsFileType type;
  final List<String>? allowedExtensions;
  final bool allowMultiple;
}

class _FolderParams {
  const _FolderParams({
    required this.title,
    required this.initialDirectory,
  });
  final String title;
  final String initialDirectory;
}

// ─── COM Helper Functions ───────────────────────────────────────────────────

void _initGuid(ffi.Pointer<_GUID> guid, int d1, int d2, int d3, List<int> d4) {
  guid.ref.Data1 = d1;
  guid.ref.Data2 = d2;
  guid.ref.Data3 = d3;
  for (int i = 0; i < 8; i++) {
    guid.ref.Data4[i] = d4[i];
  }
}

// CLSID_FileOpenDialog: DC1C5A9C-E88A-4DDE-A5A1-60F82A20AEF7
void _initClsidFileOpenDialog(ffi.Pointer<_GUID> guid) =>
    _initGuid(guid, 0xDC1C5A9C, 0xE88A, 0x4DDE, [0xA5, 0xA1, 0x60, 0xF8, 0x2A, 0x20, 0xAE, 0xF7]);

// IID_IFileOpenDialog: D57C7288-D4AD-4768-BE02-9D969532D960
void _initIidIFileOpenDialog(ffi.Pointer<_GUID> guid) =>
    _initGuid(guid, 0xD57C7288, 0xD4AD, 0x4768, [0xBE, 0x02, 0x9D, 0x96, 0x95, 0x32, 0xD9, 0x60]);

// CLSID_FileSaveDialog: C0B4E2F3-BA21-4773-8DBA-335EC946EB8B
void _initClsidFileSaveDialog(ffi.Pointer<_GUID> guid) =>
    _initGuid(guid, 0xC0B4E2F3, 0xBA21, 0x4773, [0x8D, 0xBA, 0x33, 0x5E, 0xC9, 0x46, 0xEB, 0x8B]);

// IID_IFileSaveDialog: 84BCC23-5FDE-4CDB-AEA4-AF64B83D78AB
void _initIidIFileSaveDialog(ffi.Pointer<_GUID> guid) =>
    _initGuid(guid, 0x84BCC23, 0x5FDE, 0x4CDB, [0xAE, 0xA4, 0xAF, 0x64, 0xB8, 0x3D, 0x78, 0xAB]);

// IID_IShellItem: 43826D1E-E718-42EE-BC55-A1E261C37BFE
void _initIidIShellItem(ffi.Pointer<_GUID> guid) =>
    _initGuid(guid, 0x43826D1E, 0xE718, 0x42EE, [0xBC, 0x55, 0xA1, 0xE2, 0x61, 0xC3, 0x7B, 0xFE]);

ffi.Pointer<ffi.NativeFunction<N>> _getVTableFunc<N extends Function>(ffi.Pointer pObj, int index) {
  final vtable = pObj.cast<ffi.Pointer<ffi.IntPtr>>().value;
  final funcAddress = (vtable + index).value;
  return ffi.Pointer<ffi.NativeFunction<N>>.fromAddress(funcAddress);
}

// ─── Modern COM Folder Picker Worker Implementation ─────────────────────────

String? _nativePickModernFolderInternal(_FolderParams params) {
  final ole32 = ffi.DynamicLibrary.open('ole32.dll');
  final shell32 = ffi.DynamicLibrary.open('shell32.dll');

  final coInitializeEx = ole32.lookupFunction<_CoInitializeExNative, _CoInitializeExDart>('CoInitializeEx');
  final coUninitialize = ole32.lookupFunction<_CoUninitializeNative, _CoUninitializeDart>('CoUninitialize');
  final coCreateInstance = ole32.lookupFunction<_CoCreateInstanceNative, _CoCreateInstanceDart>('CoCreateInstance');
  final coTaskMemFree = ole32.lookupFunction<_CoTaskMemFreeNative, _CoTaskMemFreeDart>('CoTaskMemFree');
  final shCreateItem = shell32.lookupFunction<_SHCreateItemFromParsingNameNative, _SHCreateItemFromParsingNameDart>('SHCreateItemFromParsingName');

  coInitializeEx(ffi.nullptr, _COINIT_APARTMENTTHREADED | _COINIT_DISABLE_OLE1DDE);

  String? selectedPath;
  final clsid = calloc<_GUID>();
  final iid = calloc<_GUID>();
  final iidShellItem = calloc<_GUID>();
  final ppDialog = calloc<ffi.Pointer>();

  try {
    _initClsidFileOpenDialog(clsid);
    _initIidIFileOpenDialog(iid);
    _initIidIShellItem(iidShellItem);

    final hrCreate = coCreateInstance(clsid, ffi.nullptr, _CLSCTX_INPROC_SERVER, iid, ppDialog);
    if (hrCreate != _S_OK || ppDialog.value == ffi.nullptr) {
      // Fallback to classic folder picker if COM creation failed
      return _nativePickClassicFolderInternal(params);
    }

    final pDialog = ppDialog.value;

    // VTable functions for IFileDialog / IFileOpenDialog
    final releaseFunc = _getVTableFunc<ffi.Uint32 Function(ffi.Pointer)>(pDialog, 2).asFunction<int Function(ffi.Pointer)>();
    final showFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.IntPtr)>(pDialog, 3).asFunction<int Function(ffi.Pointer, int)>();
    final setOptionsFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Uint32)>(pDialog, 9).asFunction<int Function(ffi.Pointer, int)>();
    final getOptionsFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Pointer<ffi.Uint32>)>(pDialog, 10).asFunction<int Function(ffi.Pointer, ffi.Pointer<ffi.Uint32>)>();
    final setFolderFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Pointer)>(pDialog, 12).asFunction<int Function(ffi.Pointer, ffi.Pointer)>();
    final setTitleFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Pointer<Utf16>)>(pDialog, 17).asFunction<int Function(ffi.Pointer, ffi.Pointer<Utf16>)>();
    final getResultFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Pointer<ffi.Pointer>)>(pDialog, 20).asFunction<int Function(ffi.Pointer, ffi.Pointer<ffi.Pointer>)>();

    // Set folder picking options
    final pOptions = calloc<ffi.Uint32>();
    getOptionsFunc(pDialog, pOptions);
    final options = pOptions.value | _FOS_PICKFOLDERS | _FOS_FORCEFILESYSTEM | _FOS_PATHMUSTEXIST;
    setOptionsFunc(pDialog, options);
    calloc.free(pOptions);

    // Set Title
    final pTitle = params.title.toNativeUtf16();
    setTitleFunc(pDialog, pTitle);
    calloc.free(pTitle);

    // Set Initial Directory if available
    if (params.initialDirectory.isNotEmpty) {
      final pInitDir = params.initialDirectory.toNativeUtf16();
      final ppItem = calloc<ffi.Pointer>();
      final hrItem = shCreateItem(pInitDir, ffi.nullptr, iidShellItem, ppItem);
      if (hrItem == _S_OK && ppItem.value != ffi.nullptr) {
        setFolderFunc(pDialog, ppItem.value);
        final itemRelease = _getVTableFunc<ffi.Uint32 Function(ffi.Pointer)>(ppItem.value, 2).asFunction<int Function(ffi.Pointer)>();
        itemRelease(ppItem.value);
      }
      calloc.free(ppItem);
      calloc.free(pInitDir);
    }

    // Show Dialog
    final hrShow = showFunc(pDialog, 0);
    if (hrShow == _S_OK) {
      final ppResultItem = calloc<ffi.Pointer>();
      final hrResult = getResultFunc(pDialog, ppResultItem);
      if (hrResult == _S_OK && ppResultItem.value != ffi.nullptr) {
        final pItem = ppResultItem.value;
        final itemRelease = _getVTableFunc<ffi.Uint32 Function(ffi.Pointer)>(pItem, 2).asFunction<int Function(ffi.Pointer)>();
        final getDisplayNameFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Uint32, ffi.Pointer<ffi.Pointer<Utf16>>)>(pItem, 5).asFunction<int Function(ffi.Pointer, int, ffi.Pointer<ffi.Pointer<Utf16>>)>();

        final ppPathStr = calloc<ffi.Pointer<Utf16>>();
        final hrName = getDisplayNameFunc(pItem, _SIGDN_FILESYSPATH, ppPathStr);
        if (hrName == _S_OK && ppPathStr.value != ffi.nullptr) {
          selectedPath = ppPathStr.value.toDartString();
          coTaskMemFree(ppPathStr.value.address);
        }
        calloc.free(ppPathStr);
        itemRelease(pItem);
      }
      calloc.free(ppResultItem);
    }

    releaseFunc(pDialog);
  } catch (_) {
    // If any error occurs, fall back to classic folder picker
    return _nativePickClassicFolderInternal(params);
  } finally {
    calloc.free(clsid);
    calloc.free(iid);
    calloc.free(iidShellItem);
    calloc.free(ppDialog);
    coUninitialize();
  }

  return selectedPath;
}

// ─── Modern COM File Picker Worker Implementation ───────────────────────────

List<String>? _nativePickFilesComInternal(_PickParams params) {
  final ole32 = ffi.DynamicLibrary.open('ole32.dll');
  final shell32 = ffi.DynamicLibrary.open('shell32.dll');

  final coInitializeEx = ole32.lookupFunction<_CoInitializeExNative, _CoInitializeExDart>('CoInitializeEx');
  final coUninitialize = ole32.lookupFunction<_CoUninitializeNative, _CoUninitializeDart>('CoUninitialize');
  final coCreateInstance = ole32.lookupFunction<_CoCreateInstanceNative, _CoCreateInstanceDart>('CoCreateInstance');
  final coTaskMemFree = ole32.lookupFunction<_CoTaskMemFreeNative, _CoTaskMemFreeDart>('CoTaskMemFree');
  final shCreateItem = shell32.lookupFunction<_SHCreateItemFromParsingNameNative, _SHCreateItemFromParsingNameDart>('SHCreateItemFromParsingName');

  coInitializeEx(ffi.nullptr, _COINIT_APARTMENTTHREADED | _COINIT_DISABLE_OLE1DDE);

  List<String>? selectedFiles;
  final clsid = calloc<_GUID>();
  final iid = calloc<_GUID>();
  final iidShellItem = calloc<_GUID>();
  final ppDialog = calloc<ffi.Pointer>();

  try {
    _initClsidFileOpenDialog(clsid);
    _initIidIFileOpenDialog(iid);
    _initIidIShellItem(iidShellItem);

    final hrCreate = coCreateInstance(clsid, ffi.nullptr, _CLSCTX_INPROC_SERVER, iid, ppDialog);
    if (hrCreate != _S_OK || ppDialog.value == ffi.nullptr) {
      return _nativePickFilesWin32Fallback(params);
    }

    final pDialog = ppDialog.value;

    final releaseFunc = _getVTableFunc<ffi.Uint32 Function(ffi.Pointer)>(pDialog, 2).asFunction<int Function(ffi.Pointer)>();
    final showFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.IntPtr)>(pDialog, 3).asFunction<int Function(ffi.Pointer, int)>();
    final setFileTypesFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Uint32, ffi.Pointer<_COMDLG_FILTERSPEC>)>(pDialog, 4).asFunction<int Function(ffi.Pointer, int, ffi.Pointer<_COMDLG_FILTERSPEC>)>();
    final setFileTypeIndexFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Uint32)>(pDialog, 5).asFunction<int Function(ffi.Pointer, int)>();
    final setOptionsFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Uint32)>(pDialog, 9).asFunction<int Function(ffi.Pointer, int)>();
    final getOptionsFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Pointer<ffi.Uint32>)>(pDialog, 10).asFunction<int Function(ffi.Pointer, ffi.Pointer<ffi.Uint32>)>();
    final setFolderFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Pointer)>(pDialog, 12).asFunction<int Function(ffi.Pointer, ffi.Pointer)>();
    final setTitleFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Pointer<Utf16>)>(pDialog, 17).asFunction<int Function(ffi.Pointer, ffi.Pointer<Utf16>)>();
    final getResultFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Pointer<ffi.Pointer>)>(pDialog, 20).asFunction<int Function(ffi.Pointer, ffi.Pointer<ffi.Pointer>)>();
    final getResultsFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Pointer<ffi.Pointer>)>(pDialog, 27).asFunction<int Function(ffi.Pointer, ffi.Pointer<ffi.Pointer>)>();

    // Configure options
    final pOptions = calloc<ffi.Uint32>();
    getOptionsFunc(pDialog, pOptions);
    int options = pOptions.value | _FOS_FORCEFILESYSTEM | _FOS_FILEMUSTEXIST | _FOS_PATHMUSTEXIST;
    if (params.allowMultiple) {
      options |= _FOS_ALLOWMULTISELECT;
    }
    setOptionsFunc(pDialog, options);
    calloc.free(pOptions);

    // Configure Filters
    final filterSpecs = _buildComFilterSpecs(type: params.type, allowedExtensions: params.allowedExtensions);
    final pSpecs = calloc<_COMDLG_FILTERSPEC>(filterSpecs.length);
    final allocatedStrings = <ffi.Pointer<Utf16>>[];

    for (int i = 0; i < filterSpecs.length; i++) {
      final namePtr = filterSpecs[i].name.toNativeUtf16();
      final specPtr = filterSpecs[i].spec.toNativeUtf16();
      allocatedStrings.add(namePtr);
      allocatedStrings.add(specPtr);
      pSpecs[i].pszName = namePtr;
      pSpecs[i].pszSpec = specPtr;
    }

    setFileTypesFunc(pDialog, filterSpecs.length, pSpecs);
    setFileTypeIndexFunc(pDialog, 1);

    // Set Title
    final pTitle = params.title.toNativeUtf16();
    setTitleFunc(pDialog, pTitle);
    calloc.free(pTitle);

    // Set Initial Directory if available
    if (params.initialDirectory.isNotEmpty) {
      final pInitDir = params.initialDirectory.toNativeUtf16();
      final ppItem = calloc<ffi.Pointer>();
      final hrItem = shCreateItem(pInitDir, ffi.nullptr, iidShellItem, ppItem);
      if (hrItem == _S_OK && ppItem.value != ffi.nullptr) {
        setFolderFunc(pDialog, ppItem.value);
        final itemRelease = _getVTableFunc<ffi.Uint32 Function(ffi.Pointer)>(ppItem.value, 2).asFunction<int Function(ffi.Pointer)>();
        itemRelease(ppItem.value);
      }
      calloc.free(ppItem);
      calloc.free(pInitDir);
    }

    // Show Dialog
    final hrShow = showFunc(pDialog, 0);
    if (hrShow == _S_OK) {
      if (params.allowMultiple) {
        final ppItemArray = calloc<ffi.Pointer>();
        final hrResults = getResultsFunc(pDialog, ppItemArray);
        if (hrResults == _S_OK && ppItemArray.value != ffi.nullptr) {
          final pArray = ppItemArray.value;
          final arrayRelease = _getVTableFunc<ffi.Uint32 Function(ffi.Pointer)>(pArray, 2).asFunction<int Function(ffi.Pointer)>();
          final getCountFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Pointer<ffi.Uint32>)>(pArray, 7).asFunction<int Function(ffi.Pointer, ffi.Pointer<ffi.Uint32>)>();
          final getItemAtFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Uint32, ffi.Pointer<ffi.Pointer>)>(pArray, 8).asFunction<int Function(ffi.Pointer, int, ffi.Pointer<ffi.Pointer>)>();

          final pCount = calloc<ffi.Uint32>();
          getCountFunc(pArray, pCount);
          final count = pCount.value;
          calloc.free(pCount);

          final results = <String>[];
          for (int i = 0; i < count; i++) {
            final ppItem = calloc<ffi.Pointer>();
            final hrItem = getItemAtFunc(pArray, i, ppItem);
            if (hrItem == _S_OK && ppItem.value != ffi.nullptr) {
              final pItem = ppItem.value;
              final itemRelease = _getVTableFunc<ffi.Uint32 Function(ffi.Pointer)>(pItem, 2).asFunction<int Function(ffi.Pointer)>();
              final getDisplayNameFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Uint32, ffi.Pointer<ffi.Pointer<Utf16>>)>(pItem, 5).asFunction<int Function(ffi.Pointer, int, ffi.Pointer<ffi.Pointer<Utf16>>)>();

              final ppPathStr = calloc<ffi.Pointer<Utf16>>();
              final hrName = getDisplayNameFunc(pItem, _SIGDN_FILESYSPATH, ppPathStr);
              if (hrName == _S_OK && ppPathStr.value != ffi.nullptr) {
                results.add(ppPathStr.value.toDartString());
                coTaskMemFree(ppPathStr.value.address);
              }
              calloc.free(ppPathStr);
              itemRelease(pItem);
            }
            calloc.free(ppItem);
          }
          selectedFiles = results;
          arrayRelease(pArray);
        }
        calloc.free(ppItemArray);
      } else {
        final ppResultItem = calloc<ffi.Pointer>();
        final hrResult = getResultFunc(pDialog, ppResultItem);
        if (hrResult == _S_OK && ppResultItem.value != ffi.nullptr) {
          final pItem = ppResultItem.value;
          final itemRelease = _getVTableFunc<ffi.Uint32 Function(ffi.Pointer)>(pItem, 2).asFunction<int Function(ffi.Pointer)>();
          final getDisplayNameFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Uint32, ffi.Pointer<ffi.Pointer<Utf16>>)>(pItem, 5).asFunction<int Function(ffi.Pointer, int, ffi.Pointer<ffi.Pointer<Utf16>>)>();

          final ppPathStr = calloc<ffi.Pointer<Utf16>>();
          final hrName = getDisplayNameFunc(pItem, _SIGDN_FILESYSPATH, ppPathStr);
          if (hrName == _S_OK && ppPathStr.value != ffi.nullptr) {
            selectedFiles = [ppPathStr.value.toDartString()];
            coTaskMemFree(ppPathStr.value.address);
          }
          calloc.free(ppPathStr);
          itemRelease(pItem);
        }
        calloc.free(ppResultItem);
      }
    }

    for (final ptr in allocatedStrings) {
      calloc.free(ptr);
    }
    calloc.free(pSpecs);
    releaseFunc(pDialog);
  } catch (_) {
    return _nativePickFilesWin32Fallback(params);
  } finally {
    calloc.free(clsid);
    calloc.free(iid);
    calloc.free(iidShellItem);
    calloc.free(ppDialog);
    coUninitialize();
  }

  return selectedFiles;
}

// ─── Modern COM Save File Worker Implementation ─────────────────────────────

String? _nativeSaveFileComInternal(_PickParams params) {
  final ole32 = ffi.DynamicLibrary.open('ole32.dll');
  final shell32 = ffi.DynamicLibrary.open('shell32.dll');

  final coInitializeEx = ole32.lookupFunction<_CoInitializeExNative, _CoInitializeExDart>('CoInitializeEx');
  final coUninitialize = ole32.lookupFunction<_CoUninitializeNative, _CoUninitializeDart>('CoUninitialize');
  final coCreateInstance = ole32.lookupFunction<_CoCreateInstanceNative, _CoCreateInstanceDart>('CoCreateInstance');
  final coTaskMemFree = ole32.lookupFunction<_CoTaskMemFreeNative, _CoTaskMemFreeDart>('CoTaskMemFree');
  final shCreateItem = shell32.lookupFunction<_SHCreateItemFromParsingNameNative, _SHCreateItemFromParsingNameDart>('SHCreateItemFromParsingName');

  coInitializeEx(ffi.nullptr, _COINIT_APARTMENTTHREADED | _COINIT_DISABLE_OLE1DDE);

  String? savedPath;
  final clsid = calloc<_GUID>();
  final iid = calloc<_GUID>();
  final iidShellItem = calloc<_GUID>();
  final ppDialog = calloc<ffi.Pointer>();

  try {
    _initClsidFileSaveDialog(clsid);
    _initIidIFileSaveDialog(iid);
    _initIidIShellItem(iidShellItem);

    final hrCreate = coCreateInstance(clsid, ffi.nullptr, _CLSCTX_INPROC_SERVER, iid, ppDialog);
    if (hrCreate != _S_OK || ppDialog.value == ffi.nullptr) {
      return _nativeSaveFileWin32Fallback(params);
    }

    final pDialog = ppDialog.value;

    final releaseFunc = _getVTableFunc<ffi.Uint32 Function(ffi.Pointer)>(pDialog, 2).asFunction<int Function(ffi.Pointer)>();
    final showFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.IntPtr)>(pDialog, 3).asFunction<int Function(ffi.Pointer, int)>();
    final setFileTypesFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Uint32, ffi.Pointer<_COMDLG_FILTERSPEC>)>(pDialog, 4).asFunction<int Function(ffi.Pointer, int, ffi.Pointer<_COMDLG_FILTERSPEC>)>();
    final setFileTypeIndexFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Uint32)>(pDialog, 5).asFunction<int Function(ffi.Pointer, int)>();
    final setOptionsFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Uint32)>(pDialog, 9).asFunction<int Function(ffi.Pointer, int)>();
    final getOptionsFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Pointer<ffi.Uint32>)>(pDialog, 10).asFunction<int Function(ffi.Pointer, ffi.Pointer<ffi.Uint32>)>();
    final setFolderFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Pointer)>(pDialog, 12).asFunction<int Function(ffi.Pointer, ffi.Pointer)>();
    final setFileNameFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Pointer<Utf16>)>(pDialog, 15).asFunction<int Function(ffi.Pointer, ffi.Pointer<Utf16>)>();
    final setTitleFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Pointer<Utf16>)>(pDialog, 17).asFunction<int Function(ffi.Pointer, ffi.Pointer<Utf16>)>();
    final getResultFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Pointer<ffi.Pointer>)>(pDialog, 20).asFunction<int Function(ffi.Pointer, ffi.Pointer<ffi.Pointer>)>();

    // Configure options
    final pOptions = calloc<ffi.Uint32>();
    getOptionsFunc(pDialog, pOptions);
    final options = pOptions.value | _FOS_FORCEFILESYSTEM | _FOS_PATHMUSTEXIST | _FOS_OVERWRITEPROMPT;
    setOptionsFunc(pDialog, options);
    calloc.free(pOptions);

    // Configure Filters
    final filterSpecs = _buildComFilterSpecs(type: params.type, allowedExtensions: params.allowedExtensions);
    final pSpecs = calloc<_COMDLG_FILTERSPEC>(filterSpecs.length);
    final allocatedStrings = <ffi.Pointer<Utf16>>[];

    for (int i = 0; i < filterSpecs.length; i++) {
      final namePtr = filterSpecs[i].name.toNativeUtf16();
      final specPtr = filterSpecs[i].spec.toNativeUtf16();
      allocatedStrings.add(namePtr);
      allocatedStrings.add(specPtr);
      pSpecs[i].pszName = namePtr;
      pSpecs[i].pszSpec = specPtr;
    }

    setFileTypesFunc(pDialog, filterSpecs.length, pSpecs);
    setFileTypeIndexFunc(pDialog, 1);

    // Set Default File Name
    if (params.fileName.isNotEmpty) {
      final pFileName = params.fileName.toNativeUtf16();
      setFileNameFunc(pDialog, pFileName);
      calloc.free(pFileName);
    }

    // Set Title
    final pTitle = params.title.toNativeUtf16();
    setTitleFunc(pDialog, pTitle);
    calloc.free(pTitle);

    // Set Initial Directory if available
    if (params.initialDirectory.isNotEmpty) {
      final pInitDir = params.initialDirectory.toNativeUtf16();
      final ppItem = calloc<ffi.Pointer>();
      final hrItem = shCreateItem(pInitDir, ffi.nullptr, iidShellItem, ppItem);
      if (hrItem == _S_OK && ppItem.value != ffi.nullptr) {
        setFolderFunc(pDialog, ppItem.value);
        final itemRelease = _getVTableFunc<ffi.Uint32 Function(ffi.Pointer)>(ppItem.value, 2).asFunction<int Function(ffi.Pointer)>();
        itemRelease(ppItem.value);
      }
      calloc.free(ppItem);
      calloc.free(pInitDir);
    }

    // Show Dialog
    final hrShow = showFunc(pDialog, 0);
    if (hrShow == _S_OK) {
      final ppResultItem = calloc<ffi.Pointer>();
      final hrResult = getResultFunc(pDialog, ppResultItem);
      if (hrResult == _S_OK && ppResultItem.value != ffi.nullptr) {
        final pItem = ppResultItem.value;
        final itemRelease = _getVTableFunc<ffi.Uint32 Function(ffi.Pointer)>(pItem, 2).asFunction<int Function(ffi.Pointer)>();
        final getDisplayNameFunc = _getVTableFunc<ffi.Int32 Function(ffi.Pointer, ffi.Uint32, ffi.Pointer<ffi.Pointer<Utf16>>)>(pItem, 5).asFunction<int Function(ffi.Pointer, int, ffi.Pointer<ffi.Pointer<Utf16>>)>();

        final ppPathStr = calloc<ffi.Pointer<Utf16>>();
        final hrName = getDisplayNameFunc(pItem, _SIGDN_FILESYSPATH, ppPathStr);
        if (hrName == _S_OK && ppPathStr.value != ffi.nullptr) {
          savedPath = ppPathStr.value.toDartString();
          coTaskMemFree(ppPathStr.value.address);
        }
        calloc.free(ppPathStr);
        itemRelease(pItem);
      }
      calloc.free(ppResultItem);
    }

    for (final ptr in allocatedStrings) {
      calloc.free(ptr);
    }
    calloc.free(pSpecs);
    releaseFunc(pDialog);
  } catch (_) {
    return _nativeSaveFileWin32Fallback(params);
  } finally {
    calloc.free(clsid);
    calloc.free(iid);
    calloc.free(iidShellItem);
    calloc.free(ppDialog);
    coUninitialize();
  }

  return savedPath;
}

// ─── Classic Win32 Tree-view Folder Picker Worker Implementation ─────────────

String? _nativePickClassicFolderInternal(_FolderParams params) {
  final shell32 = ffi.DynamicLibrary.open('shell32.dll');
  final ole32 = ffi.DynamicLibrary.open('ole32.dll');

  final shBrowse = shell32.lookupFunction<_SHBrowseForFolderWNative, _SHBrowseForFolderWDart>('SHBrowseForFolderW');
  final shGetPath = shell32.lookupFunction<_SHGetPathFromIDListWNative, _SHGetPathFromIDListWDart>('SHGetPathFromIDListW');
  final coTaskMemFree = ole32.lookupFunction<_CoTaskMemFreeNative, _CoTaskMemFreeDart>('CoTaskMemFree');

  final titleBuffer = params.title.toNativeUtf16();
  final displayBuffer = calloc<ffi.Uint16>(260);

  final bi = calloc<_BROWSEINFOW>();
  bi.ref.hwndOwner = 0;
  bi.ref.pszDisplayName = displayBuffer.cast<Utf16>();
  bi.ref.lpszTitle = titleBuffer;
  bi.ref.ulFlags = _BIF_RETURNONLYFSDIRS | _BIF_USENEWUI;

  final pidl = shBrowse(bi);
  String? selectedFolder;

  if (pidl != 0) {
    final pathBuffer = calloc<ffi.Uint16>(32768);
    final success = shGetPath(pidl, pathBuffer.cast<Utf16>());
    if (success != 0) {
      selectedFolder = pathBuffer.cast<Utf16>().toDartString();
    }
    calloc.free(pathBuffer);
    coTaskMemFree(pidl);
  }

  calloc.free(bi);
  calloc.free(displayBuffer);
  calloc.free(titleBuffer);

  return selectedFolder;
}

// ─── Fallback Win32 Implementations ─────────────────────────────────────────

List<String>? _nativePickFilesWin32Fallback(_PickParams params) {
  final comdlg32 = ffi.DynamicLibrary.open('comdlg32.dll');
  final getOpenFileName = comdlg32.lookupFunction<_GetOpenFileNameWNative, _GetOpenFileNameWDart>('GetOpenFileNameW');

  const maxBufferSize = 65536;
  final fileBuffer = calloc<ffi.Uint16>(maxBufferSize);
  final filterBuffer = _toWin32FilterPointer(_buildWin32Filter(type: params.type, allowedExtensions: params.allowedExtensions));
  final titleBuffer = params.title.toNativeUtf16();
  final initDirBuffer = params.initialDirectory.isNotEmpty
      ? params.initialDirectory.toNativeUtf16()
      : ffi.Pointer<Utf16>.fromAddress(0);

  final ofn = calloc<_OPENFILENAMEW>();
  ofn.ref.lStructSize = ffi.sizeOf<_OPENFILENAMEW>();
  ofn.ref.hwndOwner = 0;
  ofn.ref.lpstrFilter = filterBuffer;
  ofn.ref.nFilterIndex = 1;
  ofn.ref.lpstrFile = fileBuffer.cast<Utf16>();
  ofn.ref.nMaxFile = maxBufferSize;
  ofn.ref.lpstrTitle = titleBuffer;
  ofn.ref.lpstrInitialDir = initDirBuffer;

  int flags = _OFN_EXPLORER | _OFN_FILEMUSTEXIST | _OFN_PATHMUSTEXIST | _OFN_NOCHANGEDIR | _OFN_ENABLESIZING;
  if (params.allowMultiple) {
    flags |= _OFN_ALLOWMULTISELECT;
  }
  ofn.ref.Flags = flags;

  final result = getOpenFileName(ofn);
  List<String>? selectedFiles;

  if (result != 0) {
    selectedFiles = _parseWin32NullTerminatedStringList(fileBuffer, maxBufferSize);
  }

  calloc.free(ofn);
  calloc.free(fileBuffer);
  calloc.free(filterBuffer);
  calloc.free(titleBuffer);
  if (initDirBuffer.address != 0) calloc.free(initDirBuffer);

  return selectedFiles;
}

String? _nativeSaveFileWin32Fallback(_PickParams params) {
  final comdlg32 = ffi.DynamicLibrary.open('comdlg32.dll');
  final getSaveFileName = comdlg32.lookupFunction<_GetSaveFileNameWNative, _GetSaveFileNameWDart>('GetSaveFileNameW');

  const maxBufferSize = 4096;
  final fileBuffer = calloc<ffi.Uint16>(maxBufferSize);
  if (params.fileName.isNotEmpty) {
    final nativeName = params.fileName.toNativeUtf16();
    for (int i = 0; i < params.fileName.length; i++) {
      fileBuffer[i] = nativeName.cast<ffi.Uint16>()[i];
    }
    calloc.free(nativeName);
  }

  final filterBuffer = _toWin32FilterPointer(_buildWin32Filter(type: params.type, allowedExtensions: params.allowedExtensions));
  final titleBuffer = params.title.toNativeUtf16();
  final initDirBuffer = params.initialDirectory.isNotEmpty
      ? params.initialDirectory.toNativeUtf16()
      : ffi.Pointer<Utf16>.fromAddress(0);

  final ofn = calloc<_OPENFILENAMEW>();
  ofn.ref.lStructSize = ffi.sizeOf<_OPENFILENAMEW>();
  ofn.ref.hwndOwner = 0;
  ofn.ref.lpstrFilter = filterBuffer;
  ofn.ref.nFilterIndex = 1;
  ofn.ref.lpstrFile = fileBuffer.cast<Utf16>();
  ofn.ref.nMaxFile = maxBufferSize;
  ofn.ref.lpstrTitle = titleBuffer;
  ofn.ref.lpstrInitialDir = initDirBuffer;
  ofn.ref.Flags = _OFN_EXPLORER | _OFN_PATHMUSTEXIST | _OFN_OVERWRITEPROMPT | _OFN_NOCHANGEDIR | _OFN_ENABLESIZING;

  final result = getSaveFileName(ofn);
  String? savedPath;

  if (result != 0) {
    savedPath = fileBuffer.cast<Utf16>().toDartString();
  }

  calloc.free(ofn);
  calloc.free(fileBuffer);
  calloc.free(filterBuffer);
  calloc.free(titleBuffer);
  if (initDirBuffer.address != 0) calloc.free(initDirBuffer);

  return savedPath;
}

// ─── Filter Helpers ─────────────────────────────────────────────────────────

class _FilterSpec {
  const _FilterSpec(this.name, this.spec);
  final String name;
  final String spec;
}

List<_FilterSpec> _buildComFilterSpecs({
  WindowsFileType type = WindowsFileType.any,
  List<String>? allowedExtensions,
}) {
  if (type == WindowsFileType.custom && allowedExtensions != null && allowedExtensions.isNotEmpty) {
    final patterns = allowedExtensions
        .map((e) => '*.${e.startsWith('.') ? e.substring(1).toLowerCase() : e.toLowerCase()}')
        .join(';');
    return [
      _FilterSpec('Supported Files ($patterns)', patterns),
      const _FilterSpec('All Files (*.*)', '*.*'),
    ];
  }
  if (type == WindowsFileType.image) {
    const img = '*.jpg;*.jpeg;*.png;*.webp;*.bmp;*.gif;*.avif;*.heic;*.tiff;*.tif;*.arw;*.cr2;*.cr3;*.nef;*.rw2;*.orf;*.raf;*.dng';
    return const [
      _FilterSpec('Image Files', img),
      _FilterSpec('All Files (*.*)', '*.*'),
    ];
  }
  if (type == WindowsFileType.video) {
    const vid = '*.mp4;*.mov;*.avi;*.mkv;*.webm;*.flv;*.wmv';
    return const [
      _FilterSpec('Video Files', vid),
      _FilterSpec('All Files (*.*)', '*.*'),
    ];
  }
  if (type == WindowsFileType.audio) {
    const aud = '*.mp3;*.wav;*.aac;*.flac;*.ogg;*.m4a;*.wma';
    return const [
      _FilterSpec('Audio Files', aud),
      _FilterSpec('All Files (*.*)', '*.*'),
    ];
  }
  if (type == WindowsFileType.media) {
    const med = '*.jpg;*.jpeg;*.png;*.webp;*.bmp;*.gif;*.avif;*.heic;*.tiff;*.mp4;*.mov;*.avi;*.mkv;*.webm';
    return const [
      _FilterSpec('Media Files', med),
      _FilterSpec('All Files (*.*)', '*.*'),
    ];
  }
  return const [
    _FilterSpec('All Files (*.*)', '*.*'),
  ];
}

String _buildWin32Filter({
  WindowsFileType type = WindowsFileType.any,
  List<String>? allowedExtensions,
}) {
  if (type == WindowsFileType.custom && allowedExtensions != null && allowedExtensions.isNotEmpty) {
    final patterns = allowedExtensions
        .map((e) => '*.${e.startsWith('.') ? e.substring(1).toLowerCase() : e.toLowerCase()}')
        .join(';');
    return 'Supported Files ($patterns)\x00$patterns\x00All Files (*.*)\x00*.*\x00\x00';
  }
  if (type == WindowsFileType.image) {
    const img = '*.jpg;*.jpeg;*.png;*.webp;*.bmp;*.gif;*.avif;*.heic;*.tiff;*.tif;*.arw;*.cr2;*.cr3;*.nef;*.rw2;*.orf;*.raf;*.dng';
    return 'Image Files\x00$img\x00All Files (*.*)\x00*.*\x00\x00';
  }
  if (type == WindowsFileType.video) {
    const vid = '*.mp4;*.mov;*.avi;*.mkv;*.webm;*.flv;*.wmv';
    return 'Video Files\x00$vid\x00All Files (*.*)\x00*.*\x00\x00';
  }
  if (type == WindowsFileType.audio) {
    const aud = '*.mp3;*.wav;*.aac;*.flac;*.ogg;*.m4a;*.wma';
    return 'Audio Files\x00$aud\x00All Files (*.*)\x00*.*\x00\x00';
  }
  if (type == WindowsFileType.media) {
    const med = '*.jpg;*.jpeg;*.png;*.webp;*.bmp;*.gif;*.avif;*.heic;*.tiff;*.mp4;*.mov;*.avi;*.mkv;*.webm';
    return 'Media Files\x00$med\x00All Files (*.*)\x00*.*\x00\x00';
  }
  return 'All Files (*.*)\x00*.*\x00\x00';
}

ffi.Pointer<Utf16> _toWin32FilterPointer(String filter) {
  final units = <int>[];
  for (int i = 0; i < filter.length; i++) {
    units.add(filter.codeUnitAt(i));
  }
  units.add(0);
  units.add(0);

  final ptr = calloc<ffi.Uint16>(units.length);
  for (int i = 0; i < units.length; i++) {
    ptr[i] = units[i];
  }
  return ptr.cast<Utf16>();
}

List<String> _parseWin32NullTerminatedStringList(ffi.Pointer<ffi.Uint16> buffer, int maxLen) {
  final strings = <String>[];
  final current = <int>[];

  for (int i = 0; i < maxLen; i++) {
    final char = buffer[i];
    if (char == 0) {
      if (current.isEmpty) break;
      strings.add(String.fromCharCodes(current));
      current.clear();
    } else {
      current.add(char);
    }
  }

  if (strings.isEmpty) return [];

  if (strings.length == 1) {
    return [strings.first];
  }

  final folder = strings.first;
  final results = <String>[];
  final separator = folder.endsWith(r'\') ? '' : r'\';

  for (int i = 1; i < strings.length; i++) {
    results.add('$folder$separator${strings[i]}');
  }

  return results;
}
