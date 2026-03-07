import 'package:too_many_tabs/data/repositories/signal_ratio/signal_ratio_repository.dart';
import 'package:too_many_tabs/data/services/database/database_client.dart';
import 'package:too_many_tabs/ui/home/view_models/signal_noise_ratio.dart';
import 'package:too_many_tabs/utils/result.dart';

class SignalRatioRepositoryLocal implements SignalRatioRepository {
  final DatabaseClient databaseClient;

  const SignalRatioRepositoryLocal({required this.databaseClient});

  @override
  Future<Result<void>> logSignalRatio({
    required SignalRatio r,
    required DateTime at,
  }) {
    return databaseClient.logSignalRatio(at: at, r: r);
  }

  @override
  Future<Result<SignalRatio?>> signalRatioAt(DateTime at) {
    return databaseClient.signalRatioAt(at);
  }
}
