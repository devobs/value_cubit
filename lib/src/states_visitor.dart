part of 'states.dart';

/// For [WaitingState], transform in right state when starting actions.
/// For [ReadyState], try to enable/disable [ReadyState.refreshing] attribute.
class RefreshActivationVisitor<T> extends StateVisitor<BaseState<T>, T> {
  final bool mayRefreshing;

  const RefreshActivationVisitor({required this.mayRefreshing});

  @override
  BaseState<T> visitInitState(InitState<T> state) => PendingState<T>();

  @override
  BaseState<T> visitPendingState(PendingState<T> state) => state;

  @override
  BaseState<T> visitValueState(ValueState<T> state) =>
      ValueState<T>(state.value, refreshing: mayRefreshing);

  @override
  BaseState<T> visitNoValueState(NoValueState<T> state) =>
      NoValueState<T>(refreshing: mayRefreshing);

  @override
  BaseState<T> visitErrorState(ErrorState<T> state) => ErrorState<T>(
        previousState: state.stateBeforeError,
        refreshing: mayRefreshing,
        error: state.error,
        stackTrace: state.stackTrace,
      );
}
