enum SpecialGoal {
  sitBack(column: 'sit_back_goal', code: 1),
  stoke(column: 'stoke_goal', code: 2),
  startSlow(column: 'start_slow_goal', code: 3),
  slowDown(column: 'slow_down_goal', code: 4);

  final String column;
  final int code;
  const SpecialGoal({required this.column, required this.code});
}
