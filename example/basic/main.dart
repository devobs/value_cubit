import 'dart:async';

import 'package:value_cubit/value_cubit.dart';

class CounterCubit extends ValueCubit<int> {
  var _value = 0;
  Future<int> _getCounterValueFromRepository() async => _value++;

  Future<void> refresh() => perform(() async {
        final result = await _getCounterValueFromRepository();

        if (result == 2) {
          throw 'Error';
        } else if (result > 4) {
          emit(const NoValueState());
        } else {
          emit(ValueState(result));
        }
      });
}

main() async {
  final counterCubit = CounterCubit();

  final timer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
    try {
      await counterCubit.refresh();
    } catch (error) {
      // Prevent stop execution for example
    }
  });

  await for (final state in counterCubit.behaviorSubject) {
    if (state is ReadyState<int>) {
      print('State is refreshing: ${state.refreshing}');

      if (state.hasError) {
        print('Error');
      }

      if (state is WithValueState<int>) {
        print('Value : ${state.value}');
      }

      if (state is NoValueState<int>) {
        timer.cancel();
        print('No value');
      }
    } else {
      print('Waiting for value - $state');
    }
  }
}
