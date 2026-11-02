import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagger_kit/stagger_kit.dart';

double _opacityOf(WidgetTester tester, String text) {
  final opacity = tester.widget<Opacity>(
    find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first,
  );
  return opacity.opacity;
}

Widget _app(Widget child, {bool disableAnimations = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(body: child),
  ),
);

void main() {
  group('StaggerOrder.slotOf', () {
    test('forward and reverse', () {
      expect(
        [for (var i = 0; i < 4; i++) StaggerOrder.forward.slotOf(i, 4)],
        [0, 1, 2, 3],
      );
      expect(
        [for (var i = 0; i < 4; i++) StaggerOrder.reverse.slotOf(i, 4)],
        [3, 2, 1, 0],
      );
    });

    test('centerOut starts in the middle', () {
      expect(
        [for (var i = 0; i < 5; i++) StaggerOrder.centerOut.slotOf(i, 5)],
        [2, 1, 0, 1, 2],
      );
      expect(
        [for (var i = 0; i < 4; i++) StaggerOrder.centerOut.slotOf(i, 4)],
        [1, 0, 0, 1],
      );
    });
  });

  testWidgets('animateIn goes from hidden to visible', (tester) async {
    await tester.pumpWidget(_app(const Text('hello').animateIn()));
    expect(_opacityOf(tester, 'hello'), 0);

    await tester.pump(StaggerItem.defaultDuration ~/ 2);
    expect(_opacityOf(tester, 'hello'), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 'hello'), 1);
  });

  testWidgets('stagger delays each item by the interval', (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      _app(
        Column(
          children: [const Text('a'), const Text('b'), const Text('c')].stagger(
            interval: const Duration(milliseconds: 100),
            onComplete: () => completed++,
          ),
        ),
      ),
    );

    for (var i = 0; i < 9; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final a = _opacityOf(tester, 'a');
    final b = _opacityOf(tester, 'b');
    final c = _opacityOf(tester, 'c');
    expect(a, greaterThan(b));
    expect(b, greaterThan(0));
    expect(c, 0);

    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 'c'), 1);
    expect(completed, 1);
  });

  testWidgets('reduced motion shows items settled at once', (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      _app(
        Column(
          children: [const Text('a'), const Text('b')].stagger(
            delay: const Duration(seconds: 1),
            onComplete: () => completed++,
          ),
        ),
        disableAnimations: true,
      ),
    );
    await tester.pump();
    expect(_opacityOf(tester, 'a'), 1);
    expect(_opacityOf(tester, 'b'), 1);
    expect(completed, 1);
  });

  testWidgets('controller replays, reverses and resets', (tester) async {
    final controller = StaggerController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(const Text('x').animateIn(controller: controller)),
    );
    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 'x'), 1);

    controller.replay();
    await tester.pump();
    expect(_opacityOf(tester, 'x'), 0);
    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 'x'), 1);

    controller.reverse();
    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 'x'), 0);

    controller.play();
    await tester.pumpAndSettle();
    controller.reset();
    await tester.pump();
    expect(_opacityOf(tester, 'x'), 0);
  });

  testWidgets('autoPlay false waits for the controller', (tester) async {
    final controller = StaggerController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(const Text('x').animateIn(controller: controller, autoPlay: false)),
    );
    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 'x'), 0);

    controller.play();
    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 'x'), 1);
  });

  testWidgets('child state survives the animation', (tester) async {
    final key = GlobalKey<EditableTextState>();
    final text = TextEditingController();
    addTearDown(text.dispose);
    await tester.pumpWidget(
      _app(
        TextField(
          key: key,
          controller: text,
        ).animateIn(effects: StaggerPresets.focusUp),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    final before = tester.state(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(EditableText)), same(before));
  });

  group('StaggerScope', () {
    testWidgets('cascades visible items and settles later ones', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          StaggerScope(
            interval: const Duration(milliseconds: 100),
            child: ListView.builder(
              itemCount: 100,
              itemExtent: 100,
              itemBuilder: (context, i) => Text('item $i').staggerAt(i),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 150));
      expect(
        _opacityOf(tester, 'item 0'),
        greaterThan(_opacityOf(tester, 'item 1')),
      );
      expect(_opacityOf(tester, 'item 2'), 0);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pump();
      final later = find.textContaining('item 3').last;
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: later, matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, 1);
    });

    testWidgets('columnCount cascades diagonally', (tester) async {
      await tester.pumpWidget(
        _app(
          StaggerScope(
            interval: const Duration(milliseconds: 100),
            child: GridView.count(
              crossAxisCount: 2,
              children: [
                for (var i = 0; i < 4; i++)
                  Text('cell $i').staggerAt(i, columnCount: 2),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));
      // Cells 1 and 2 sit on the same diagonal.
      expect(_opacityOf(tester, 'cell 1'), _opacityOf(tester, 'cell 2'));
      expect(_opacityOf(tester, 'cell 3'), 0);
      await tester.pumpAndSettle();
    });
  });
}
