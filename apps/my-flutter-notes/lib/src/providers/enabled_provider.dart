import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'enabled_provider.g.dart';

@riverpod
class Enabled extends _$Enabled {
  @override
  bool build() {
    return true;
  }

  void setEnabled(bool enabled) {
    state = enabled;
  }
}
