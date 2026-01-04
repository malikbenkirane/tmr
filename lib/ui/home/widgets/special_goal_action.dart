import 'package:flutter/widgets.dart';
import 'package:too_many_tabs/domain/models/settings/special_goal.dart';

class SpecialGoalAction {
  const SpecialGoalAction({required this.goal, required this.symbol});
  final IconData symbol;
  final SpecialGoal goal;
}
