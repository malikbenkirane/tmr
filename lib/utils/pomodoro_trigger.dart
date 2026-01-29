enum PomodoroTrigger { breakPeriod, workPeriod }

extension PomodoroTriggerParsing on String {
  PomodoroTrigger toPomodoroTrigger() {
    switch (this) {
      case 'breakPeriod':
        return PomodoroTrigger.breakPeriod;
      case 'workPeriod':
        return PomodoroTrigger.workPeriod;
      default:
        throw ArgumentError('Invalid PomodoroTrigger string: $this');
    }
  }
}
