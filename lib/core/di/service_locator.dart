import 'package:app_screenshots/core/services/command_server.dart';
import 'package:app_screenshots/core/services/file_open_service.dart';
import 'package:app_screenshots/core/services/icloud_backup_service.dart';
import 'package:app_screenshots/core/services/icloud_sync_service.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/asc_upload_service.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/design_file_service.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/asc_upload_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/data/repositories/ai_provider_repository_impl.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/screenshot_persistence_service.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/template_persistence_service.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/translation_memory_service.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/translation_service.dart';
import 'package:app_screenshots/features/screenshot_editor/domain/repositories/ai_provider_repository.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:app_screenshots/features/settings/presentation/cubit/backup_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_library_cubit.dart';
import 'package:app_screenshots/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:app_screenshots/features/settings/data/services/app_icon_service.dart';
import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';
import 'package:app_screenshots/features/settings/presentation/cubit/app_icon_cubit.dart';
import 'package:app_screenshots/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  await _registerExternalDeps();
  final syncService = await _registerCloudSync();
  _registerServices(syncService);
  _registerRepositories();
  _registerCubits();
}

// ─────────────────────────────────────────────────────────────────────────────
// External / platform dependencies
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _registerExternalDeps() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Cloud sync (order-sensitive — must come before services)
// ─────────────────────────────────────────────────────────────────────────────

Future<ICloudSyncService> _registerCloudSync() async {
  final syncService = ICloudSyncService(sl<SharedPreferences>());
  await syncService.init();
  sl.registerSingleton<ICloudSyncService>(syncService);
  return syncService;
}

// ─────────────────────────────────────────────────────────────────────────────
// Services
// ─────────────────────────────────────────────────────────────────────────────

void _registerServices(ICloudSyncService syncService) {
  sl.registerLazySingleton(
    () => ScreenshotPersistenceService(storageRoot: syncService.designsPath),
  );
  sl.registerLazySingleton(
    () => TemplatePersistenceService(
      storageRoot: '${syncService.designsPath}/screenshot_templates',
    ),
  );
  sl.registerLazySingleton(() => AppIconService());
  sl.registerLazySingleton(
    () => ICloudBackupService(sl(), storageRoot: syncService.designsPath),
  );
  sl.registerLazySingleton(() => FileOpenService()..init());
  sl.registerLazySingleton(() => TranslationMemoryService());
  sl.registerLazySingleton(() => TranslationService(sl(), sl()));
  sl.registerLazySingleton(() => AscUploadService(sl()));
  sl.registerLazySingleton(() => DesignFileService());
  sl.registerLazySingleton(
    () => CommandServer(persistenceService: sl(), designFileService: sl()),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Repositories
// ─────────────────────────────────────────────────────────────────────────────

void _registerRepositories() {
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<AIProviderRepository>(
    () => AIProviderRepositoryImpl(sl(), sl()),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Cubits
// ─────────────────────────────────────────────────────────────────────────────

void _registerCubits() {
  sl.registerFactory(() => ThemeCubit(sl()));
  sl.registerFactory(
    () => ScreenshotEditorCubit(persistenceService: sl(), prefs: sl()),
  );
  sl.registerFactory(
    () => ScreenshotLibraryCubit(persistenceService: sl(), syncService: sl()),
  );
  sl.registerFactory(() => TranslationCubit(sl()));
  sl.registerFactory(() => AscUploadCubit(sl(), sl()));
  sl.registerLazySingleton(() => AppIconCubit(sl(), sl())..load());
  sl.registerLazySingleton(() => BackupCubit(sl())..init());
}
