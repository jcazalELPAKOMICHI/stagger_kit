import 'package:flutter/foundation.dart';

/// A command broadcast by a [StaggerController].
enum StaggerCommand {
  /// Animate in from wherever the items currently are.
  play,

  /// Jump back to the start and animate in again, keeping the stagger.
  replay,

  /// Animate out.
  reverse,

  /// Jump back to the start without animating.
  reset,
}

/// Drives a group of stagger items at once.
///
/// Pass the same controller to every item (or to `List<Widget>.stagger()` /
/// `StaggerScope`) and call [replay], [reverse], etc. to control them all.
///
/// ```dart
/// final controller = StaggerController();
///
/// Column(children: fields.stagger(controller: controller));
///
/// controller.replay();
/// ```
class StaggerController extends ChangeNotifier {
  StaggerCommand? _command;

  /// The most recent command, or null if none was sent yet.
  StaggerCommand? get command => _command;

  /// Animates every item in from its current position.
  void play() => _send(StaggerCommand.play);

  /// Restarts every item from the beginning, with the original delays.
  void replay() => _send(StaggerCommand.replay);

  /// Animates every item out.
  void reverse() => _send(StaggerCommand.reverse);

  /// Hides every item immediately.
  void reset() => _send(StaggerCommand.reset);

  void _send(StaggerCommand command) {
    _command = command;
    notifyListeners();
  }
}
