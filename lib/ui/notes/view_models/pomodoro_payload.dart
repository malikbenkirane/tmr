class PomodoroPayload {
  final String onTap; // PomodoroTrigger.name
  final int routineId;

  const PomodoroPayload({required this.onTap, required this.routineId});
}
