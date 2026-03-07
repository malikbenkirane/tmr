import 'package:too_many_tabs/ui/home/view_models/signal_noise_ratio.dart';
import 'package:too_many_tabs/utils/result.dart';

abstract class SignalRatioRepository {
  Future<Result<void>> logSignalRatio({
    required SignalRatio r,
    required DateTime at,
  });
  Future<Result<SignalRatio?>> signalRatioAt(DateTime at);
}
