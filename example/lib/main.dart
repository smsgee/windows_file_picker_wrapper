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
  State<FilePickerExampleScreen> createState() => _FilePickerExampleScreenState();
}

class _FilePickerExampleScreenState extends State<FilePickerExampleScreen> {
  String _status = 'Ready. Select an action below.';
  List<String> _results = [];

  Future<void> _pickFolder() async {
    setState(() => _status = 'Opening Modern Folder Picker...');
    final path = await WindowsFilePickerWrapper.pickFolder(
      title: 'Select Destination Directory',
    );
    setState(() {
      if (path != null) {
        _status = 'Selected Folder:';
        _results = [path];
      } else {
        _status = 'Folder selection cancelled.';
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
    setState(() {
      if (path != null) {
        _status = 'Saved Destination:';
        _results = [path];
      } else {
        _status = 'Save file cancelled.';
      }
    });
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
              header: const Text('PICKER ACTIONS'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.folder_fill, color: CupertinoColors.activeBlue),
                  title: const Text('Pick Folder'),
                  subtitle: const Text('Modern Windows 10/11 Folder Dialog'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _pickFolder,
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.photo_fill_on_rectangle_fill, color: CupertinoColors.activeGreen),
                  title: const Text('Pick Multiple Photos'),
                  subtitle: const Text('Multi-select image filter (*.jpg, *.png, etc.)'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _pickImages,
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.doc_text_fill, color: CupertinoColors.systemOrange),
                  title: const Text('Pick Single Document'),
                  subtitle: const Text('Custom filter (*.pdf, *.docx, *.json)'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _pickSingleDocument,
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.floppy_disk, color: CupertinoColors.systemPurple),
                  title: const Text('Save File'),
                  subtitle: const Text('Modern Windows 10/11 SaveFileDialog'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _saveFile,
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('RESULT / STATUS'),
              footer: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_status, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
              ),
              children: [
                if (_results.isEmpty)
                  const CupertinoListTile(
                    title: Text('No files or folder selected yet', style: TextStyle(color: CupertinoColors.placeholderText)),
                  )
                else
                  ..._results.map(
                    (p) => CupertinoListTile(
                      leading: const Icon(CupertinoIcons.checkmark_circle_fill, color: CupertinoColors.activeGreen, size: 20),
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
