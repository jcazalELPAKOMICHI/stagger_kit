import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'effects.dart';
import 'stagger_item.dart';
import 'stagger_scope.dart';

/// Default gap between the start of one item and the next.
const Duration kStaggerInterval = Duration(milliseconds: 70);

/// The order in which items of a group start animating.
enum StaggerOrder {
  /// First to last.
  forward,

  /// Last to first.
  reverse,

  /// From the middle item outwards.
  centerOut;

  /// The start slot (0 starts first) of the item at [index] in a group of
  /// [count] items.
  int slotOf(int index, int count) => switch (this) {
    forward => index,
    reverse => count - 1 - index,
    centerOut => (index - (count - 1) / 2).abs().floor(),
  };
}

/// Staggers a list of widgets, typically the children of a [Column], [Row]
/// or [Wrap].
extension StaggerListExtension on List<Widget> {
  /// Wraps every widget in a [StaggerItem], each one starting [interval]
  /// after the previous one.
  ///
  /// ```dart
  /// Column(
  ///   children: [
  ///     const Logo(),
  ///     const Text('Welcome back'),
  ///     EmailField(),
  ///     PasswordField(),
  ///     LoginButton(),
  ///   ].stagger(),
  /// )
  /// ```
  ///
  /// [onComplete] is called once, when the last item to start has settled.
  /// After [StaggerCommand.reverse], items leave in the opposite order.
  List<Widget> stagger({
    List<StaggerEffect> effects = StaggerPresets.fadeUp,
    Duration duration = StaggerItem.defaultDuration,
    Duration interval = kStaggerInterval,
    Duration delay = Duration.zero,
    Curve curve = StaggerItem.defaultCurve,
    StaggerOrder order = StaggerOrder.forward,
    StaggerController? controller,
    bool autoPlay = true,
    VoidCallback? onComplete,
  }) {
    final count = length;
    if (count == 0) return const [];
    final slots = [for (var i = 0; i < count; i++) order.slotOf(i, count)];
    final lastSlot = slots.reduce((a, b) => a > b ? a : b);
    final lastIndex = slots.indexOf(lastSlot);
    return [
      for (var i = 0; i < count; i++)
        StaggerItem(
          effects: effects,
          duration: duration,
          delay: delay + interval * slots[i],
          reverseDelay: interval * (lastSlot - slots[i]),
          curve: curve,
          controller: controller,
          autoPlay: autoPlay,
          onComplete: i == lastIndex ? onComplete : null,
          child: this[i],
        ),
    ];
  }
}

/// Animation helpers on any widget.
extension StaggerWidgetExtension on Widget {
  /// Animates this widget in on its own. See [StaggerItem].
  Widget animateIn({
    List<StaggerEffect> effects = StaggerPresets.fadeUp,
    Duration duration = StaggerItem.defaultDuration,
    Duration delay = Duration.zero,
    Curve curve = StaggerItem.defaultCurve,
    StaggerController? controller,
    bool autoPlay = true,
    VoidCallback? onComplete,
  }) => StaggerItem(
    effects: effects,
    duration: duration,
    delay: delay,
    curve: curve,
    controller: controller,
    autoPlay: autoPlay,
    onComplete: onComplete,
    child: this,
  );

  /// Marks this widget as item [index] of the nearest [StaggerScope].
  /// See [StaggerIndexed].
  Widget staggerAt(int index, {int? columnCount}) =>
      StaggerIndexed(index: index, columnCount: columnCount, child: this);
}
