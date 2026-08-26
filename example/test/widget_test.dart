import 'package:flutter_test/flutter_test.dart';
import 'package:windows_file_picker_wrapper_example/main.dart';

void main() {
  testWidgets('Renders iOS Cupertino Example App', (WidgetTester tester) async {
    await tester.pumpWidget(const FilePickerExampleApp());
    expect(find.text('Windows Picker Wrapper'), findsOneWidget);
    expect(find.text('Pick Folder'), findsOneWidget);
    expect(find.text('Pick Multiple Photos'), findsOneWidget);
    expect(find.text('Pick Single Document'), findsOneWidget);
    expect(find.text('Save File'), findsOneWidget);
  });
}
