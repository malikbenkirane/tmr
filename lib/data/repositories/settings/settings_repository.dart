import 'package:too_many_tabs/domain/models/settings/settings_summary.dart';
import 'package:too_many_tabs/domain/models/settings/special_goal.dart';
import 'package:too_many_tabs/utils/result.dart';

abstract class SettingsRepository {
  Future<Result<SettingsSummary>> getSettings();
  Future<Result<void>> setOverwriteDatabase(bool setting);
  Future<Result<void>> updateSpecialGoal({
    required SpecialGoal setting,
    required Duration goal,
  });
}
