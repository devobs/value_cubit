import 'package:test/test.dart';

import 'package:value_cubit/value_cubit.dart';

var _value = 0;
Future<int> getMyValueFromRepository() async => _value++;

class MyCubit extends ValueCubit<int> {
  @override
  Future<void> emitValues() async {
    final result = await getMyValueFromRepository();

    switch (result) {
      case 2:
        emit(NoValueState());
        break;
      case 3:
      case 4:
        fail('Error');
      default:
        emit(ValueState(result));
    }
  }
}

void main() {
  late MyCubit _myCubit;

  setUp(() {
    _myCubit = MyCubit();
  });

  tearDown(() async {
    await _myCubit.close();
  });

  test('with values incremented', () {
    expect(
        _myCubit.state,
        isA<InitState<int>>().having(
            (state) => state.refreshing, 'init   state not refreshing', false));

    _myCubit.refresh();
    _myCubit.refresh();
    _myCubit.refresh();
    _myCubit.refresh().onError((error, stackTrace) {
      // Ignore error
    });
    _myCubit.refresh().onError((error, stackTrace) {
      // Ignore error
    });
    _myCubit.refresh();
    _myCubit.refresh().then((_) {
      _myCubit.clear();
    });

    // Ensure the current state is [WaitingState] instead of [InitState]
    expect(_myCubit.state, isNot(isA<InitState<int>>()));
    expect(
        _myCubit.state,
        isA<WaitingState<int>>().having((state) => state.refreshing,
            'waiting state not refreshing', false));

    expect(
        _myCubit.stream,
        emitsInOrder([
          isA<ValueState<int>>()
              .having((state) => state.refreshing, 'first value not refreshing',
                  false)
              .having((state) => state.value, 'first value', 0),
          isA<ValueState<int>>()
              .having((state) => state.refreshing,
                  'second value not refreshing', true)
              .having((state) => state.value, 'second value', 0),
          isA<ValueState<int>>()
              .having((state) => state.refreshing,
                  'second value not refreshing', false)
              .having((state) => state.value, 'second value', 1),
          // refresh with no value after value
          isA<ValueState<int>>()
              .having(
                  (state) => state.refreshing, 'second value  refreshing', true)
              .having((state) => state.value, 'second value', 1),
          isA<NoValueState<int>>()
              .having((state) => state.refreshing, 'no value', false),
          isA<NoValueState<int>>()
              .having((state) => state.refreshing, 'no value refreshing', true),
          isA<ErrorState<int>>()
              .having((state) => state.refreshing,
                  'error for third value not refreshing', false)
              .having(
                (state) => state.stateBeforeError,
                'no value before erreur',
                isA<NoValueState<int>>()
                    .having((state) => state.refreshing, 'no value', false),
              )
              .having((state) => state.hasValue, 'second value before erreur',
                  false),
          // refresh with error after error
          isA<ErrorState<int>>().having((state) => state.refreshing,
              'error for third value refreshing', true),
          isA<ErrorState<int>>()
              .having((state) => state.refreshing,
                  'error for fourth value not refreshing', false)
              .having(
                (state) => state.stateBeforeError,
                'no value before erreur',
                isA<NoValueState<int>>()
                    .having((state) => state.refreshing, 'no value', false),
              )
              .having((state) => state.hasValue, 'second value before erreur',
                  false),
          // refresh after arror
          isA<ErrorState<int>>().having((state) => state.refreshing,
              'error for fourth value refreshing', true),
          isA<ValueState<int>>()
              .having((state) => state.refreshing, 'fifth value not refreshing',
                  false)
              .having((state) => state.value, 'fifth value ', 5),
          isA<ValueState<int>>()
              .having(
                  (state) => state.refreshing, 'fifth value refreshing', true)
              .having((state) => state.value, 'fifth value', 5),
          isA<ValueState<int>>()
              .having(
                  (state) => state.refreshing, 'sixth value refreshing', false)
              .having((state) => state.value, 'sixth value', 6),
          // _myRefresh.clear()
          isA<WaitingState<int>>(),
        ]));
  });

  test('equalities and hash', () {
    // Dont create object with [const] to avoid [identical] return true
    final initState1 = InitState<int>(), initState2 = InitState<int>();

    expect(initState1, initState2);
    expect(initState1.hashCode, initState2.hashCode);

    final waitingState1 = WaitingState<int>(),
        waitingState2 = WaitingState<int>();

    expect(waitingState1, waitingState2);
    expect(waitingState1.hashCode, waitingState2.hashCode);

    expect(waitingState1.mayRefreshing(), waitingState1);
    expect(waitingState1.mayNotRefreshing(), waitingState2);

    final noValueState1 = NoValueState<int>(),
        noValueState2 = NoValueState<int>();

    expect(noValueState1, noValueState2);
    expect(noValueState1.hashCode, noValueState2.hashCode);

    final valueState1 = ValueState<int>(0), valueState2 = ValueState<int>(0);

    expect(valueState1, valueState2);
    expect(valueState1.hashCode, valueState2.hashCode);

    final errorState1 =
            ErrorState<int>(previousState: InitState(), error: 'Error'),
        errorState2 =
            ErrorState<int>(previousState: InitState(), error: 'Error');

    expect(errorState1, errorState2);
    expect(errorState1.hashCode, errorState2.hashCode);
  });

  test('visitor', () {
    const _visitor = _TestStateVisitor();

    expect(const InitState().accept(_visitor), 1);
    expect(const WaitingState().accept(_visitor), 4);
    expect(const NoValueState().accept(_visitor), 2);
    expect(const ValueState(0).accept(_visitor), 3);
    expect(
        ErrorState(previousState: InitState(), error: 'Error').accept(_visitor),
        0);
  });
}

class _TestStateVisitor extends StateVisitor<int, int> {
  const _TestStateVisitor();

  @override
  visitErrorState(ErrorState state) => 0;

  @override
  visitInitState(InitState state) => 1;

  @override
  visitNoValueState(NoValueState state) => 2;

  @override
  visitValueState(ValueState valueState) => 3;

  @override
  visitWaitingState(WaitingState state) => 4;
}
