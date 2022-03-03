/// Base class for handling value states.
abstract class BaseState<T> {
  const BaseState();

  /// This property indicate an action is processing and a new state
  /// [ValueState], [NoValueState] or [ErrorState] will be emitted.
  bool get refreshing;

  /// Copy the actual object and according to the state can enable refreshing
  BaseState<T> mayRefreshing();

  /// Copy the actual object and according to the state can disable refreshing
  BaseState<T> mayNotRefreshing();

  /// Visitor pattern to enhance class capabilities
  R accept<R>(StateVisitor<R, T> visitor);
}

/// State with no value (support null safety).
class NoValueState<T> extends BaseState<T> {
  const NoValueState({this.refreshing = false});

  @override
  final bool refreshing;

  @override
  NoValueState<T> mayRefreshing() => NoValueState<T>(refreshing: true);
  @override
  NoValueState<T> mayNotRefreshing() => NoValueState<T>(refreshing: false);

  @override
  R accept<R>(StateVisitor<R, T> visitor) => visitor.visitNoValueState(this);

  @override
  bool operator ==(other) =>
      identical(this, other) ||
      runtimeType == other.runtimeType &&
          other is NoValueState<T> &&
          refreshing == other.refreshing;
  @override
  int get hashCode => refreshing.hashCode;
}

/// State for waiting value and there was no [ValueState] or [NoValueState]
/// before. Therefore [refreshing] is always false.
/// Useful to handle waiting page before first value is displayed or when
/// a user is disconnected.
class WaitingState<T> extends BaseState<T> {
  const WaitingState();

  @override
  bool get refreshing => false;

  @override
  WaitingState<T> mayRefreshing() => this;
  @override
  WaitingState<T> mayNotRefreshing() => this;

  @override
  R accept<R>(StateVisitor<R, T> visitor) => visitor.visitWaitingState(this);

  @override
  bool operator ==(other) =>
      identical(this, other) ||
      runtimeType == other.runtimeType &&
          other is WaitingState<T> &&
          refreshing == other.refreshing;
  @override
  int get hashCode => refreshing.hashCode;
}

/// Initial state before any processing. If all has been intialized and
/// the action to get the value is started, then emit a [WaitingState]
class InitState<T> extends WaitingState<T> {
  const InitState();

  @override
  WaitingState<T> mayRefreshing() => WaitingState<T>();

  @override
  R accept<R>(StateVisitor<R, T> visitor) => visitor.visitInitState(this);

  @override
  bool operator ==(other) =>
      identical(this, other) ||
      runtimeType == other.runtimeType &&
          other is InitState<T> &&
          refreshing == other.refreshing;
  @override
  int get hashCode => refreshing.hashCode;
}

/// State that provide the value.
class ValueState<T> extends BaseState<T> {
  const ValueState(this.value, {this.refreshing = false});

  /// Value associated with state
  final T value;

  @override
  final bool refreshing;

  @override
  ValueState<T> mayRefreshing() => ValueState<T>(value, refreshing: true);
  @override
  ValueState<T> mayNotRefreshing() => ValueState<T>(value, refreshing: false);

  @override
  R accept<R>(StateVisitor<R, T> visitor) => visitor.visitValueState(this);

  @override
  bool operator ==(other) =>
      identical(this, other) ||
      runtimeType == other.runtimeType &&
          other is ValueState<T> &&
          refreshing == other.refreshing &&
          value == other.value;
  @override
  int get hashCode => Object.hash(refreshing, value);
}

/// State for error (maybe linked with a [ValueState] or not)
class ErrorState<T> extends BaseState<T> {
  factory ErrorState(
          {required BaseState<T> previousState,
          required Object error,
          StackTrace? stackTrace}) =>
      ErrorState._(
          stateBeforeError: _consumePreviousErrors<T>(previousState),
          error: error,
          stackTrace: stackTrace,
          refreshing: false);

  const ErrorState._(
      {required this.error,
      required this.stackTrace,
      required this.stateBeforeError,
      required this.refreshing});

  /// Previous state that is not [ErrorState]. If several errors are
  /// triggered, they are also ignored.
  final BaseState<T> stateBeforeError;

  /// The error object.
  final Object error;

  /// The error stack trace.
  final StackTrace? stackTrace;

  /// Current error has previous value
  bool get hasValue => stateBeforeError is ValueState<T>;

  static BaseState<T> _consumePreviousErrors<T>(state) => state is ErrorState<T>
      ? _consumePreviousErrors<T>(state.stateBeforeError)
      : state;

  @override
  ErrorState<T> mayRefreshing() => ErrorState._(
      stateBeforeError: stateBeforeError,
      error: error,
      stackTrace: stackTrace,
      refreshing: true);
  @override
  ErrorState<T> mayNotRefreshing() => ErrorState._(
      stateBeforeError: stateBeforeError,
      error: error,
      stackTrace: stackTrace,
      refreshing: false);

  @override
  final bool refreshing;

  @override
  R accept<R>(StateVisitor<R, T> visitor) => visitor.visitErrorState(this);

  @override
  bool operator ==(other) =>
      identical(this, other) ||
      runtimeType == other.runtimeType &&
          other is ErrorState<T> &&
          refreshing == other.refreshing &&
          error == other.error &&
          stackTrace == other.stackTrace &&
          stateBeforeError == other.stateBeforeError;
  @override
  int get hashCode =>
      Object.hash(refreshing, error, stackTrace, stateBeforeError);
}

/// Visitor base class to enhance states capabilities
abstract class StateVisitor<R, T> {
  const StateVisitor();

  R visitNoValueState(NoValueState<T> state);

  R visitWaitingState(WaitingState<T> state);

  R visitInitState(InitState<T> state);

  R visitErrorState(ErrorState<T> state);

  R visitValueState(ValueState<T> valueState);
}
