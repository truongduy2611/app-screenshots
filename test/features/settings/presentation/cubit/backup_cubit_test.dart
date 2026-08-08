import 'package:app_screenshots/core/services/icloud_backup_service.dart';
import 'package:app_screenshots/core/services/icloud_sync_service.dart';
import 'package:app_screenshots/features/settings/presentation/cubit/backup_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockICloudBackupService extends Mock implements ICloudBackupService {}

class MockICloudSyncService extends Mock implements ICloudSyncService {}

void main() {
  late MockICloudBackupService backupService;
  late MockICloudSyncService syncService;

  setUp(() {
    backupService = MockICloudBackupService();
    syncService = MockICloudSyncService();
  });

  test('init only loads status and does not create a backup', () async {
    final lastBackup = DateTime(2026, 7, 11);
    when(() => backupService.isAvailable()).thenAnswer((_) async => true);
    when(() => backupService.lastBackupDate).thenReturn(lastBackup);
    when(() => syncService.isUserEnabled).thenReturn(true);

    final cubit = BackupCubit(backupService, syncService);
    await cubit.init();

    expect(cubit.state.isAvailable, isTrue);
    expect(cubit.state.isSyncEnabled, isTrue);
    expect(cubit.state.lastBackupDate, lastBackup);
    verify(() => backupService.isAvailable()).called(1);
    verifyNever(() => backupService.createBackup());

    await cubit.close();
  });
}
