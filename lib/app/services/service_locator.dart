import 'package:get_it/get_it.dart';
import 'package:qadam_app/app/services/step_counter_service.dart';

import 'coin_service.dart';

final GetIt serviceLocator = GetIt.instance;

void setupServiceLocator() {
  serviceLocator.registerLazySingleton<StepCounterService>(
    () => StepCounterService(),
  );
  serviceLocator.registerLazySingleton<CoinService>(
    () => CoinService(),
  );
}