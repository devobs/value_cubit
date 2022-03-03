import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';

import 'states.dart';

/// Shared implementation to handle refresh capability on cubit
abstract class ValueCubit<T> extends Cubit<BaseState<T>>
    with CubitValueStateMixin {
  ValueCubit() : super(InitState<T>());

  /// Refresh the cubit state.
  Future<void> refresh() async {
    await perform(emitValues);
  }

  /// Init the state of cubit.
  void clear() {
    emit(WaitingState<T>());
  }

  /// Get the value here and emit a [ValueState] if success.
  @protected
  Future<void> emitValues();
}

mixin CubitValueStateMixin<T> on Cubit<BaseState<T>> {
  final _lock = Lock(reentrant: true);

  /// Handle states (waiting, refreshing, error...) while and [action] is
  /// processed.
  /// If [errorAsState] is true and [action] raise an exception then an
  /// [ErrorState] is emitted. if false, nothing is emitted.
  @protected
  Future<R> perform<R>(FutureOr<R> Function() action,
          {bool errorAsState = true}) =>
      _lock.synchronized(() async {
        try {
          final stateRefreshing = state.mayRefreshing();
          if (state != stateRefreshing) emit(stateRefreshing);

          return await action();
        } catch (error, stackTrace) {
          if (errorAsState) {
            emit(ErrorState<T>(
                previousState: state.mayNotRefreshing(),
                error: error,
                stackTrace: stackTrace));
          }
          rethrow;
        } finally {
          final stateRefreshingEnd = state.mayNotRefreshing();

          if (state != stateRefreshingEnd) emit(stateRefreshingEnd);
        }
      });
}
