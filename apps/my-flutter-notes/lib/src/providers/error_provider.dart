import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'error_provider.g.dart';

@riverpod
class Error extends _$Error {
  @override
  bool build() {
    return false;
  }

  void setError(bool error) {
    state = error;
  }
}
