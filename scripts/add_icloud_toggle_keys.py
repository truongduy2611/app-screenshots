#!/usr/bin/env python3
"""Add iCloud sync toggle l10n keys to all ARB files."""
import json
import os

L10N_DIR = os.path.join(os.path.dirname(__file__), '..', 'lib', 'l10n')

# New keys to add after "icloudBackup"
NEW_KEYS = {
    "en": {
        "icloudSync": "iCloud Sync",
        "icloudSyncSubtitle": "Sync designs across your devices via iCloud",
        "icloudSyncDisabled": "iCloud sync is disabled",
        "restartRequired": "Restart the app for changes to take effect",
    },
    "vi": {
        "icloudSync": "Đồng bộ iCloud",
        "icloudSyncSubtitle": "Đồng bộ thiết kế giữa các thiết bị qua iCloud",
        "icloudSyncDisabled": "Đồng bộ iCloud đã tắt",
        "restartRequired": "Khởi động lại ứng dụng để áp dụng thay đổi",
    },
    "fr": {
        "icloudSync": "Synchronisation iCloud",
        "icloudSyncSubtitle": "Synchroniser les designs entre vos appareils via iCloud",
        "icloudSyncDisabled": "La synchronisation iCloud est désactivée",
        "restartRequired": "Redémarrez l'application pour appliquer les modifications",
    },
    "es": {
        "icloudSync": "Sincronización iCloud",
        "icloudSyncSubtitle": "Sincroniza diseños entre tus dispositivos mediante iCloud",
        "icloudSyncDisabled": "La sincronización de iCloud está desactivada",
        "restartRequired": "Reinicia la aplicación para aplicar los cambios",
    },
    "de": {
        "icloudSync": "iCloud-Synchronisierung",
        "icloudSyncSubtitle": "Designs über iCloud zwischen Geräten synchronisieren",
        "icloudSyncDisabled": "iCloud-Synchronisierung ist deaktiviert",
        "restartRequired": "App neu starten, um Änderungen zu übernehmen",
    },
    "ja": {
        "icloudSync": "iCloud同期",
        "icloudSyncSubtitle": "iCloudを使ってデバイス間でデザインを同期",
        "icloudSyncDisabled": "iCloud同期がオフです",
        "restartRequired": "変更を適用するにはアプリを再起動してください",
    },
    "ko": {
        "icloudSync": "iCloud 동기화",
        "icloudSyncSubtitle": "iCloud를 통해 기기 간 디자인 동기화",
        "icloudSyncDisabled": "iCloud 동기화가 비활성화되어 있습니다",
        "restartRequired": "변경 사항을 적용하려면 앱을 다시 시작하세요",
    },
    "zh": {
        "icloudSync": "iCloud 同步",
        "icloudSyncSubtitle": "通过 iCloud 在设备之间同步设计",
        "icloudSyncDisabled": "iCloud 同步已关闭",
        "restartRequired": "重新启动应用以应用更改",
    },
    "zh_Hant": {
        "icloudSync": "iCloud 同步",
        "icloudSyncSubtitle": "透過 iCloud 在裝置之間同步設計",
        "icloudSyncDisabled": "iCloud 同步已關閉",
        "restartRequired": "重新啟動應用程式以套用變更",
    },
    "pt": {
        "icloudSync": "Sincronização iCloud",
        "icloudSyncSubtitle": "Sincronize designs entre dispositivos via iCloud",
        "icloudSyncDisabled": "A sincronização do iCloud está desativada",
        "restartRequired": "Reinicie o app para aplicar as alterações",
    },
    "it": {
        "icloudSync": "Sincronizzazione iCloud",
        "icloudSyncSubtitle": "Sincronizza i design tra i tuoi dispositivi tramite iCloud",
        "icloudSyncDisabled": "La sincronizzazione iCloud è disattivata",
        "restartRequired": "Riavvia l'app per applicare le modifiche",
    },
    "ru": {
        "icloudSync": "Синхронизация iCloud",
        "icloudSyncSubtitle": "Синхронизация дизайнов между устройствами через iCloud",
        "icloudSyncDisabled": "Синхронизация iCloud отключена",
        "restartRequired": "Перезапустите приложение для применения изменений",
    },
    "tr": {
        "icloudSync": "iCloud Senkronizasyonu",
        "icloudSyncSubtitle": "Tasarımları iCloud üzerinden cihazlar arasında senkronize edin",
        "icloudSyncDisabled": "iCloud senkronizasyonu devre dışı",
        "restartRequired": "Değişikliklerin geçerli olması için uygulamayı yeniden başlatın",
    },
    "nl": {
        "icloudSync": "iCloud-synchronisatie",
        "icloudSyncSubtitle": "Synchroniseer ontwerpen tussen apparaten via iCloud",
        "icloudSyncDisabled": "iCloud-synchronisatie is uitgeschakeld",
        "restartRequired": "Start de app opnieuw om wijzigingen toe te passen",
    },
    "ar": {
        "icloudSync": "مزامنة iCloud",
        "icloudSyncSubtitle": "مزامنة التصاميم بين أجهزتك عبر iCloud",
        "icloudSyncDisabled": "مزامنة iCloud معطلة",
        "restartRequired": "أعد تشغيل التطبيق لتطبيق التغييرات",
    },
    "th": {
        "icloudSync": "การซิงค์ iCloud",
        "icloudSyncSubtitle": "ซิงค์การออกแบบระหว่างอุปกรณ์ผ่าน iCloud",
        "icloudSyncDisabled": "การซิงค์ iCloud ถูกปิด",
        "restartRequired": "รีสตาร์ทแอปเพื่อให้การเปลี่ยนแปลงมีผล",
    },
}

# EN gets @descriptions too
EN_DESCRIPTIONS = {
    "icloudSync": "Settings label for the master iCloud sync toggle",
    "icloudSyncSubtitle": "Subtitle explaining iCloud sync functionality",
    "icloudSyncDisabled": "Message shown when iCloud sync is turned off",
    "restartRequired": "Message telling user to restart the app after changing iCloud settings",
}

for filename in sorted(os.listdir(L10N_DIR)):
    if not filename.startswith('app_') or not filename.endswith('.arb'):
        continue

    filepath = os.path.join(L10N_DIR, filename)
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Determine locale from filename
    locale = filename.replace('app_', '').replace('.arb', '')

    if locale not in NEW_KEYS:
        print(f"⚠️  Skipping {filename} — no translations defined")
        continue

    translations = NEW_KEYS[locale]

    # Check if already added
    if 'icloudSync' in data:
        print(f"⏭️  {filename} — already has icloudSync key")
        continue

    # Add the keys
    for key, value in translations.items():
        data[key] = value
        if locale == 'en' and key in EN_DESCRIPTIONS:
            data[f'@{key}'] = {"description": EN_DESCRIPTIONS[key]}

    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')

    print(f"✅ {filename} — added {len(translations)} keys")

print("\nDone!")
