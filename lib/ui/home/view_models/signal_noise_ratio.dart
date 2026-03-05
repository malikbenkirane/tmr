class SignalNoiseRatio {
  final double? ratio;
  const SignalNoiseRatio({this.ratio});
  int? get noise => () {
    return ratio == null ? null : (100 / (1 + ratio!)).toInt();
  }();
  bool get meaningful => ratio != null;
}
