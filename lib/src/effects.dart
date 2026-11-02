import 'dart:math' as math;
import 'dart:ui' show ImageFilter, TileMode, lerpDouble;

import 'package:flutter/widgets.dart';

/// Signature for [CustomEffect.builder].
///
/// [t] is the eased progress of the animation, usually between 0 (start)
/// and 1 (settled). Curves such as [Curves.easeOutBack] may overshoot.
typedef StaggerEffectBuilder = Widget Function(Widget child, double t);

/// A visual transformation applied to a child while it animates in.
///
/// Effects are composable: every effect in a list wraps the result of the
/// previous one, so `[FadeEffect(), MoveEffect()]` fades *and* moves.
///
/// Each effect always produces the same widget structure regardless of the
/// progress,
/// so the state of the animated child (focus, text, scroll position) is
/// preserved for the whole animation.
@immutable
sealed class StaggerEffect {
  const StaggerEffect({this.curve});

  /// Curve for this effect only. When null, the item's curve is used.
  final Curve? curve;

  /// Wraps [child] with this effect at eased progress [t].
  Widget apply(Widget child, double t);
}

/// Animates opacity from [begin] to [end].
final class FadeEffect extends StaggerEffect {
  const FadeEffect({this.begin = 0, this.end = 1, super.curve});

  final double begin;
  final double end;

  @override
  Widget apply(Widget child, double t) {
    final opacity = lerpDouble(begin, end, t)!.clamp(0.0, 1.0);
    return Opacity(opacity: opacity, child: child);
  }
}

/// Moves the child by a fixed offset in logical pixels.
///
/// Prefer this over [SlideEffect] when children have different sizes: every
/// child travels the same distance, which reads as a cleaner cascade.
final class MoveEffect extends StaggerEffect {
  const MoveEffect({
    this.begin = const Offset(0, 24),
    this.end = Offset.zero,
    super.curve,
  });

  final Offset begin;
  final Offset end;

  @override
  Widget apply(Widget child, double t) =>
      Transform.translate(offset: Offset.lerp(begin, end, t)!, child: child);
}

/// Moves the child by a fraction of its own size.
final class SlideEffect extends StaggerEffect {
  const SlideEffect({
    this.begin = const Offset(0, 0.25),
    this.end = Offset.zero,
    super.curve,
  });

  final Offset begin;
  final Offset end;

  @override
  Widget apply(Widget child, double t) => FractionalTranslation(
    translation: Offset.lerp(begin, end, t)!,
    child: child,
  );
}

/// Scales the child from [begin] to [end] around [alignment].
final class ScaleEffect extends StaggerEffect {
  const ScaleEffect({
    this.begin = 0.85,
    this.end = 1,
    this.alignment = Alignment.center,
    super.curve,
  });

  final double begin;
  final double end;
  final Alignment alignment;

  @override
  Widget apply(Widget child, double t) => Transform.scale(
    scale: lerpDouble(begin, end, t)!,
    alignment: alignment,
    child: child,
  );
}

/// Blurs the child, going from a [begin] sigma to an [end] sigma.
///
/// The blur layer is disabled once the sigma reaches zero, so a settled
/// child costs nothing extra to paint.
final class BlurEffect extends StaggerEffect {
  const BlurEffect({this.begin = 8, this.end = 0, super.curve});

  final double begin;
  final double end;

  @override
  Widget apply(Widget child, double t) {
    final sigma = math.max(0.0, lerpDouble(begin, end, t)!);
    return ImageFiltered(
      enabled: sigma > 0.01,
      imageFilter: ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: TileMode.decal,
      ),
      child: child,
    );
  }
}

/// An effect defined by a [builder], for anything the built-in effects
/// don't cover.
///
/// The builder must return the same widget structure for every `t` to keep
/// the child's state intact.
final class CustomEffect extends StaggerEffect {
  const CustomEffect({required this.builder, super.curve});

  final StaggerEffectBuilder builder;

  @override
  Widget apply(Widget child, double t) => builder(child, t);
}

/// Ready-made effect combinations.
abstract final class StaggerPresets {
  /// Fades in.
  static const List<StaggerEffect> fadeIn = [FadeEffect()];

  /// Fades in while rising 24px. The classic login/onboarding cascade.
  static const List<StaggerEffect> fadeUp = [FadeEffect(), MoveEffect()];

  /// Fades in while dropping 24px.
  static const List<StaggerEffect> fadeDown = [
    FadeEffect(),
    MoveEffect(begin: Offset(0, -24)),
  ];

  /// Fades in from the right.
  static const List<StaggerEffect> slideFromRight = [
    FadeEffect(),
    MoveEffect(begin: Offset(32, 0)),
  ];

  /// Fades in from the left.
  static const List<StaggerEffect> slideFromLeft = [
    FadeEffect(),
    MoveEffect(begin: Offset(-32, 0)),
  ];

  /// Fades in while growing slightly.
  static const List<StaggerEffect> scaleIn = [FadeEffect(), ScaleEffect()];

  /// Springs in with a small overshoot. Good for buttons and chips.
  static const List<StaggerEffect> pop = [
    FadeEffect(curve: Curves.easeOut),
    ScaleEffect(begin: 0.6, curve: Curves.easeOutBack),
  ];

  /// Comes into focus from a blur.
  static const List<StaggerEffect> blurIn = [FadeEffect(), BlurEffect()];

  /// Rises and comes into focus at the same time.
  static const List<StaggerEffect> focusUp = [
    FadeEffect(),
    MoveEffect(begin: Offset(0, 16)),
    BlurEffect(begin: 6),
  ];
}
