// write a string for this in dart you only output dart code (no need for ```dart)
enum NotificationCode {
  routineHalfGoal(0),
  routineCompletedGoal(1),
  routineGoalIn10Minutes(2),
  routineGoalIn5Minutes(3),
  routineSettleCheck(4),
  test(5),
  specialGoalStoke50(6),
  specialGoalStoke90(7),
  specialGoalSitback50(8),
  specialGoalSitback5(10),
  specialGoalSitback15(11),
  specialGoalSitback100(12),
  specialGoalStartSlow33(13),
  specialGoalStartSlow66(14),
  specialGoalStartSlow100(15);

  const NotificationCode(this.code);

  final int code;
}

extension NotificationCodeExtension on NotificationCode {
  /// Returns a human‑readable string for each enum value.
  String get description {
    switch (this) {
      case NotificationCode.routineHalfGoal:
        return 'Routine half goal';
      case NotificationCode.routineCompletedGoal:
        return 'Routine completed goal';
      case NotificationCode.routineGoalIn10Minutes:
        return 'Routine goal in 10 minutes';
      case NotificationCode.routineGoalIn5Minutes:
        return 'Routine goal in 5 minutes';
      case NotificationCode.routineSettleCheck:
        return 'Routine settle check';
      case NotificationCode.test:
        return 'Test';
      case NotificationCode.specialGoalStoke50:
        return 'Special goal: Stoke 50';
      case NotificationCode.specialGoalStoke90:
        return 'Special goal: Stoke 90';
      case NotificationCode.specialGoalSitback50:
        return 'Special goal: Sitback 50';
      case NotificationCode.specialGoalSitback5:
        return 'Special goal: Sitback 5';
      case NotificationCode.specialGoalSitback15:
        return 'Special goal: Sitback 15';
      case NotificationCode.specialGoalSitback100:
        return 'Special goal: Sitback 100';
      case NotificationCode.specialGoalStartSlow33:
        return 'Special goal: Start slow 33%';
      case NotificationCode.specialGoalStartSlow66:
        return 'Special goal: Start slow 66%';
      case NotificationCode.specialGoalStartSlow100:
        return 'Special goal: Start slow 100%';
    }
  }

  /// Returns a formatted string combining the enum name and its code.
  String get formatted => '${name.toString()}($code) – $description';
}
