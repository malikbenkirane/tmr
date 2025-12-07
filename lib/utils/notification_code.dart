enum NotificationCode {
  routineHalfGoal(0),
  routineCompletedGoal(1),
  routineGoalIn5Minutes(3),
  routineGoalIn10Minutes(2);

  const NotificationCode(this.code);

  final int code;
}
