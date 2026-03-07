class SignalRatio {
  final double? ratio;
  final double? overtimeRatio;

  const SignalRatio({this.ratio, this.overtimeRatio});

  int? get noise => () {
    return ratio == null ? null : (100 * (1 - ratio!)).toInt();
  }();

  int? get overtime => () {
    return overtimeRatio == null ? null : (100 * overtimeRatio!).toInt();
  }();

  bool get meaningful => ratio != null;

  static SignalRatio fromIntegerRatios({
    required int signal,
    required int overtime,
  }) {
    return SignalRatio(ratio: signal / 100, overtimeRatio: overtime / 100);
  }

  @override
  String toString() {
    return 'SignalNoiseRatio(noise: $noise, overtime: $overtime) [sr=$ratio or=$overtimeRatio]';
  }
}
