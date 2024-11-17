import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'display_settings.freezed.dart';
part 'display_settings.g.dart';

@freezed
class DisplaySettings with _$DisplaySettings {
  const DisplaySettings._();

  const factory DisplaySettings({
    @Default(ThemeMode.system) ThemeMode themeMode,
  }) = _DisplaySettings;

  @override
  String toString() => 'DisplaySettings(themeMode: $themeMode)';

  factory DisplaySettings.fromJson(Map<String, dynamic> json) =>
      _$DisplaySettingsFromJson(json);
}
