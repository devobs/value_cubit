A dart package that helps implements basic states for [BLoC library](https://pub.dev/packages/bloc).


[![pub package](https://img.shields.io/pub/v/value_cubit.svg)](https://pub.dev/packages/value_cubit)
[![Test](https://github.com/devobs/value_cubit/actions/workflows/test.yml/badge.svg)](https://github.com/devobs/value_cubit/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/devobs/value_cubit/branch/main/graph/badge.svg?token=reuUbDNsC1)](https://codecov.io/gh/devobs/value_cubit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

* Provides all states to handle init, waiting, value/no value and error states
* A `ValueCubit` class to manage standards states and refreshing capabilities

## Usage

```dart
class MyCubit extends ValueCubit<int> {
  @override
  Future<void> emitValues() async {
    final result = await getMyValueFromRepository();

    emit(ValueState(result));
  }
}

main() async {
  final myCubit = MyCubit();

  myCubit.refresh();

  await for (final state in myCubit.stream) {
    if (state is WaitingState<int>) {
      // do stuff for waiting
    } else if (state is ValueState<int>) {
      // do stuff with value
    } else if (state is ErrorState<int>) {
      // handle error
    }
  }

  // you can refresh values
}
```

## Feedback

Please file any issues, bugs or feature requests as an issue on the [Github page](https://github.com/devobs/value_cubit/issues).
