// Smoke test for the Tornado Gallery landing site.

import 'package:flutter_test/flutter_test.dart';

import 'package:tornado_gallery_site/main.dart';

void main() {
  testWidgets('renders the hero headline', (WidgetTester tester) async {
    await tester.pumpWidget(const TornadoGallerySite());
    await tester.pump();

    // Headline copy and a section heading are present.
    expect(find.text('Your photos,'), findsOneWidget);
    expect(find.text('Tornado Gallery'), findsWidgets);
  });
}
