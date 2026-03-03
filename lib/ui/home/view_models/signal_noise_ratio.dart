class SignalNoiseRatio {
  final double? ratio;
  const SignalNoiseRatio({this.ratio});
  double? get noise => () {
    return ratio == null ? null : 1 / (1 + ratio!);
  }();
  bool get meaningful => ratio != null;
}
