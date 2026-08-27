## 1.0.3

* Added modern Windows 10/11 Explorer-style folder picker (`pickModernFolder`) using COM `IFileOpenDialog` with `FOS_PICKFOLDERS`.
* Preserved classic Win32 `SHBrowseForFolderW` tree-view folder picker as `pickClassicFolder`.
* Enhanced `pickFolder` to default to the modern Explorer dialog with optional classic tree-view fallback (`useModern: false`).
* Upgraded `pickFile`, `pickFiles`, and `saveFile` to modern COM Common Item Dialogs (`IFileOpenDialog` / `IFileSaveDialog`) with worker isolate execution.
* Updated the example application demonstrating both modern and classic file and folder pickers.

## 1.0.2

* Added complete iOS/Cupertino-styled example application in `example/`.
* Achieved 100% dartdoc documentation coverage (160/160 pub points).
* Explicitly declared `platforms: windows:` top-level metadata.
* Updated homepage and repository metadata for verified publisher `smsgee.com`.

## 1.0.0

* Initial release of `windows_file_picker_wrapper`.
* Modern Windows 10/11 `IFileOpenDialog` (FOS_PICKFOLDERS) folder browser.
* Multi-file `OpenFileDialog` with type filtering and multi-select.
* Native `SaveFileDialog`.
* Isolated out-of-process STA execution.
