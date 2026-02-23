enum NotificationChannel {
  halfSplit,
  pomodoro,
  wrapUp,
  goalCompleted;

  String message() {
    if (index == wrapUp.index) {
      return "All set to wrap things up! 🎉😊";
    }
    if (index == goalCompleted.index) {
      return "Goal completed! 🎉🚀";
    }
    return "";
  }
}

abstract class NotificationChannelId {
  static const pomodoro = 'pomodoro';
}
