import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/goals/data/goals_repository.dart';
import '../../features/tasks/data/tasks_repository.dart';
import '../../features/study_log/data/study_log_repository.dart';
import '../../features/review/data/review_repository.dart';
import '../../features/focus/data/focus_repository.dart';
import '../../features/stats/data/stats_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../auth/auth_global.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Storage
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // Auth global state
  getIt.registerLazySingleton<AuthGlobal>(
    () => AuthGlobal(getIt<FlutterSecureStorage>()),
  );

  // API Client
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(getIt<FlutterSecureStorage>(), getIt<AuthGlobal>()),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<ApiClient>(), getIt<FlutterSecureStorage>(), getIt<AuthGlobal>()),
  );

  getIt.registerLazySingleton<GoalsRepository>(
    () => GoalsRepository(getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<TasksRepository>(
    () => TasksRepository(getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<StudyLogRepository>(
    () => StudyLogRepository(getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<ReviewRepository>(
    () => ReviewRepository(getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<FocusRepository>(
    () => FocusRepository(getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<StatsRepository>(
    () => StatsRepository(getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository(getIt<ApiClient>()),
  );
}
