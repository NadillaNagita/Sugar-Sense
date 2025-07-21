import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sugarsense/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pengujian login', (WidgetTester tester) async {
    // Jalankan aplikasi
    app.main();
    await tester.pumpAndSettle();

    // Masukkan email & password (pastikan widget punya Key)
    await tester.enterText(find.byKey(Key('emailField')), 'test@example.com');
    await tester.enterText(find.byKey(Key('passwordField')), '123456');

    // Klik tombol login
    await tester.tap(find.byKey(Key('loginButton')));
    await tester.pumpAndSettle();

    // Pastikan berhasil login (ubah sesuai teks yang muncul di halaman berikutnya)
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
