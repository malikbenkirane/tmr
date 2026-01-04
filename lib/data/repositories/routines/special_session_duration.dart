class SpecialSessionDuration {
  const SpecialSessionDuration({required this.duration, required this.current});
  final Duration duration;
  final DateTime? current;

  @override
  String toString() =>
      'SpecialSessionDuration(duration: $duration, current: $current)';
}
