class GoalUpdate {
  const GoalUpdate({required int routineID, required Duration goal})
    : _goal = goal,
      _id = routineID;

  final int _id;
  final Duration _goal;

  int get routineID => _id;
  Duration get goal => _goal;
}
