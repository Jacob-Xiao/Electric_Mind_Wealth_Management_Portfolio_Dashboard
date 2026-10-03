import 'package:electric_mind_portfolio/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shell renders the placeholder portfolio overview',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PortfolioApp());

    expect(find.text('ELECTRIC MIND'), findsOneWidget);
    expect(find.text('Portfolio Overview'), findsOneWidget);
    expect(
      find.text('Your portfolio summary will appear here.'),
      findsOneWidget,
    );
  });
}
