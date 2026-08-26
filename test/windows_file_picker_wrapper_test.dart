import 'package:flutter_test/flutter_test.dart';
import 'package:windows_file_picker_wrapper/windows_file_picker_wrapper.dart';

void main() {
  test('WindowsFileType enums exist', () {
    expect(WindowsFileType.values.length, 6);
    expect(WindowsFileType.any, isNotNull);
    expect(WindowsFileType.image, isNotNull);
    expect(WindowsFileType.video, isNotNull);
    expect(WindowsFileType.audio, isNotNull);
    expect(WindowsFileType.media, isNotNull);
    expect(WindowsFileType.custom, isNotNull);
  });
}
