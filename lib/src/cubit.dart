import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';
import 'package:value_cubit/value_cubit.dart';

import 'states.dart';

/// Shortbut to user [BaseState] with [Cubit]
abstract class ValueCubit<T> extends Cubit<BaseState<T>>
    with CubitValueStateMixin {
  ValueCubit() : super(InitState<T>());
}

/// Shared implementation to handle refresh capability on cubit
abstract class RefreshValueCubit<T> extends ValueCubit<T>
    with CubitValueStateMixin {
  RefreshValueCubit();

  /// Refresh the cubit state.
  Future<void> refresh() async {
    await perform(emitValues);
  }

  /// Init the state of cubit.
  void clear() {
    emit(PendingState<T>());
  }

  /// Get the value here and emit a [ValueState] if success.
  @protected
  Future<void> emitValues();
}

mixin CubitValueStateMixin<T> on Cubit<BaseState<T>> {
  final _lock = Lock(reentrant: true);

  /// Handle states (waiting, refreshing, error...) while an [action] is
  /// processed.
  /// If [errorAsState] is `true` and [action] raise an exception then an
  /// [ErrorState] is emitted. if `false`, nothing is emitted. The exception
  /// is always rethrown by [perform] to be handled by the caller.
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

/// Execute [CubitValueStateMixin.perform] on each cubit of a list.
/// Useful for cubits that are suscribed to others.
Future<R> performOnIterable<R>(
    Iterable<ValueCubit> cubits, FutureOr<R> Function() action,
    {bool errorAsState = true}) async {
  if (cubits.isEmpty) {
    return await action();
  }

  return performOnIterable<R>(cubits.skip(1),
      () => cubits.first.perform<R>(action, errorAsState: errorAsState),
      errorAsState: errorAsState);
}
