import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/core/app/local_storage/local_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:frontend/core/app/di/injections.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: false,
  asExtension: false,
)
Future<void> configureDependencies() async {
  await LocalStorage.init();
  await dotenv.load(fileName: ".env");
  $initGetIt(getIt);
}
