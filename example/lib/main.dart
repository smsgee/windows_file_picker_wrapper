import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:windows_file_picker_wrapper/windows_file_picker_wrapper.dart';

void main() {
  runApp(const FilePickerExampleApp());
}

/// Simple iOS/Cupertino-styled demo application for [WindowsFilePickerWrapper].
class FilePickerExampleApp extends StatelessWidget {
  const FilePickerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.activeBlue,
      ),
      home: FilePickerExampleScreen(),
    );
  }
}

/// Main example screen showcasing iOS Cupertino grouped cards and actions.
class FilePickerExampleScreen extends StatefulWidget {
  const FilePickerExampleScreen({super.key});

  @override
  State<FilePickerExampleScreen> createState() =>
      _FilePickerExampleScreenState();
}

class _FilePickerExampleScreenState extends State<FilePickerExampleScreen> {
  String _status = 'Ready. Select an action below.';
  List<String> _results = [];

  Future<void> _pickModernFile() async {
    setState(() => _status = 'Opening Modern File Picker (Any File)...');
    final path = await WindowsFilePickerWrapper.pickFile(
      title: 'Select Any File',
      type: WindowsFileType.any,
    );
    setState(() {
      if (path != null) {
        _status = 'Selected File:';
        _results = [path];
      } else {
        _status = 'File selection cancelled.';
      }
    });
  }

  Future<void> _pickModernFolder() async {
    setState(() => _status = 'Opening Modern Folder Picker...');
    final path = await WindowsFilePickerWrapper.pickModernFolder(
      title: 'Select Destination Directory',
    );
    setState(() {
      if (path != null) {
        _status = 'Selected Modern Folder:';
        _results = [path];
      } else {
        _status = 'Modern folder selection cancelled.';
      }
    });
  }

  Future<void> _pickClassicFolder() async {
    setState(() => _status = 'Opening Classic Tree-view Folder Picker...');
    final path = await WindowsFilePickerWrapper.pickClassicFolder(
      title: 'Select Directory (Classic Tree)',
    );
    setState(() {
      if (path != null) {
        _status = 'Selected Classic Folder:';
        _results = [path];
      } else {
        _status = 'Classic folder selection cancelled.';
      }
    });
  }

  Future<void> _pickImages() async {
    setState(() => _status = 'Opening Images Picker...');
    final paths = await WindowsFilePickerWrapper.pickFiles(
      title: 'Select Images',
      type: WindowsFileType.image,
      allowMultiple: true,
    );
    setState(() {
      if (paths != null && paths.isNotEmpty) {
        _status = 'Selected ${paths.length} Image(s):';
        _results = paths;
      } else {
        _status = 'Image selection cancelled.';
      }
    });
  }

  Future<void> _pickSingleDocument() async {
    setState(() => _status = 'Opening Document Picker...');
    final path = await WindowsFilePickerWrapper.pickFile(
      title: 'Select Document',
      type: WindowsFileType.custom,
      allowedExtensions: ['pdf', 'docx', 'xlsx', 'txt', 'json'],
    );
    setState(() {
      if (path != null) {
        _status = 'Selected Document:';
        _results = [path];
      } else {
        _status = 'Document selection cancelled.';
      }
    });
  }

  Future<void> _saveFile() async {
    setState(() => _status = 'Opening Save File Dialog...');
    final path = await WindowsFilePickerWrapper.saveFile(
      title: 'Export Backup',
      fileName: 'backup_export.json',
      allowedExtensions: ['json'],
    );
    if (path != null) {
      try {
        final sampleData = const JsonEncoder.withIndent('  ').convert({
          'plugin': 'windows_file_picker_wrapper',
          'version': '1.0.3',
          'exportedAt': DateTime.now().toIso8601String(),
          'message':
              'Real file written successfully to disk via Windows Native Picker!',
          'sampleItems': ['Item 1', 'Item 2', 'Item 3'],
        });
        await File(path).writeAsString(sampleData);
        setState(() {
          _status = 'File written successfully to:';
          _results = [path];
        });
      } catch (e) {
        setState(() {
          _status = 'File path chosen, but write error: $e';
          _results = [path];
        });
      }
    } else {
      setState(() {
        _status = 'Save file cancelled.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Windows Picker Wrapper'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text('File/Folder Picker Actions'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.doc,
                      color: CupertinoColors.activeBlue),
                  title: const Text('Pick File (Modern)'),
                  subtitle:
                      const Text('Modern Windows 10/11 Single File Dialog'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _pickModernFile,
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.folder_badge_plus,
                      color: CupertinoColors.systemTeal),
                  title: const Text('Pick Folder (Modern)'),
                  subtitle:
                      const Text('Modern Windows 10/11 Explorer Folder Dialog'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _pickModernFolder,
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.folder,
                      color: CupertinoColors.systemGrey),
                  title: const Text('Pick Folder (Classic)'),
                  subtitle: const Text(
                      'Legacy Win32 Tree-view Folder Dialog (SHBrowseForFolder)'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _pickClassicFolder,
                ),
                CupertinoListTile(
                  leading: const Icon(
                      CupertinoIcons.photo_fill_on_rectangle_fill,
                      color: CupertinoColors.activeGreen),
                  title: const Text('Pick Multiple Photos (Modern)'),
                  subtitle: const Text(
                      'Multi-select image filter (*.jpg, *.png, etc.)'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _pickImages,
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.doc_text_fill,
                      color: CupertinoColors.systemOrange),
                  title: const Text('Pick Single Document (Modern)'),
                  subtitle: const Text('Custom filter (*.pdf, *.docx, *.json)'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _pickSingleDocument,
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.floppy_disk,
                      color: CupertinoColors.systemPurple),
                  title: const Text('Save File (Modern)'),
                  subtitle: const Text(
                      'Prompts destination and writes real JSON content'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _saveFile,
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('RESULT / STATUS'),
              footer: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_status,
                    style: const TextStyle(
                        fontSize: 13, color: CupertinoColors.systemGrey)),
              ),
              children: [
                if (_results.isEmpty)
                  const CupertinoListTile(
                    title: Text('No files or folder selected yet',
                        style:
                            TextStyle(color: CupertinoColors.placeholderText)),
                  )
                else
                  ..._results.map(
                    (p) => CupertinoListTile(
                      leading: const Icon(CupertinoIcons.checkmark_circle_fill,
                          color: CupertinoColors.activeGreen, size: 20),
                      title: Text(p, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
