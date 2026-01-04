import 'package:too_many_tabs/domain/models/settings/special_goal.dart';

class SpecialGoalSession {
  final SpecialGoal goal;
  final DateTime startedAt;
  final DateTime? stoppedAt;

  const SpecialGoalSession({
    required this.goal,
    required this.startedAt,
    this.stoppedAt,
  });

  bool get isClosed => stoppedAt != null;

  @override
  String toString() {
    return 'SpecialGoalSession('
        'goal: $goal, '
        'startedAt: $startedAt, '
        'stoppedAt: $stoppedAt, '
        'isClosed: $isClosed'
        ')';
  }
}
