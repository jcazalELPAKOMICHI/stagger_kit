import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'effects.dart';
import 'extensions.dart';
import 'stagger_item.dart';

/// Staggers the items of a lazily built list or grid.
///
/// Wrap a [ListView], [GridView], [SliverList]… with a scope and mark each
/// item with [StaggerIndexed] (or [StaggerWidgetExtension.staggerAt]):
///
/// ```dart
/// StaggerScope(
///   child: ListView.builder(
///     itemCount: orders.length,
///     itemBuilder: (context, i) => OrderTile(orders[i]).staggerAt(i),
///   ),
/// )
/// ```
///
/// Items visible on the first frame cascade in by index. Items that appear
/// later while scrolling show up settled, unless [animateOnScroll] is true,
/// in which case they animate in without a delay. An item that already
/// animated never animates again when it is scrolled back into view.
class StaggerScope extends StatefulWidget {
  const StaggerScope({
    super.key,
    required this.child,
    this.effects = StaggerPresets.fadeUp,
    this.duration = StaggerItem.defaultDuration,
    this.interval = kStaggerInterval,
    this.delay = Duration.zero,
    this.curve = StaggerItem.defaultCurve,
    this.animateOnScroll = false,
    this.controller,
  });

  final Widget child;
  final List<StaggerEffect> effects;
  final Duration duration;

  /// Gap between the start of consecutive items on the first frame.
  final Duration interval;

  /// Wait before the first item starts.
  final Duration delay;
  final Curve curve;

  /// Whether items that first appear after the initial frame animate in.
  final bool animateOnScroll;

  /// Replays, reverses or resets every item currently built.
  final StaggerController? controller;

  /// The nearest scope's state, or null if there is none.
  static StaggerScopeState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_StaggerScopeMarker>()?.state;

  @override
  State<StaggerScope> createState() => StaggerScopeState();
}

/// State of a [StaggerScope], read by its [StaggerIndexed] items.
class StaggerScopeState extends State<StaggerScope> {
  final Set<int> _seen = {};
  bool _initialFrame = true;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => _initialFrame = false,
    );
  }

  /// Settings shared by all items.
  StaggerScope get config => widget;

  /// Whether items are still being built for the first frame.
  bool get isInitialFrame => _initialFrame;

  /// Records that item [index] was built. Returns true the first time only.
  bool register(int index) => _seen.add(index);

  @override
  Widget build(BuildContext context) =>
      _StaggerScopeMarker(state: this, config: widget, child: widget.child);
}

class _StaggerScopeMarker extends InheritedWidget {
  const _StaggerScopeMarker({
    required this.state,
    required this.config,
    required super.child,
  });

  final StaggerScopeState state;
  final StaggerScope config;

  @override
  bool updateShouldNotify(_StaggerScopeMarker oldWidget) =>
      config != oldWidget.config;
}

/// Item [index] of the nearest [StaggerScope].
///
/// For grids, pass [columnCount] to make items cascade diagonally (row plus
/// column) instead of one by one.
class StaggerIndexed extends StatelessWidget {
  const StaggerIndexed({
    super.key,
    required this.index,
    this.columnCount,
    required this.child,
  }) : assert(index >= 0),
       assert(columnCount == null || columnCount > 0);

  final int index;
  final int? columnCount;
  final Widget child;

  int get _slot => switch (columnCount) {
    null => index,
    final columns => index ~/ columns + index % columns,
  };

  @override
  Widget build(BuildContext context) {
    final scope = StaggerScope.maybeOf(context);
    assert(
      scope != null,
      'StaggerIndexed must be placed under a StaggerScope.',
    );
    if (scope == null) return child;

    final config = scope.config;
    final isNew = scope.register(index);
    final initial = scope.isInitialFrame;
    return StaggerItem(
      effects: config.effects,
      duration: config.duration,
      delay: initial ? config.delay + config.interval * _slot : Duration.zero,
      curve: config.curve,
      controller: config.controller,
      settled: !isNew || (!initial && !config.animateOnScroll),
      child: child,
    );
  }
}
