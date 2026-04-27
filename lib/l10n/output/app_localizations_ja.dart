// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'App Screenshots';

  @override
  String get screenshotStudio => 'スクリーンショットスタジオ';

  @override
  String get screenshotStudioSubtitle => '美しいApp Storeスクリーンショットを作成';

  @override
  String get settings => '設定';

  @override
  String get appearance => '外観';

  @override
  String get about => 'アプリについて';

  @override
  String get themeSystem => 'システム';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeSystemSubtitle => 'デバイスの設定に従う';

  @override
  String get themeLightSubtitle => '常にライトテーマを使用';

  @override
  String get themeDarkSubtitle => '常にダークテーマを使用';

  @override
  String get newDesign => '新規デザイン';

  @override
  String get save => '保存';

  @override
  String get saveAs => '名前を付けて保存';

  @override
  String get export => '書き出し';

  @override
  String get share => '共有';

  @override
  String get delete => '削除';

  @override
  String get rename => '名前変更';

  @override
  String get duplicate => '複製';

  @override
  String get cancel => 'キャンセル';

  @override
  String get undo => '元に戻す';

  @override
  String get redo => 'やり直し';

  @override
  String get confirm => '確認';

  @override
  String get done => '完了';

  @override
  String get rotationX => '回転 X';

  @override
  String get rotationY => '回転 Y';

  @override
  String get rotationZ => '回転 Z';

  @override
  String get edit => '編集';

  @override
  String get close => '閉じる';

  @override
  String get designName => 'デザイン名';

  @override
  String get enterDesignName => 'デザイン名を入力';

  @override
  String get folder => 'フォルダ';

  @override
  String get newFolder => '新規フォルダ';

  @override
  String get folderName => 'フォルダ名';

  @override
  String get enterFolderName => 'フォルダ名を入力';

  @override
  String get moveToFolder => 'フォルダに移動';

  @override
  String get noFolder => 'フォルダなし';

  @override
  String get emptyFolder => 'このフォルダは空です';

  @override
  String get deleteFolder => 'フォルダを削除';

  @override
  String get deleteFolderConfirmation => 'このフォルダを削除しますか？デザインはルートに移動されます。';

  @override
  String get cloneToDevice => 'デバイスに複製';

  @override
  String get saveAsTemplate => 'テンプレートとして保存';

  @override
  String get moveLeft => '左へ移動';

  @override
  String get moveRight => '右へ移動';

  @override
  String get deleteSelectedConfirmation => '選択した項目を削除してもよろしいですか？';

  @override
  String selectedCount(int count) {
    return '$count 件選択中';
  }

  @override
  String get exportedDesigns => 'エクスポートしたデザイン';

  @override
  String get select => '選択';

  @override
  String get move => '移動';

  @override
  String get alsoDeleteAllDesigns => 'フォルダ内のデザインもすべて削除';

  @override
  String get renameFolder => 'フォルダ名を変更';

  @override
  String get deleteDesign => 'デザインを削除';

  @override
  String get deleteDesignConfirmation => 'このデザインを削除しますか？';

  @override
  String get background => '背景';

  @override
  String get solidColor => '単色';

  @override
  String get gradient => 'グラデーション';

  @override
  String get addGradientStop => 'ストップを追加';

  @override
  String get removeGradientStop => 'ストップを削除';

  @override
  String get deviceFrame => 'デバイスフレーム';

  @override
  String get selectDevice => 'デバイスを選択';

  @override
  String get noFrame => 'フレームなし';

  @override
  String get iphone => 'iPhone';

  @override
  String get ipad => 'iPad';

  @override
  String get textOverlay => 'テキスト';

  @override
  String get addText => 'テキストを追加';

  @override
  String get newText => '新規テキスト';

  @override
  String get editText => 'テキストを編集';

  @override
  String get fontSize => 'フォントサイズ';

  @override
  String get fontWeight => 'フォントウェイト';

  @override
  String get fontFamily => 'フォント';

  @override
  String get textColor => 'テキスト色';

  @override
  String get textAlign => 'テキスト揃え';

  @override
  String get textRotation => '回転';

  @override
  String get textScale => '拡大縮小';

  @override
  String get textDecoration => '装飾';

  @override
  String get textBackground => '背景';

  @override
  String get textBorder => '枠線';

  @override
  String get deleteText => 'テキストを削除';

  @override
  String get imageOverlay => '画像';

  @override
  String get addImage => '画像を追加';

  @override
  String get deleteImage => '画像を削除';

  @override
  String get doodle => 'ドゥードル';

  @override
  String get enableDoodle => 'ドゥードルパターンを有効化';

  @override
  String get iconSource => 'アイコンソース';

  @override
  String get iconSize => 'アイコンサイズ';

  @override
  String get iconSpacing => '間隔';

  @override
  String get iconOpacity => '不透明度';

  @override
  String get iconRotation => '回転';

  @override
  String get randomizeRotation => 'ランダム回転';

  @override
  String get grid => 'グリッド';

  @override
  String get showGrid => 'グリッドを表示';

  @override
  String get snapToGrid => 'グリッドに吸着';

  @override
  String get gridSize => 'グリッドサイズ';

  @override
  String get showCenterLines => '中心線を表示';

  @override
  String get padding => 'パディング';

  @override
  String get cornerRadius => '角丸';

  @override
  String get frameRotation => 'フレーム回転';

  @override
  String get orientation => '向き';

  @override
  String get portrait => '縦向き';

  @override
  String get landscape => '横向き';

  @override
  String get tools => 'ツール';

  @override
  String get pickImage => '画像を選択';

  @override
  String get importImage => '画像をインポート';

  @override
  String get dropImageHere => 'ここに画像をドロップ';

  @override
  String get replaceImage => '画像を差し替え';

  @override
  String get savedToLibrary => 'ライブラリに保存しました';

  @override
  String get exportedSuccessfully => '書き出しが完了しました';

  @override
  String get failedToExport => '書き出しに失敗しました';

  @override
  String get gridView => 'グリッド表示';

  @override
  String get listView => 'リスト表示';

  @override
  String get emptyLibrary => 'デザインがありません';

  @override
  String get emptyLibrarySubtitle => '+ をタップして最初のスクリーンショットデザインを作成';

  @override
  String version(String version) {
    return 'バージョン $version';
  }

  @override
  String designsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count個のデザイン',
      zero: 'デザインなし',
    );
    return '$_temp0';
  }

  @override
  String get library => 'ライブラリ';

  @override
  String get noDesignsYet => 'デザインがありません';

  @override
  String get createYourFirstDesign => '最初のスクリーンショットデザインを作成';

  @override
  String get solid => 'ソリッド';

  @override
  String get backgroundColor => '背景色';

  @override
  String get gradientColors => 'グラデーション色';

  @override
  String get none => 'なし';

  @override
  String get color => '色';

  @override
  String get location => '位置';

  @override
  String get angle => '角度';

  @override
  String get removeStop => 'ストップを削除';

  @override
  String get alignment => '配置';

  @override
  String get decorationStyle => '装飾スタイル';

  @override
  String get decorationColor => '装飾色';

  @override
  String get borderAndFill => '枠線と塗り';

  @override
  String get fillColor => '塗りの色';

  @override
  String get borderColor => '枠線の色';

  @override
  String get borderWidth => '枠線の幅';

  @override
  String get borderRadius => '角丸';

  @override
  String get horizontalPadding => '水平パディング';

  @override
  String get verticalPadding => '垂直パディング';

  @override
  String get rotation => '回転';

  @override
  String get selectOrAddText => 'テキストオーバーレイを選択または追加';

  @override
  String editingLocale(String locale) {
    return '$localeのオーバーライドを編集中';
  }

  @override
  String get copyToClipboard => 'クリップボードにコピー';

  @override
  String get copiedToClipboard => 'クリップボードにコピーしました';

  @override
  String get pasteFromClipboard => 'クリップボードから貼り付け';

  @override
  String get noImageInClipboard => 'クリップボードに画像が見つかりません';

  @override
  String get checkOutMyDesign => 'このデザインを見てください！';

  @override
  String get templates => 'テンプレート';

  @override
  String get more => 'その他';

  @override
  String get pickAStyleForScreenshots => 'スクリーンショットのスタイルを選択';

  @override
  String get content => 'コンテンツ';

  @override
  String get enterText => 'テキストを入力...';

  @override
  String get typography => 'タイポグラフィ';

  @override
  String get sizeAndWeight => 'サイズとウェイト';

  @override
  String get transform => '変形';

  @override
  String get transparent => '透明';

  @override
  String get addIcon => 'アイコンを追加';

  @override
  String get iconColor => 'アイコン色';

  @override
  String get sfSymbols => 'SF Symbols';

  @override
  String get materialLabel => 'マテリアル';

  @override
  String get emojiLabel => '絵文字';

  @override
  String get searchIcons => 'アイコンを検索...';

  @override
  String get roundedStyle => 'ラウンド';

  @override
  String get sharpStyle => 'シャープ';

  @override
  String get outlinedStyle => 'アウトライン';

  @override
  String get weightLabel => 'ウェイト';

  @override
  String get displayLabel => 'ディスプレイ';

  @override
  String get showGridLabel => 'グリッドを表示';

  @override
  String get displayGridLines => 'キャンバスにグリッド線を表示';

  @override
  String get snapToGridLabel => 'グリッドに吸着';

  @override
  String get snapToGridSubtitle => '要素を最も近いグリッド線に吸着';

  @override
  String get centerLines => '中心線';

  @override
  String get centerLinesSubtitle => '中央揃えガイドを表示';

  @override
  String get gridSizeLabel => 'グリッドサイズ';

  @override
  String get sizeLabel => 'サイズ';

  @override
  String get scatterIconPatterns => 'コンテンツの背面にアイコンパターンを散りばめる';

  @override
  String get iconStyle => 'アイコンスタイル';

  @override
  String get presetsLabel => 'プリセット';

  @override
  String get layoutLabel => 'レイアウト';

  @override
  String get opacityLabel => '不透明度';

  @override
  String get iconSizeLabel => 'アイコンサイズ';

  @override
  String get spacingLabel => '間隔';

  @override
  String get customIcons => 'カスタムアイコン';

  @override
  String screenshotLabel(int index) {
    return 'スクリーンショット $index';
  }

  @override
  String get searchDesignsAndFolders => 'デザインとフォルダを検索…';

  @override
  String noResultsFor(String query) {
    return '「$query」の検索結果はありません';
  }

  @override
  String get zoomToFit => '画面に合わせる';

  @override
  String get addScreenshot => 'スクリーンショットを追加';

  @override
  String get exportCurrent => '現在のものを書き出し';

  @override
  String get exportAll => 'すべて書き出し';

  @override
  String get selectExportFolder => '書き出し先フォルダを選択';

  @override
  String screenshotStudioCount(int count) {
    return 'スクリーンショットスタジオ · $count枚';
  }

  @override
  String get deviceFrames => 'デバイスフレーム';

  @override
  String get gradients => 'グラデーション';

  @override
  String get textOverlays => 'テキストオーバーレイ';

  @override
  String get doodles => 'ドゥードル';

  @override
  String get frame => 'フレーム';

  @override
  String get text => 'テキスト';

  @override
  String get unlockPro => '✨ Proを解除';

  @override
  String get removeAllCreativeLimits => 'すべての制限を解除';

  @override
  String get foldersUnlimitedSaves => 'フォルダ＆無制限保存';

  @override
  String get foldersUnlimitedSavesSubtitle => 'フォルダで整理し、デザインを無制限に保存';

  @override
  String get allDevicesMultiScreenshot => '全デバイス＋マルチスクリーンショット';

  @override
  String get allDevicesMultiScreenshotSubtitle =>
      'すべてのデバイスフレームを使い、複数のスクリーンショットを同時にデザイン';

  @override
  String get advancedDesignTools => '高度なデザインツール';

  @override
  String get advancedDesignToolsSubtitle =>
      'テキスト、アイコン、ドゥードル、全Google Fontsライブラリを解除';

  @override
  String get proUnlimitedMultiSets => '無制限のマルチスクリーンショットセット';

  @override
  String get proUnlimitedMultiSetsSubtitle => '必要なだけセットを作成';

  @override
  String get proAllDevicesMultiMode => 'マルチモードで全デバイスフレーム';

  @override
  String get proAllDevicesMultiModeSubtitle => 'iPad、Apple Watchなど一括スクリーンショット用';

  @override
  String get proAiTranslationAllLocales => 'AI翻訳 — 全言語';

  @override
  String get proAiTranslationSubtitle => 'App Storeの全言語に一括翻訳';

  @override
  String get proAllDoodlePresets => '全Doodleプリセット＆カスタムアイコン';

  @override
  String get proAllDoodlePresetsSubtitle => '無制限のパターンで完全な創作の自由';

  @override
  String get proLabel => 'Pro';

  @override
  String get continueWithPro => 'Proで続ける';

  @override
  String get restorePurchases => '購入を復元';

  @override
  String get support => 'サポート';

  @override
  String get legal => '法的情報';

  @override
  String get rateOnAppStore => 'App Storeで評価';

  @override
  String get sendFeedback => 'フィードバックを送信';

  @override
  String get redeemCode => 'コードを使う';

  @override
  String get termsOfService => '利用規約';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get enjoyingApp => 'App Screenshotsをお楽しみですか？';

  @override
  String get enjoyingAppSubtitle => 'タップしてご意見をお聞かせください';

  @override
  String get restoreCode => 'コードを復元';

  @override
  String get upgradeNow => '今すぐアップグレード';

  @override
  String get oneTimePurchase => '買い切り — ずっとあなたのもの';

  @override
  String get restorePurchase => '購入を復元';

  @override
  String get proActive => 'Pro 有効';

  @override
  String get allFeaturesUnlocked => 'すべての機能が解除されました';

  @override
  String get upgradeToPro => 'Proにアップグレード';

  @override
  String get upgradeToProDescription =>
      'フォルダ、全デバイス、マルチスクリーンショット、高度なデザインツールなどを解除。';

  @override
  String get restore => '復元';

  @override
  String get appIcon => 'アプリアイコン';

  @override
  String get defaultLabel => 'デフォルト';

  @override
  String get purpleLabel => 'パープル';

  @override
  String get exportingScreenshots => 'スクリーンショットをエクスポート中…';

  @override
  String get images => '画像';

  @override
  String get icons => 'アイコン';

  @override
  String get selectFont => 'フォントを選択';

  @override
  String get searchFonts => 'フォントを検索…';

  @override
  String get stops => 'ストップ';

  @override
  String get tapBarToAdd => 'バーをタップして追加';

  @override
  String get selectedStop => '選択されたストップ';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件',
      one: '1件',
    );
    return '$_temp0';
  }

  @override
  String get chooseScreenSize => 'デザインの画面サイズを選択';

  @override
  String get multiScreenshot => 'マルチスクリーンショット';

  @override
  String get createUpTo10Screenshots => '最大10枚のスクリーンショットを作成';

  @override
  String get pickScreenSize => 'スクリーンショットの画面サイズを選択';

  @override
  String get orPickDeviceSize => 'またはデバイスサイズを選択';

  @override
  String get dragScreenshotsHint => 'スクリーンショットをこのエリアにドラッグ';

  @override
  String get tapImportHint => 'またはここをクリックしてインポート';

  @override
  String get tapImportHintMobile => 'インポートをタップしてスクリーンショットを追加';

  @override
  String get shareDesignFile => 'デザインファイルを共有';

  @override
  String get importDesign => 'デザインをインポート';

  @override
  String get designExportedSuccessfully => 'デザインをエクスポートしました';

  @override
  String get designImportedSuccessfully => 'デザインをインポートしました';

  @override
  String get failedToImportDesign => 'デザインのインポートに失敗しました';

  @override
  String get savedToFile => 'ファイルに保存しました';

  @override
  String get saveToLibrary => 'ライブラリに保存';

  @override
  String get icloudBackup => 'iCloudバックアップ';

  @override
  String get backupNow => '今すぐバックアップ';

  @override
  String get restoreFromBackup => 'バックアップから復元';

  @override
  String get lastBackup => '最後のバックアップ';

  @override
  String get backupsAutomatic => 'バックアップは自動的に作成されます';

  @override
  String get noBackupsAvailable => 'バックアップはありません';

  @override
  String get restoreWarning => '復元すると現在のデザインがすべて置き換えられます。この操作は取り消せません。';

  @override
  String get backupRestoredSuccessfully => 'バックアップを復元しました';

  @override
  String get backupCreatedSuccessfully => 'バックアップを作成しました';

  @override
  String get backupFailed => 'バックアップに失敗しました';

  @override
  String get icloudNotAvailable => 'iCloudは利用できません';

  @override
  String get gradientType => 'グラデーションタイプ';

  @override
  String get linear => 'リニア';

  @override
  String get radial => '放射状';

  @override
  String get sweep => 'スイープ';

  @override
  String get mesh => 'メッシュ';

  @override
  String get radialSettings => '放射状の設定';

  @override
  String get radius => '半径';

  @override
  String get sweepSettings => 'スイープの設定';

  @override
  String get startAngle => '開始角度';

  @override
  String get endAngle => '終了角度';

  @override
  String get meshPoints => 'メッシュポイント';

  @override
  String get meshOptions => 'メッシュオプション';

  @override
  String get blend => 'ブレンド';

  @override
  String get noise => 'ノイズ';

  @override
  String get showDotGrid => 'キャンバスドット';

  @override
  String get showDotGridSubtitle => 'エディタの背景にドットパターンを表示';

  @override
  String get addPoint => 'ポイントを追加';

  @override
  String get removePoint => '削除';

  @override
  String get centerX => '中心 X';

  @override
  String get centerY => '中心 Y';

  @override
  String pointCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countポイント',
    );
    return '$_temp0';
  }

  @override
  String pointLabel(int index) {
    return 'ポイント $index';
  }

  @override
  String get xAxis => 'X';

  @override
  String get yAxis => 'Y';

  @override
  String get uploadToAppStoreConnect => 'App Store Connectにアップロード';

  @override
  String get loadingApps => 'アプリを読み込み中...';

  @override
  String loadingVersionForApp(String appName) {
    return '$appNameのバージョンを読み込み中...';
  }

  @override
  String get unknownError => '不明なエラー';

  @override
  String get noApiKeyConfigured => 'APIキー未設定';

  @override
  String get ascApiKeySetupHint =>
      'スクリーンショットをアップロードするにはApp Store Connect APIキーを設定してください。';

  @override
  String get configureApiKey => 'APIキーを設定';

  @override
  String get selectApp => 'アプリを選択';

  @override
  String get searchApps => 'アプリを検索...';

  @override
  String get noAppsFound => 'アプリが見つかりません';

  @override
  String get checkApiKeyPermissions => 'APIキーの権限を確認してください。';

  @override
  String noAppsMatchQuery(String query) {
    return '\"$query\"に一致するアプリがありません';
  }

  @override
  String get changeApp => 'アプリを変更';

  @override
  String get screenshotDisplayType => 'スクリーンショット表示タイプ';

  @override
  String get replace => '置き換え';

  @override
  String get append => '追加';

  @override
  String get rememberForThisDesign => 'このデザインに記憶';

  @override
  String get willSkipAppSelectionNextTime => '次回はアプリ選択をスキップします';

  @override
  String get youllPickTheAppEachTime => '毎回アプリを選択します';

  @override
  String get localesHeader => '言語';

  @override
  String get deselectAll => 'すべて解除';

  @override
  String get selectAll => 'すべて選択';

  @override
  String get selectLocalesToUpload => 'アップロードする言語を選択';

  @override
  String uploadNLocales(int count) {
    return '$count言語をアップロード';
  }

  @override
  String nScreenshots(int count) {
    return '$count枚のスクリーンショット';
  }

  @override
  String get across => '、';

  @override
  String nLocales(int count) {
    return '$count言語';
  }

  @override
  String nFiles(int count) {
    return '$countファイル';
  }

  @override
  String get uploadFailed => 'アップロード失敗';

  @override
  String get completedWithIssues => '問題ありで完了';

  @override
  String get uploadComplete => 'アップロード完了！';

  @override
  String nSucceeded(int count) {
    return '$count件成功';
  }

  @override
  String nFailed(int count) {
    return '$count件失敗';
  }

  @override
  String uploadingLocale(String locale) {
    return '$localeをアップロード中';
  }

  @override
  String nOfTotalScreenshots(int current, int total) {
    return '$current / $total枚';
  }

  @override
  String get preparingUpload => 'アップロード準備中...';

  @override
  String get statusPending => '待機中';

  @override
  String get statusUploading => 'アップロード中...';

  @override
  String get statusDone => '完了';

  @override
  String get statusFailed => '失敗';

  @override
  String get somethingWentWrong => 'エラーが発生しました';

  @override
  String get retry => '再試行';

  @override
  String get appStoreConnectApiKey => 'App Store Connect APIキー';

  @override
  String get ascApiKeyGenerateHint =>
      'App Store Connect → ユーザーとアクセス → 統合 → キー でAPIキーを生成';

  @override
  String get keyId => 'キーID';

  @override
  String get keyIdHint => '例: ABC1234DEF';

  @override
  String get issuerId => '発行者ID';

  @override
  String get issuerIdHint => '例: 12345678-1234-1234-1234-123456789012';

  @override
  String get privateKeyLabel => '秘密鍵（.p8ファイルの内容）';

  @override
  String get privateKeyExistingHint => '••••••• （既存を保持する場合は空欄）';

  @override
  String get privateKeyNewHint => '-----BEGIN PRIVATE KEY-----\\n...';

  @override
  String get clear => 'クリア';

  @override
  String get clearCredentialsTitle => '資格情報をクリアしますか？';

  @override
  String get clearCredentialsMessage =>
      '保存されたAPIキーが削除されます。今後のアップロードには再入力が必要です。';

  @override
  String get apiKeySettingsTitle => 'APIキー';

  @override
  String get apiKeyLoading => '読み込み中...';

  @override
  String apiKeyConfigured(String maskedKeyId) {
    return 'キーID: $maskedKeyId';
  }

  @override
  String get apiKeyNotConfigured => '未設定';

  @override
  String get provider => 'プロバイダー';

  @override
  String get appContext => 'アプリのコンテキスト';

  @override
  String get addContext => 'コンテキストを追加...';

  @override
  String get sourceLanguage => '元の言語';

  @override
  String get targetLanguages => '翻訳先の言語';

  @override
  String get translateAll => 'すべて翻訳';

  @override
  String translatingProgress(int completed, int total) {
    return '翻訳中 $completed / $total';
  }

  @override
  String get manualCopyPaste => '手動（コピー＆ペースト）';

  @override
  String get uploadToAsc => 'ASCにアップロード';

  @override
  String get uploadExistingFolderToAsc => 'Upload Existing Folder...';

  @override
  String get noImagesFoundInFolder =>
      'No valid screenshot images found in selected folder';

  @override
  String get addMoreLanguages => '言語を追加';

  @override
  String get editTranslations => '翻訳を編集';

  @override
  String get addTextOverlaysFirst => 'まずスクリーンショットにテキストを追加してください';

  @override
  String get selectAtLeastOneTargetLanguage => '翻訳先の言語を1つ以上選択してください';

  @override
  String get failedToCaptureLocaleScreenshots => 'ローカライズスクリーンショットの撮影に失敗';

  @override
  String get translationProvider => '翻訳プロバイダー';

  @override
  String get chooseHowTextGetsTranslated => 'テキストの翻訳方法を選択';

  @override
  String get apiKey => 'APIキー';

  @override
  String get apiKeysStoredSecurely => 'APIキーはmacOSキーチェーンに安全に保存されます';

  @override
  String get endpointUrl => 'エンドポイントURL';

  @override
  String get model => 'モデル';

  @override
  String get providerApple => 'Apple（オンデバイス）';

  @override
  String get providerOpenai => 'OpenAI';

  @override
  String get providerGemini => 'Google Gemini';

  @override
  String get providerDeepl => 'DeepL';

  @override
  String get providerCustom => 'カスタムエンドポイント';

  @override
  String get providerManual => '手動（コピー＆ペースト）';

  @override
  String get providerAppleSubtitle => '無料、プライベート — Apple Intelligence必要';

  @override
  String get providerOpenaiSubtitle => 'GPT-4o Mini — 自分のAPIキーを使用';

  @override
  String get providerGeminiSubtitle => 'Gemini 2.0 Flash — 自分のAPIキーを使用';

  @override
  String get providerDeeplSubtitle => 'プロフェッショナル翻訳 — 自分のAPIキーを使用';

  @override
  String get providerCustomSubtitle => 'Ollama、Together AI、LM Studioなど';

  @override
  String get providerManualSubtitle => 'プロンプトをコピー → AIに貼り付け → 回答を貼り付け';

  @override
  String manualTranslateTitle(String locales) {
    return '手動翻訳 → $locales';
  }

  @override
  String get step1CopyPrompt => 'ステップ1: プロンプトをコピー';

  @override
  String get step2PasteResponse => 'ステップ2: AIの回答を貼り付け';

  @override
  String get copied => 'コピーしました！';

  @override
  String get copyPrompt => 'プロンプトをコピー';

  @override
  String get paste => '貼り付け';

  @override
  String get pasteJsonHint =>
      'ChatGPT、Claude、Geminiなど任意のAIからのJSON回答を貼り付けてください。';

  @override
  String get applyTranslations => '翻訳を適用';

  @override
  String get couldNotParseJson => 'JSONを解析できませんでした。フォーマットを確認して再試行してください。';

  @override
  String missingLocalesError(String locales) {
    return '不足している言語: $locales';
  }

  @override
  String localeMissingKeysError(String locale, String keys) {
    return '$localeにキーが不足: $keys';
  }

  @override
  String nTexts(int count) {
    return '$countテキスト';
  }

  @override
  String get appContextDialogTitle => 'アプリのコンテキスト';

  @override
  String get appContextDescription => '翻訳の雰囲気やドメインが合うようにアプリを説明してください。';

  @override
  String get appContextHint => '例: ランナー向けフィットネスアプリ。エネルギッシュで前向きな言葉遣いを使って。';

  @override
  String get addLanguages => '言語を追加';

  @override
  String get searchLanguage => '言語を検索...';

  @override
  String get noLanguagesFound => '言語が見つかりません';

  @override
  String get selectLanguages => '言語を選択';

  @override
  String addNLanguages(int count) {
    return '$count言語を追加';
  }

  @override
  String get appStoreConnect => 'App Store Connect';

  @override
  String get aiGenerate => '✨ AI生成';

  @override
  String get aiGenerateSubtitle => 'スタイルを説明してAIにテンプレートを作成させる';

  @override
  String get aiTemplatePromptHint => '例: フィットネスアプリ向きのダークでエレガントなスタイル';

  @override
  String get aiTemplateGenerating => '生成中…';

  @override
  String get aiTemplateError => 'テンプレートの生成に失敗';

  @override
  String get aiTemplateNoApiKey => 'AIテンプレートを使用するには設定でGemini APIキーを設定してください';

  @override
  String get generate => '生成';

  @override
  String get applyTemplate => 'テンプレートを適用';

  @override
  String get applyTemplateConfirm =>
      '現在のすべてのスクリーンショットのデザインが選択したテンプレートに置き換わります。';

  @override
  String applyTemplateConfirmExpand(int templateCount, int currentCount) {
    return 'このテンプレートには$templateCount個のデザインがありますが、現在$currentCount個です。不足分は自動的に作成され、すべてのデザインが置き換わります。';
  }

  @override
  String get apply => '適用';

  @override
  String get aiProviderSettings => 'AIプロバイダー';

  @override
  String get aiProvider => 'プロバイダー';

  @override
  String get aiApiKeyHint => 'APIキーをここに貼り付け';

  @override
  String get aiGeminiKeyHelp =>
      'Google AI Studio (aistudio.google.com)からAPIキーを取得してください。';

  @override
  String get aiOpenaiKeyHelp =>
      'OpenAIダッシュボード (platform.openai.com)からAPIキーを取得してください。';

  @override
  String get aiAppleFmInfo =>
      'Apple Foundation Modelsはデバイス上で動作します。APIキーやインターネット接続は不要です。';

  @override
  String get aiKeyNotConfigured => 'APIキー未設定';

  @override
  String get aiAssistant => 'AIアシスタント';

  @override
  String get aiAssistantSubtitle => 'デザインの変更を説明してAIに適用させる';

  @override
  String get aiAssistantHint => '変更したい内容を説明...';

  @override
  String get aiAssistantSuggestions => 'こちらをお試し';

  @override
  String get aiAssistantThinking => '考え中...';

  @override
  String get aiAssistantUndo => 'AI変更を元に戻す';

  @override
  String get aiAssistantClearChat => 'チャットをクリア';

  @override
  String get aiAssistantApplyToAll => 'すべてのスクリーンショットに適用';

  @override
  String aiAssistantAppliedToAll(int count) {
    return '$count枚のスクリーンショットに変更を適用しました。';
  }

  @override
  String aiAssistantPartialSuccess(int success, int total, int failed) {
    return '$success/$total枚に適用。$failed件失敗。';
  }

  @override
  String aiAssistantUnexpectedError(String error) {
    return '予期しないエラー: $error';
  }

  @override
  String get aiSuggestionAddGradient => 'グラデーション背景を追加';

  @override
  String get aiSuggestionLightMode => 'ライトモードに切替';

  @override
  String get aiSuggestionDarkMode => 'ダークモードに切替';

  @override
  String get aiSuggestionAddHeadline => 'キャッチーな見出しを追加';

  @override
  String get aiSuggestionBiggerTitle => 'タイトルを大きく';

  @override
  String get aiSuggestionAddSubtitle => 'サブタイトルを追加';

  @override
  String get aiSuggestionTiltFrame => 'フレームを傾ける';

  @override
  String get aiSuggestionRoundCorners => '角を丸くする';

  @override
  String get aiSuggestionWriteHeadline => 'キャッチーな見出しを書く';

  @override
  String get aiSuggestionColorPalette => 'カラーパレットを提案';

  @override
  String get aiSuggestionAddDoodle => 'ドゥードルパターン背景を追加';

  @override
  String get aiSuggestionEmojiDoodle => '絵文字ドゥードルパターンを使用';

  @override
  String get aiSuggestionAdd3DTilt => '3Dパースペクティブ傾斜を追加';

  @override
  String get aiSuggestionTransparentBg => '背景を透明にする';

  @override
  String get aiSuggestionLandscapeMode => '横向きモードに切替';

  @override
  String get magnifierShapeLabel => '形状';

  @override
  String get magnifierShapeCircle => '円';

  @override
  String get magnifierShapeRounded => '角丸';

  @override
  String get magnifierShapeStar => '星';

  @override
  String get magnifierShapeHexagon => '六角形';

  @override
  String get magnifierShapeDiamond => 'ひし形';

  @override
  String get magnifierShapeHeart => 'ハート';

  @override
  String magnifierCorner(int value) {
    return '角丸: $value';
  }

  @override
  String magnifierPoints(int value) {
    return 'ポイント: $value';
  }

  @override
  String magnifierZoom(String value) {
    return 'ズーム: $value×';
  }

  @override
  String magnifierWidth(int value) {
    return '幅: $value';
  }

  @override
  String magnifierHeight(int value) {
    return '高さ: $value';
  }

  @override
  String magnifierBorder(String value) {
    return '枠線: $value';
  }

  @override
  String magnifierSourceX(int value) {
    return 'ソース X: $value';
  }

  @override
  String magnifierSourceY(int value) {
    return 'ソース Y: $value';
  }

  @override
  String magnifierOpacity(int value) {
    return '不透明度: $value%';
  }

  @override
  String get bringForward => '前面へ移動';

  @override
  String get sendBackward => '背面へ移動';

  @override
  String get inFrontOfFrame => 'フレームの前面';

  @override
  String get behindFrame => 'フレームの背面';

  @override
  String get onlySelectedLocalesWillBeRendered => '選択した言語のみがレンダリングされます';

  @override
  String renderNLocales(int count) {
    return '$count言語をレンダリング';
  }

  @override
  String get source => 'ソース';

  @override
  String get supportTheDeveloper => '開発者を支援する';

  @override
  String supportTheDeveloperDescription(String price) {
    return 'アプリが気に入りましたか？コーヒーをおごってください！ $price';
  }

  @override
  String get enableCliServer => 'CLIサーバーを有効にする';

  @override
  String get enableCliServerDescription => 'CLIツールを使用するにはローカルサーバーを起動してください。';

  @override
  String get cliLearnMoreButton => 'ドキュメントを読む';

  @override
  String get cliCompanionTitle => 'コマンドラインツール';

  @override
  String get cliCompanionDescription =>
      'コンパニオンCLIツールを使って、ターミナルからスクリーンショットを自動化できます。セットアップ手順はドキュメントをご覧ください。';
}
