class SignalNoiseRatio {
  final double? ratio;
  final double? overtimeRatio;

  const SignalNoiseRatio({this.ratio, this.overtimeRatio});

  int? get noise => () {
    return ratio == null ? null : (100 / (1 + ratio!)).toInt();
  }();

  int? get overtime => () {
    return overtimeRatio == null ? null : (100 / (1 + overtimeRatio!)).toInt();
  }();

  bool get meaningful => ratio != null;

  @override
  String toString() {
    return 'SignalNoiseRatio(noise: $noise, overtime: $overtime)';
  }
}
