import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'effects.dart';

/// Animates a single [child] in with a list of [effects].
///
/// This is the building block behind `List<Widget>.stagger()`,
/// `Widget.animateIn()` and `StaggerIndexed`; use it directly when you need
/// full control.
///
/// When the platform asks for reduced motion
/// ([MediaQueryData.disableAnimations]), the child is shown settled right away.
class StaggerItem extends StatefulWidget {
  const StaggerItem({
    super.key,
    required this.child,
    this.effects = StaggerPresets.fadeUp,
    this.duration = defaultDuration,
    this.delay = Duration.zero,
    this.reverseDelay = Duration.zero,
    this.curve = defaultCurve,
    this.controller,
    this.autoPlay = true,
    this.settled = false,
    this.onComplete,
  });

  /// Default length of one item's animation.
  static const Duration defaultDuration = Duration(milliseconds: 450);

  /// Default easing for one item's animation.
  static const Curve defaultCurve = Curves.easeOutCubic;

  final Widget child;

  /// Effects applied in order; the first one wraps [child] directly.
  final List<StaggerEffect> effects;

  /// Length of this item's animation, not counting [delay].
  final Duration duration;

  /// Wait before animating in.
  final Duration delay;

  /// Wait before animating out after [StaggerCommand.reverse].
  final Duration reverseDelay;

  /// Easing used by every effect that doesn't set its own curve.
  final Curve curve;

  /// Optional controller to replay, reverse or reset this item.
  final StaggerController? controller;

  /// Whether to animate in as soon as the item is first built.
  final bool autoPlay;

  /// Whether to start already settled (fully visible), without animating.
  ///
  /// Only read when the item is first built.
  final bool settled;

  /// Called each time the item finishes animating in.
  final VoidCallback? onComplete;

  @override
  State<StaggerItem> createState() => _StaggerItemState();
}

class _StaggerItemState extends State<StaggerItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.settled ? 1 : 0,
  )..addStatusListener(_handleStatus);

  Timer? _timer;
  bool _reduceMotion = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_handleCommand);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduceMotion && _animation.isAnimating) {
      _timer?.cancel();
      _animation.value = 1;
    }
    if (!_started) {
      _started = true;
      if (widget.autoPlay && !widget.settled) _play();
    }
  }

  @override
  void didUpdateWidget(StaggerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _animation.duration = widget.duration;
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleCommand);
      widget.controller?.addListener(_handleCommand);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller?.removeListener(_handleCommand);
    _animation.dispose();
    super.dispose();
  }

  void _handleCommand() {
    switch (widget.controller?.command) {
      case StaggerCommand.play:
        _play();
      case StaggerCommand.replay:
        _play(restart: true);
      case StaggerCommand.reverse:
        _reverse();
      case StaggerCommand.reset:
        _timer?.cancel();
        _animation.value = 0;
      case null:
        break;
    }
  }

  void _play({bool restart = false}) {
    _timer?.cancel();
    if (_reduceMotion) {
      _animation.value = 1;
      return;
    }
    if (restart) _animation.value = 0;
    _after(widget.delay, _animation.forward);
  }

  void _reverse() {
    _timer?.cancel();
    if (_reduceMotion) {
      _animation.value = 0;
      return;
    }
    _after(widget.reverseDelay, _animation.reverse);
  }

  void _after(Duration delay, TickerFuture Function() run) {
    if (delay == Duration.zero) {
      run();
      return;
    }
    _timer = Timer(delay, () {
      if (mounted) run();
    });
  }

  void _handleStatus(AnimationStatus status) {
    final onComplete = widget.onComplete;
    if (!status.isCompleted || onComplete == null) return;
    // Settling can happen while building (reduced motion), where the
    // callback must not trigger a rebuild. Defer it to after the frame.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => onComplete());
    } else {
      onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final progress = _animation.value;
        var result = child!;
        for (final effect in widget.effects) {
          final t = (effect.curve ?? widget.curve).transform(progress);
          result = effect.apply(result, t);
        }
        return result;
      },
    );
  }
}
