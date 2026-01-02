import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:too_many_tabs/data/repositories/settings/settings_repository.dart';
import 'package:too_many_tabs/domain/models/settings/settings_summary.dart';
import 'package:too_many_tabs/ui/settings/view_models/special_goal_setting_update.dart';
import 'package:too_many_tabs/utils/command.dart';
import 'package:too_many_tabs/utils/result.dart';

class SettingsViewmodel extends ChangeNotifier {
  SettingsViewmodel({required SettingsRepository repository})
    : _repository = repository {
    load = Command0(_load)..execute();
    switchOverwriteDatabase = Command0(_switchOverwriteDatabase);
    updateSpecialGoalSetting = Command1(_updateSpecialGoalSetting);
  }
  final SettingsRepository _repository;
  SettingsSummary? _settings;
  SettingsSummary get settings => _settings!;
  final _log = Logger('SettingsViewmodel');

  late Command0 load;
  late Command0 switchOverwriteDatabase;
  late Command1<void, SpecialGoalSettingUpdate> updateSpecialGoalSetting;

  Future<Result> _load() async {
    try {
      final resultGet = await _repository.getSettings();
      switch (resultGet) {
        case Error<SettingsSummary>():
          _log.warning('_repository: getSettings: ${resultGet.error}');
          return Result.error(resultGet.error);
        case Ok<SettingsSummary>():
          _settings = resultGet.value;
          _log.fine('loaded settings $settings');
      }
      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> _switchOverwriteDatabase() async {
    try {
      final resultSet = await _repository.setOverwriteDatabase(
        !_settings!.overwriteDatabase,
      );
      switch (resultSet) {
        case Error<void>():
          _log.warning('_switchOverwriteDatabase: ${resultSet.error}');
          return Result.error(resultSet.error);
        case Ok<void>():
      }
      await _load();
      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> _updateSpecialGoalSetting(
    SpecialGoalSettingUpdate update,
  ) async {
    try {
      final result = await _repository.updateSpecialGoal(
        setting: update.setting,
        goal: update.goal,
      );
      switch (result) {
        case Ok<void>():
          _log.fine("_updateSpecialGoalSetting: $update");
          _settings!.set(update.setting, update.goal);
          break;
        case Error<void>():
          _log.warning("_updateSpecialGoalSetting: $result.error");
      }
      return result;
    } finally {
      notifyListeners();
    }
  }
}
