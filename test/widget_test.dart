import 'package:flutter_test/flutter_test.dart';
import 'package:movie_recommender_web/main.dart';

void main() {
  testWidgets('App renders CineSage', (WidgetTester tester) async {
    await tester.pumpWidget(const CineMatchApp());
    expect(find.text('CineMatch'), findsOneWidget);
  });
}
