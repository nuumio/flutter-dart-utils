// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'display_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DisplaySettings _$DisplaySettingsFromJson(Map<String, dynamic> json) {
  return _DisplaySettings.fromJson(json);
}

/// @nodoc
mixin _$DisplaySettings {
  ThemeMode get themeMode => throw _privateConstructorUsedError;

  /// Serializes this DisplaySettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DisplaySettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DisplaySettingsCopyWith<DisplaySettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DisplaySettingsCopyWith<$Res> {
  factory $DisplaySettingsCopyWith(
          DisplaySettings value, $Res Function(DisplaySettings) then) =
      _$DisplaySettingsCopyWithImpl<$Res, DisplaySettings>;
  @useResult
  $Res call({ThemeMode themeMode});
}

/// @nodoc
class _$DisplaySettingsCopyWithImpl<$Res, $Val extends DisplaySettings>
    implements $DisplaySettingsCopyWith<$Res> {
  _$DisplaySettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DisplaySettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? themeMode = null,
  }) {
    return _then(_value.copyWith(
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as ThemeMode,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DisplaySettingsImplCopyWith<$Res>
    implements $DisplaySettingsCopyWith<$Res> {
  factory _$$DisplaySettingsImplCopyWith(_$DisplaySettingsImpl value,
          $Res Function(_$DisplaySettingsImpl) then) =
      __$$DisplaySettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({ThemeMode themeMode});
}

/// @nodoc
class __$$DisplaySettingsImplCopyWithImpl<$Res>
    extends _$DisplaySettingsCopyWithImpl<$Res, _$DisplaySettingsImpl>
    implements _$$DisplaySettingsImplCopyWith<$Res> {
  __$$DisplaySettingsImplCopyWithImpl(
      _$DisplaySettingsImpl _value, $Res Function(_$DisplaySettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of DisplaySettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? themeMode = null,
  }) {
    return _then(_$DisplaySettingsImpl(
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as ThemeMode,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DisplaySettingsImpl extends _DisplaySettings {
  const _$DisplaySettingsImpl({this.themeMode = ThemeMode.system}) : super._();

  factory _$DisplaySettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$DisplaySettingsImplFromJson(json);

  @override
  @JsonKey()
  final ThemeMode themeMode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DisplaySettingsImpl &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, themeMode);

  /// Create a copy of DisplaySettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DisplaySettingsImplCopyWith<_$DisplaySettingsImpl> get copyWith =>
      __$$DisplaySettingsImplCopyWithImpl<_$DisplaySettingsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DisplaySettingsImplToJson(
      this,
    );
  }
}

abstract class _DisplaySettings extends DisplaySettings {
  const factory _DisplaySettings({final ThemeMode themeMode}) =
      _$DisplaySettingsImpl;
  const _DisplaySettings._() : super._();

  factory _DisplaySettings.fromJson(Map<String, dynamic> json) =
      _$DisplaySettingsImpl.fromJson;

  @override
  ThemeMode get themeMode;

  /// Create a copy of DisplaySettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DisplaySettingsImplCopyWith<_$DisplaySettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
