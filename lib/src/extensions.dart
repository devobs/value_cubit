import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:stream_transform/stream_transform.dart';

import 'cubit.dart';
import 'states.dart';

/// Shortcut to use [RefreshActivationVisitor].
extension RefreshingExtensions<T> on BaseState<T> {
  /// Copy the actual object and according to the state can enable refreshing
  BaseState<T> mayRefreshing() =>
      accept(RefreshActivationVisitor<T>(mayRefreshing: true));

  /// Copy the actual object and according to the state can disable refreshing
  BaseState<T> mayNotRefreshing() =>
      accept(RefreshActivationVisitor<T>(mayRefreshing: false));
}

/// Extensions for cubit to
extension StateAndStream<T> on Cubit<T> {
  /// Get a new stream with current state as first value and the following
  /// values
  Stream<T> get behaviorSubject => Stream.value(state).followedBy(stream);
}

typedef WaitingMapperType<T> = BaseState<T>? Function();
typedef RefreshingyMapperType<T> = BaseState<T>? Function(bool refreshing);
typedef ErrorMapperType<T, F> = BaseState<T>? Function(
    ErrorState<F> errorState);

/// This mixin help to listen a stream an then update the current cubit
mixin StreamInputCubitMixin<T, EVENT> on ValueCubit<T> {
  late StreamSubscription _refreshStreamSubscription;

  /// Listen the [stream] and call [emitValuesFromStream] for every event.
  @protected
  void listenRefreshStream(Stream<EVENT> stream,
      Future<void> Function(EVENT event) emitValuesFromStream) {
    _refreshStreamSubscription = stream.listen(emitValuesFromStream);
  }

  @override
  Future<void> close() async {
    await _refreshStreamSubscription.cancel();
    return super.close();
  }

  /// Helper to map from a state to other state. Useful to map "default" states
  /// from original stream.
  /// The [map] argument contains a function that map the origin event from the
  /// stream to the value.  If `null` is returned, then a [NoValueState] is
  /// emitted. Else a [ValueState] is emitted with the value returned inside.
  /// [fromState] is the origin state to map.
  /// If the optional parameter [refreshingWithCurrentState] is `true` (default
  /// value), then the cubit emit the current state refreshing if original
  /// stream emit a refreshing state. Else, the refreshing is mapped from
  /// original stream.
  /// [mapInit], [mapPending], [mapNoValue] and [mapError] override the default
  /// behavior of the mapper.
  void emitMappedState<F>(
    T? Function(F from) map,
    BaseState<F> fromState, {
    bool refreshingWithCurrentState = true,
    WaitingMapperType<T>? mapInit,
    WaitingMapperType<T>? mapPending,
    RefreshingyMapperType<T>? mapNoValue,
    ErrorMapperType<T, F>? mapError,
  }) {
    emit(fromState.accept<BaseState<T>>(_MappedStateVisitor<F, T>(
      map,
      currentState: refreshingWithCurrentState ? state : null,
      mapInit: mapInit,
      mapPending: mapPending,
      mapNoValue: mapNoValue,
      mapError: mapError,
    )));
  }
}

/// A visitor to map de state to other state.
class _MappedStateVisitor<F, T> implements StateVisitor<BaseState<T>, F> {
  /// Function that map the origin event from the stream to the value
  /// If `null` is returned, then a [NoValueState] is emitted. Else a
  /// [ValueState] is emitted with the value returned inside.
  final T? Function(F from) mapValue;

  final BaseState<T>? currentState;

  final WaitingMapperType<T>? mapInit;
  final WaitingMapperType<T>? mapPending;
  final RefreshingyMapperType<T>? mapNoValue;
  final ErrorMapperType<T, F>? mapError;

  _MappedStateVisitor(
    this.mapValue, {
    required this.currentState,
    required this.mapInit,
    required this.mapPending,
    required this.mapNoValue,
    required this.mapError,
  });

  @override
  BaseState<T> visitInitState(InitState<F> state) =>
      _applyMap((_) => mapInit?.call(), state) ?? InitState<T>();

  @override
  BaseState<T> visitPendingState(PendingState<F> state) =>
      _applyMap((_) => mapPending?.call(), state) ?? PendingState<T>();

  @override
  BaseState<T> visitValueState(ValueState<F> state) {
    final currentStateRefreshing = _returnCurrentStateRefreshing(state);
    if (currentStateRefreshing != null) {
      return currentStateRefreshing;
    }

    final mapped = mapValue(state.value);

    if (mapped == null) {
      return NoValueState<T>(refreshing: state.refreshing);
    }

    return ValueState<T>(mapped, refreshing: state.refreshing);
  }

  @override
  BaseState<T> visitNoValueState(NoValueState<F> state) =>
      _applyMap(mapNoValue, state) ??
      NoValueState<T>(refreshing: state.refreshing);

  @override
  BaseState<T> visitErrorState(ErrorState<F> errorState) {
    if (mapError != null) {
      final result = mapError!(errorState);

      if (result != null) return result;
    }

    return _returnCurrentStateRefreshing(errorState) ??
        ErrorState<T>(
          error: errorState.error,
          stackTrace: errorState.stackTrace,
          refreshing: errorState.refreshing,
          previousState: currentState ??
              errorState.stateBeforeError.accept(
                _MappedStateVisitor(mapValue,
                    currentState: currentState,
                    mapInit: mapInit,
                    mapPending: mapPending,
                    mapNoValue: mapNoValue,
                    mapError: mapError),
              ),
        );
  }

  BaseState<T>? _returnCurrentStateRefreshing(BaseState<F> state) =>
      state is ReadyState<F> && state.refreshing && currentState != null
          ?
          // Prefer using the current state refreshing before display the new
          // value
          currentState!.mayRefreshing()
          : null;

  BaseState<T>? _applyMap(
      RefreshingyMapperType<T>? mapper, BaseState<F> state) {
    if (mapper != null) {
      return mapper(state is ReadyState<F> && state.refreshing);
    }
    return _returnCurrentStateRefreshing(state);
  }
}
