import 'package:flutter_test/flutter_test.dart';
import 'package:windows_file_picker_wrapper/windows_file_picker_wrapper.dart';

void main() {
  test('WindowsFileType enums are well defined', () {
    expect(WindowsFileType.values.length, 6);
    expect(WindowsFileType.any, isNotNull);
    expect(WindowsFileType.image, isNotNull);
    expect(WindowsFileType.video, isNotNull);
    expect(WindowsFileType.audio, isNotNull);
    expect(WindowsFileType.media, isNotNull);
    expect(WindowsFileType.custom, isNotNull);
  });

  test('WindowsFilePickerWrapper static methods are present', () {
    expect(WindowsFilePickerWrapper.pickModernFolder, isNotNull);
    expect(WindowsFilePickerWrapper.pickClassicFolder, isNotNull);
    expect(WindowsFilePickerWrapper.pickFolder, isNotNull);
    expect(WindowsFilePickerWrapper.pickFile, isNotNull);
    expect(WindowsFilePickerWrapper.pickFiles, isNotNull);
    expect(WindowsFilePickerWrapper.saveFile, isNotNull);
  });
}
