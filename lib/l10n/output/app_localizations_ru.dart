// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'App Screenshots';

  @override
  String get screenshotStudio => 'Студия скриншотов';

  @override
  String get screenshotStudioSubtitle =>
      'Создавайте красивые скриншоты для App Store';

  @override
  String get settings => 'Настройки';

  @override
  String get appearance => 'Оформление';

  @override
  String get about => 'О приложении';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeSystemSubtitle => 'Следовать настройкам устройства';

  @override
  String get themeLightSubtitle => 'Всегда использовать светлую тему';

  @override
  String get themeDarkSubtitle => 'Всегда использовать тёмную тему';

  @override
  String get newDesign => 'Новый дизайн';

  @override
  String get save => 'Сохранить';

  @override
  String get saveAs => 'Сохранить как';

  @override
  String get export => 'Экспорт';

  @override
  String get share => 'Поделиться';

  @override
  String get delete => 'Удалить';

  @override
  String get rename => 'Переименовать';

  @override
  String get duplicate => 'Дублировать';

  @override
  String get cancel => 'Отмена';

  @override
  String get undo => 'Отменить';

  @override
  String get redo => 'Повторить';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get done => 'Готово';

  @override
  String get rotationX => 'Поворот X';

  @override
  String get rotationY => 'Поворот Y';

  @override
  String get rotationZ => 'Поворот Z';

  @override
  String get edit => 'Редактировать';

  @override
  String get close => 'Закрыть';

  @override
  String get designName => 'Название дизайна';

  @override
  String get enterDesignName => 'Введите название дизайна';

  @override
  String get folder => 'Папка';

  @override
  String get newFolder => 'Новая папка';

  @override
  String get folderName => 'Название папки';

  @override
  String get enterFolderName => 'Введите название папки';

  @override
  String get moveToFolder => 'Переместить в папку';

  @override
  String get noFolder => 'Без папки';

  @override
  String get emptyFolder => 'Эта папка пуста';

  @override
  String get deleteFolder => 'Удалить папку';

  @override
  String get deleteFolderConfirmation =>
      'Вы уверены, что хотите удалить эту папку? Дизайны будут перемещены в корень.';

  @override
  String get cloneToDevice => 'Клонировать на устройство';

  @override
  String get saveAsTemplate => 'Сохранить как шаблон';

  @override
  String get moveLeft => 'Переместить влево';

  @override
  String get moveRight => 'Переместить вправо';

  @override
  String get deleteSelectedConfirmation =>
      'Вы уверены, что хотите удалить выбранные элементы?';

  @override
  String selectedCount(int count) {
    return '$count выбрано';
  }

  @override
  String get exportedDesigns => 'Экспортированные дизайны';

  @override
  String get select => 'Выбрать';

  @override
  String get move => 'Переместить';

  @override
  String get alsoDeleteAllDesigns => 'Также удалить все дизайны';

  @override
  String get renameFolder => 'Переименовать папку';

  @override
  String get deleteDesign => 'Удалить дизайн';

  @override
  String get deleteDesignConfirmation =>
      'Вы уверены, что хотите удалить этот дизайн?';

  @override
  String get background => 'Фон';

  @override
  String get solidColor => 'Сплошной цвет';

  @override
  String get gradient => 'Градиент';

  @override
  String get addGradientStop => 'Добавить точку';

  @override
  String get removeGradientStop => 'Удалить точку';

  @override
  String get deviceFrame => 'Рамка устройства';

  @override
  String get selectDevice => 'Выбрать устройство';

  @override
  String get noFrame => 'Без рамки';

  @override
  String get iphone => 'iPhone';

  @override
  String get ipad => 'iPad';

  @override
  String get textOverlay => 'Текст';

  @override
  String get addText => 'Добавить текст';

  @override
  String get newText => 'Новый текст';

  @override
  String get editText => 'Редактировать текст';

  @override
  String get fontSize => 'Размер шрифта';

  @override
  String get fontWeight => 'Начертание';

  @override
  String get fontFamily => 'Шрифт';

  @override
  String get textColor => 'Цвет текста';

  @override
  String get textAlign => 'Выравнивание текста';

  @override
  String get textRotation => 'Поворот';

  @override
  String get textScale => 'Масштаб';

  @override
  String get textDecoration => 'Оформление';

  @override
  String get textBackground => 'Фон';

  @override
  String get textBorder => 'Граница';

  @override
  String get deleteText => 'Удалить текст';

  @override
  String get imageOverlay => 'Изображение';

  @override
  String get addImage => 'Добавить изображение';

  @override
  String get deleteImage => 'Удалить изображение';

  @override
  String get doodle => 'Дудл';

  @override
  String get enableDoodle => 'Включить узор дудл';

  @override
  String get iconSource => 'Источник иконок';

  @override
  String get iconSize => 'Размер иконки';

  @override
  String get iconSpacing => 'Интервал';

  @override
  String get iconOpacity => 'Непрозрачность';

  @override
  String get iconRotation => 'Поворот';

  @override
  String get randomizeRotation => 'Случайный поворот';

  @override
  String get grid => 'Сетка';

  @override
  String get showGrid => 'Показать сетку';

  @override
  String get snapToGrid => 'Привязка к сетке';

  @override
  String get gridSize => 'Размер сетки';

  @override
  String get showCenterLines => 'Показать центральные линии';

  @override
  String get padding => 'Отступ';

  @override
  String get cornerRadius => 'Радиус скругления';

  @override
  String get frameRotation => 'Поворот рамки';

  @override
  String get orientation => 'Ориентация';

  @override
  String get portrait => 'Портретная';

  @override
  String get landscape => 'Альбомная';

  @override
  String get tools => 'Инструменты';

  @override
  String get pickImage => 'Выбрать изображение';

  @override
  String get importImage => 'Импортировать изображение';

  @override
  String get dropImageHere => 'Перетащите изображение сюда';

  @override
  String get replaceImage => 'Заменить изображение';

  @override
  String get savedToLibrary => 'Сохранено в библиотеку';

  @override
  String get exportedSuccessfully => 'Успешно экспортировано';

  @override
  String get failedToExport => 'Не удалось экспортировать';

  @override
  String get gridView => 'Вид сетки';

  @override
  String get listView => 'Вид списка';

  @override
  String get emptyLibrary => 'Пока нет дизайнов';

  @override
  String get emptyLibrarySubtitle => 'Нажмите +, чтобы создать первый дизайн';

  @override
  String version(String version) {
    return 'Версия $version';
  }

  @override
  String designsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дизайнов',
      many: '$count дизайнов',
      few: '$count дизайна',
      one: '1 дизайн',
      zero: 'Нет дизайнов',
    );
    return '$_temp0';
  }

  @override
  String get library => 'Библиотека';

  @override
  String get noDesignsYet => 'Пока нет дизайнов';

  @override
  String get createYourFirstDesign => 'Создайте первый дизайн скриншота';

  @override
  String get solid => 'Сплошной';

  @override
  String get backgroundColor => 'Цвет фона';

  @override
  String get gradientColors => 'Цвета градиента';

  @override
  String get none => 'Нет';

  @override
  String get color => 'Цвет';

  @override
  String get location => 'Позиция';

  @override
  String get angle => 'Угол';

  @override
  String get removeStop => 'Удалить точку';

  @override
  String get alignment => 'Выравнивание';

  @override
  String get decorationStyle => 'Стиль оформления';

  @override
  String get decorationColor => 'Цвет оформления';

  @override
  String get borderAndFill => 'Граница и заливка';

  @override
  String get fillColor => 'Цвет заливки';

  @override
  String get borderColor => 'Цвет границы';

  @override
  String get borderWidth => 'Ширина границы';

  @override
  String get borderRadius => 'Радиус границы';

  @override
  String get horizontalPadding => 'Горизонтальный отступ';

  @override
  String get verticalPadding => 'Вертикальный отступ';

  @override
  String get rotation => 'Поворот';

  @override
  String get selectOrAddText => 'Выберите или добавьте текстовый слой';

  @override
  String editingLocale(String locale) {
    return 'Редактирование варианта $locale';
  }

  @override
  String get copyToClipboard => 'Скопировать в буфер';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get pasteFromClipboard => 'Вставить из буфера обмена';

  @override
  String get noImageInClipboard => 'Изображение не найдено в буфере обмена';

  @override
  String get checkOutMyDesign => 'Посмотрите мой дизайн!';

  @override
  String get templates => 'Шаблоны';

  @override
  String get more => 'Ещё';

  @override
  String get pickAStyleForScreenshots => 'Выберите стиль для скриншотов';

  @override
  String get content => 'Содержимое';

  @override
  String get enterText => 'Введите текст...';

  @override
  String get typography => 'Типографика';

  @override
  String get sizeAndWeight => 'Размер и начертание';

  @override
  String get transform => 'Трансформация';

  @override
  String get transparent => 'Прозрачный';

  @override
  String get addIcon => 'Добавить иконку';

  @override
  String get iconColor => 'Цвет иконки';

  @override
  String get sfSymbols => 'SF Symbols';

  @override
  String get materialLabel => 'Material';

  @override
  String get emojiLabel => 'Эмодзи';

  @override
  String get searchIcons => 'Поиск иконок...';

  @override
  String get roundedStyle => 'Скруглённый';

  @override
  String get sharpStyle => 'Острый';

  @override
  String get outlinedStyle => 'Контурный';

  @override
  String get weightLabel => 'Начертание';

  @override
  String get displayLabel => 'Отображение';

  @override
  String get showGridLabel => 'Показать сетку';

  @override
  String get displayGridLines => 'Показать линии сетки на холсте';

  @override
  String get snapToGridLabel => 'Привязка к сетке';

  @override
  String get snapToGridSubtitle => 'Привязать элементы к ближайшей линии';

  @override
  String get centerLines => 'Центральные линии';

  @override
  String get centerLinesSubtitle => 'Показать направляющие центра';

  @override
  String get gridSizeLabel => 'Размер сетки';

  @override
  String get sizeLabel => 'Размер';

  @override
  String get scatterIconPatterns => 'Разбросать узоры иконок за содержимым';

  @override
  String get iconStyle => 'Стиль иконки';

  @override
  String get presetsLabel => 'Пресеты';

  @override
  String get layoutLabel => 'Макет';

  @override
  String get opacityLabel => 'Непрозрачность';

  @override
  String get iconSizeLabel => 'Размер иконки';

  @override
  String get spacingLabel => 'Интервал';

  @override
  String get customIcons => 'Свои иконки';

  @override
  String screenshotLabel(int index) {
    return 'Скриншот $index';
  }

  @override
  String get searchDesignsAndFolders => 'Поиск дизайнов и папок…';

  @override
  String noResultsFor(String query) {
    return 'Нет результатов для «$query»';
  }

  @override
  String get zoomToFit => 'По размеру';

  @override
  String get addScreenshot => 'Добавить скриншот';

  @override
  String get exportCurrent => 'Экспорт текущего';

  @override
  String get exportAll => 'Экспорт всех';

  @override
  String get selectExportFolder => 'Выберите папку для экспорта';

  @override
  String screenshotStudioCount(int count) {
    return 'Студия скриншотов · $count скриншотов';
  }

  @override
  String get deviceFrames => 'Рамки устройств';

  @override
  String get gradients => 'Градиенты';

  @override
  String get textOverlays => 'Текстовые слои';

  @override
  String get doodles => 'Дудлы';

  @override
  String get frame => 'Рамка';

  @override
  String get text => 'Текст';

  @override
  String get unlockPro => '✨ Разблокировать Pro';

  @override
  String get removeAllCreativeLimits => 'Снимите все творческие ограничения';

  @override
  String get foldersUnlimitedSaves => 'Папки и безлимитное сохранение';

  @override
  String get foldersUnlimitedSavesSubtitle =>
      'Организуйте папками и сохраняйте без ограничений';

  @override
  String get allDevicesMultiScreenshot => 'Все устройства + мульти-скриншоты';

  @override
  String get allDevicesMultiScreenshotSubtitle =>
      'Все рамки устройств и несколько скриншотов сразу';

  @override
  String get advancedDesignTools => 'Расширенные инструменты';

  @override
  String get advancedDesignToolsSubtitle =>
      'Текстовые слои, иконки, дудлы и вся библиотека Google Fonts';

  @override
  String get proUnlimitedMultiSets => 'Безлимитные мульти-наборы';

  @override
  String get proUnlimitedMultiSetsSubtitle =>
      'Создавайте столько наборов, сколько нужно';

  @override
  String get proAllDevicesMultiMode => 'Все рамки устройств в мульти-режиме';

  @override
  String get proAllDevicesMultiModeSubtitle =>
      'iPad, Apple Watch и другие для пакетных скриншотов';

  @override
  String get proAiTranslationAllLocales => 'ИИ-перевод — Все языки';

  @override
  String get proAiTranslationSubtitle =>
      'Переводите на все языки App Store одновременно';

  @override
  String get proAllDoodlePresets => 'Все паттерны и пользовательские иконки';

  @override
  String get proAllDoodlePresetsSubtitle =>
      'Полная творческая свобода с безлимитными паттернами';

  @override
  String get proLabel => 'Pro';

  @override
  String get continueWithPro => 'Продолжить с Pro';

  @override
  String get restorePurchases => 'Восстановить покупки';

  @override
  String get support => 'Поддержка';

  @override
  String get legal => 'Правовая информация';

  @override
  String get rateOnAppStore => 'Оценить в App Store';

  @override
  String get sendFeedback => 'Отправить отзыв';

  @override
  String get redeemCode => 'Активировать код';

  @override
  String get termsOfService => 'Условия использования';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get enjoyingApp => 'Нравится App Screenshots?';

  @override
  String get enjoyingAppSubtitle => 'Нажмите, чтобы оставить отзыв';

  @override
  String get restoreCode => 'Восстановить код';

  @override
  String get upgradeNow => 'Обновить сейчас';

  @override
  String get oneTimePurchase => 'Разовая покупка — навсегда ваша';

  @override
  String get restorePurchase => 'Восстановить покупку';

  @override
  String get proActive => 'Pro активен';

  @override
  String get allFeaturesUnlocked => 'Все функции разблокированы';

  @override
  String get upgradeToPro => 'Перейти на Pro';

  @override
  String get upgradeToProDescription =>
      'Разблокируйте папки, все устройства, мульти-скриншоты, расширенные инструменты дизайна и многое другое.';

  @override
  String get restore => 'Восстановить';

  @override
  String get appIcon => 'Значок приложения';

  @override
  String get defaultLabel => 'По умолчанию';

  @override
  String get purpleLabel => 'Фиолетовый';

  @override
  String get exportingScreenshots => 'Экспорт скриншотов…';

  @override
  String get images => 'Изображения';

  @override
  String get icons => 'Значки';

  @override
  String get selectFont => 'Выбрать шрифт';

  @override
  String get searchFonts => 'Поиск шрифтов…';

  @override
  String get stops => 'Точки';

  @override
  String get tapBarToAdd => 'Нажмите на полосу, чтобы добавить';

  @override
  String get selectedStop => 'Выбранная точка';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count элементов',
      one: '1 элемент',
    );
    return '$_temp0';
  }

  @override
  String get chooseScreenSize => 'Выберите размер экрана для вашего дизайна';

  @override
  String get multiScreenshot => 'Мульти-скриншот';

  @override
  String get createUpTo10Screenshots => 'Создайте до 10 скриншотов';

  @override
  String get pickScreenSize => 'Выберите размер экрана для ваших скриншотов';

  @override
  String get orPickDeviceSize => 'или выберите размер устройства';

  @override
  String get dragScreenshotsHint => 'Перетащите скриншоты в эту область';

  @override
  String get tapImportHint => 'или нажмите здесь для импорта';

  @override
  String get tapImportHintMobile => 'Нажмите Импорт, чтобы добавить скриншот';

  @override
  String get shareDesignFile => 'Поделиться файлом дизайна';

  @override
  String get importDesign => 'Импортировать дизайн';

  @override
  String get designExportedSuccessfully => 'Дизайн успешно экспортирован';

  @override
  String get designImportedSuccessfully => 'Дизайн успешно импортирован';

  @override
  String get failedToImportDesign => 'Не удалось импортировать дизайн';

  @override
  String get savedToFile => 'Сохранено в файл';

  @override
  String get saveToLibrary => 'Сохранить в библиотеку';

  @override
  String get icloudBackup => 'Резервная копия iCloud';

  @override
  String get backupNow => 'Создать копию сейчас';

  @override
  String get restoreFromBackup => 'Восстановить из копии';

  @override
  String get lastBackup => 'Последняя копия';

  @override
  String get backupsAutomatic => 'Копии создаются автоматически';

  @override
  String get noBackupsAvailable => 'Нет доступных копий';

  @override
  String get restoreWarning =>
      'Восстановление заменит все текущие дизайны. Это действие нельзя отменить.';

  @override
  String get backupRestoredSuccessfully => 'Копия успешно восстановлена';

  @override
  String get backupCreatedSuccessfully => 'Копия успешно создана';

  @override
  String get backupFailed => 'Ошибка резервного копирования';

  @override
  String get icloudNotAvailable => 'iCloud недоступен';

  @override
  String get gradientType => 'Тип градиента';

  @override
  String get linear => 'Линейный';

  @override
  String get radial => 'Радиальный';

  @override
  String get sweep => 'Развёртка';

  @override
  String get mesh => 'Сетка';

  @override
  String get radialSettings => 'Настройки радиального';

  @override
  String get radius => 'Радиус';

  @override
  String get sweepSettings => 'Настройки развёртки';

  @override
  String get startAngle => 'Начальный угол';

  @override
  String get endAngle => 'Конечный угол';

  @override
  String get meshPoints => 'Точки сетки';

  @override
  String get meshOptions => 'Параметры сетки';

  @override
  String get blend => 'Смешивание';

  @override
  String get noise => 'Шум';

  @override
  String get showDotGrid => 'Точки холста';

  @override
  String get showDotGridSubtitle => 'Показать точечный узор на фоне редактора';

  @override
  String get addPoint => 'Добавить точку';

  @override
  String get removePoint => 'Удалить';

  @override
  String get centerX => 'Центр X';

  @override
  String get centerY => 'Центр Y';

  @override
  String pointCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count точек',
      many: '$count точек',
      few: '$count точки',
      one: '1 точка',
    );
    return '$_temp0';
  }

  @override
  String pointLabel(int index) {
    return 'Точка $index';
  }

  @override
  String get xAxis => 'X';

  @override
  String get yAxis => 'Y';

  @override
  String get uploadToAppStoreConnect => 'Загрузить в App Store Connect';

  @override
  String get loadingApps => 'Загрузка приложений...';

  @override
  String loadingVersionForApp(String appName) {
    return 'Загрузка версии для $appName...';
  }

  @override
  String get unknownError => 'Неизвестная ошибка';

  @override
  String get noApiKeyConfigured => 'API-ключ не настроен';

  @override
  String get ascApiKeySetupHint =>
      'Настройте API-ключ App Store Connect для загрузки скриншотов.';

  @override
  String get configureApiKey => 'Настроить API-ключ';

  @override
  String get selectApp => 'Выбрать приложение';

  @override
  String get searchApps => 'Поиск приложений...';

  @override
  String get noAppsFound => 'Приложения не найдены';

  @override
  String get checkApiKeyPermissions => 'Проверьте разрешения API-ключа.';

  @override
  String noAppsMatchQuery(String query) {
    return 'Нет приложений для \"$query\"';
  }

  @override
  String get changeApp => 'Сменить приложение';

  @override
  String get screenshotDisplayType => 'Тип отображения скриншотов';

  @override
  String get replace => 'Заменить';

  @override
  String get append => 'Добавить';

  @override
  String get rememberForThisDesign => 'Запомнить для этого дизайна';

  @override
  String get willSkipAppSelectionNextTime =>
      'Выбор приложения будет пропущен в следующий раз';

  @override
  String get youllPickTheAppEachTime =>
      'Вы будете выбирать приложение каждый раз';

  @override
  String get localesHeader => 'ЯЗЫКИ';

  @override
  String get deselectAll => 'Снять всё';

  @override
  String get selectAll => 'Выбрать всё';

  @override
  String get selectLocalesToUpload => 'Выберите языки для загрузки';

  @override
  String uploadNLocales(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'языков',
      one: 'язык',
    );
    return 'Загрузить $count $_temp0';
  }

  @override
  String nScreenshots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'скриншотов',
      one: 'скриншот',
    );
    return '$count $_temp0';
  }

  @override
  String get across => 'на';

  @override
  String nLocales(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'языков',
      one: 'язык',
    );
    return '$count $_temp0';
  }

  @override
  String nFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'файлов',
      one: 'файл',
    );
    return '$count $_temp0';
  }

  @override
  String get uploadFailed => 'Загрузка не удалась';

  @override
  String get completedWithIssues => 'Завершено с проблемами';

  @override
  String get uploadComplete => 'Загрузка завершена!';

  @override
  String nSucceeded(int count) {
    return '$count успешно';
  }

  @override
  String nFailed(int count) {
    return '$count не удалось';
  }

  @override
  String uploadingLocale(String locale) {
    return 'Загрузка $locale';
  }

  @override
  String nOfTotalScreenshots(int current, int total) {
    return '$current из $total скриншотов';
  }

  @override
  String get preparingUpload => 'Подготовка загрузки...';

  @override
  String get statusPending => 'Ожидание';

  @override
  String get statusUploading => 'Загрузка...';

  @override
  String get statusDone => 'Готово';

  @override
  String get statusFailed => 'Ошибка';

  @override
  String get somethingWentWrong => 'Что-то пошло не так';

  @override
  String get retry => 'Повторить';

  @override
  String get appStoreConnectApiKey => 'API-ключ App Store Connect';

  @override
  String get ascApiKeyGenerateHint =>
      'Создайте API-ключ в App Store Connect → Пользователи и доступ → Интеграции → Ключи';

  @override
  String get keyId => 'ID ключа';

  @override
  String get keyIdHint => 'напр. ABC1234DEF';

  @override
  String get issuerId => 'ID издателя';

  @override
  String get issuerIdHint => 'напр. 12345678-1234-1234-1234-123456789012';

  @override
  String get privateKeyLabel => 'Закрытый ключ (содержимое файла .p8)';

  @override
  String get privateKeyExistingHint =>
      '••••••• (оставьте пустым, чтобы сохранить текущий)';

  @override
  String get privateKeyNewHint => '-----BEGIN PRIVATE KEY-----\\n...';

  @override
  String get clear => 'Очистить';

  @override
  String get clearCredentialsTitle => 'Очистить учётные данные?';

  @override
  String get clearCredentialsMessage =>
      'Это удалит сохранённый API-ключ. Вам нужно будет ввести его снова для будущих загрузок.';

  @override
  String get apiKeySettingsTitle => 'API-ключ';

  @override
  String get apiKeyLoading => 'Загрузка...';

  @override
  String apiKeyConfigured(String maskedKeyId) {
    return 'ID ключа: $maskedKeyId';
  }

  @override
  String get apiKeyNotConfigured => 'Не настроено';

  @override
  String get provider => 'Провайдер';

  @override
  String get appContext => 'Контекст приложения';

  @override
  String get addContext => 'Добавить контекст...';

  @override
  String get sourceLanguage => 'Исходный язык';

  @override
  String get targetLanguages => 'Целевые языки';

  @override
  String get translateAll => 'Перевести всё';

  @override
  String translatingProgress(int completed, int total) {
    return 'Перевод $completed / $total';
  }

  @override
  String get manualCopyPaste => 'Вручную (Копировать-Вставить)';

  @override
  String get uploadToAsc => 'Загрузить в ASC';

  @override
  String get addMoreLanguages => 'Добавить ещё языки';

  @override
  String get editTranslations => 'Редактировать переводы';

  @override
  String get addTextOverlaysFirst => 'Сначала добавьте текст на скриншоты';

  @override
  String get selectAtLeastOneTargetLanguage =>
      'Выберите хотя бы один целевой язык';

  @override
  String get failedToCaptureLocaleScreenshots =>
      'Не удалось сделать локализованные скриншоты';

  @override
  String get translationProvider => 'Провайдер перевода';

  @override
  String get chooseHowTextGetsTranslated => 'Выберите способ перевода текста';

  @override
  String get apiKey => 'API-ключ';

  @override
  String get apiKeysStoredSecurely =>
      'API-ключи надёжно хранятся в связке ключей macOS';

  @override
  String get endpointUrl => 'URL эндпоинта';

  @override
  String get model => 'Модель';

  @override
  String get providerApple => 'Apple (На устройстве)';

  @override
  String get providerOpenai => 'OpenAI';

  @override
  String get providerGemini => 'Google Gemini';

  @override
  String get providerDeepl => 'DeepL';

  @override
  String get providerCustom => 'Свой эндпоинт';

  @override
  String get providerManual => 'Вручную (Копировать-Вставить)';

  @override
  String get providerAppleSubtitle =>
      'Бесплатно, конфиденциально — требуется Apple Intelligence';

  @override
  String get providerOpenaiSubtitle =>
      'GPT-4o Mini — используйте свой API-ключ';

  @override
  String get providerGeminiSubtitle =>
      'Gemini 2.0 Flash — используйте свой API-ключ';

  @override
  String get providerDeeplSubtitle =>
      'Профессиональный перевод — используйте свой API-ключ';

  @override
  String get providerCustomSubtitle => 'Ollama, Together AI, LM Studio и др.';

  @override
  String get providerManualSubtitle =>
      'Скопируйте промпт → вставьте в ИИ → вставьте ответ обратно';

  @override
  String manualTranslateTitle(String locales) {
    return 'Ручной перевод → $locales';
  }

  @override
  String get step1CopyPrompt => 'Шаг 1: Скопируйте промпт';

  @override
  String get step2PasteResponse => 'Шаг 2: Вставьте ответ ИИ';

  @override
  String get copied => 'Скопировано!';

  @override
  String get copyPrompt => 'Копировать промпт';

  @override
  String get paste => 'Вставить';

  @override
  String get pasteJsonHint =>
      'Вставьте JSON-ответ от ChatGPT, Claude, Gemini или другого ИИ.';

  @override
  String get applyTranslations => 'Применить переводы';

  @override
  String get couldNotParseJson =>
      'Не удалось разобрать JSON. Проверьте формат и попробуйте снова.';

  @override
  String missingLocalesError(String locales) {
    return 'Отсутствующие языки: $locales';
  }

  @override
  String localeMissingKeysError(String locale, String keys) {
    return '$locale отсутствуют ключи: $keys';
  }

  @override
  String nTexts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'текстов',
      one: 'текст',
    );
    return '$count $_temp0';
  }

  @override
  String get appContextDialogTitle => 'Контекст приложения';

  @override
  String get appContextDescription =>
      'Опишите приложение, чтобы переводы соответствовали его тону и тематике.';

  @override
  String get appContextHint =>
      'напр. Фитнес-приложение для бегунов. Используйте энергичный и мотивирующий стиль.';

  @override
  String get addLanguages => 'Добавить языки';

  @override
  String get searchLanguage => 'Найти язык...';

  @override
  String get noLanguagesFound => 'Языки не найдены';

  @override
  String get selectLanguages => 'Выберите языки';

  @override
  String addNLanguages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'языков',
      one: 'язык',
    );
    return 'Добавить $count $_temp0';
  }

  @override
  String get appStoreConnect => 'App Store Connect';

  @override
  String get aiGenerate => '✨ ИИ-генерация';

  @override
  String get aiGenerateSubtitle => 'Опишите стиль, и ИИ создаст шаблон';

  @override
  String get aiTemplatePromptHint =>
      'напр. Тёмный элегантный стиль для фитнес-приложения';

  @override
  String get aiTemplateGenerating => 'Генерация…';

  @override
  String get aiTemplateError => 'Не удалось сгенерировать шаблон';

  @override
  String get aiTemplateNoApiKey =>
      'Настройте API-ключ Gemini в Настройках для использования ИИ-шаблонов';

  @override
  String get generate => 'Сгенерировать';

  @override
  String get applyTemplate => 'Применить шаблон';

  @override
  String get applyTemplateConfirm =>
      'Это заменит дизайн всех текущих скриншотов выбранным шаблоном.';

  @override
  String applyTemplateConfirmExpand(int templateCount, int currentCount) {
    return 'В этом шаблоне $templateCount дизайнов, а у вас $currentCount. Недостающие скриншоты будут созданы автоматически, и все дизайны будут заменены.';
  }

  @override
  String get apply => 'Применить';

  @override
  String get aiProviderSettings => 'ИИ-провайдер';

  @override
  String get aiProvider => 'Провайдер';

  @override
  String get aiApiKeyHint => 'Вставьте свой API-ключ сюда';

  @override
  String get aiGeminiKeyHelp =>
      'Получите API-ключ в Google AI Studio (aistudio.google.com).';

  @override
  String get aiOpenaiKeyHelp =>
      'Получите API-ключ в панели OpenAI (platform.openai.com).';

  @override
  String get aiAppleFmInfo =>
      'Модели Apple Foundation работают на устройстве. API-ключ и интернет не нужны.';

  @override
  String get aiKeyNotConfigured => 'API-ключ не настроен';

  @override
  String get aiAssistant => 'ИИ-ассистент';

  @override
  String get aiAssistantSubtitle =>
      'Опишите изменения дизайна, и ИИ применит их';

  @override
  String get aiAssistantHint => 'Опишите, что хотите изменить...';

  @override
  String get aiAssistantSuggestions => 'Попробуйте эти';

  @override
  String get aiAssistantThinking => 'Думаю...';

  @override
  String get aiAssistantUndo => 'Отменить изменение ИИ';

  @override
  String get aiAssistantClearChat => 'Очистить чат';

  @override
  String get aiAssistantApplyToAll => 'Применить ко всем скриншотам';

  @override
  String aiAssistantAppliedToAll(int count) {
    return 'Изменения применены к $count скриншотам.';
  }

  @override
  String aiAssistantPartialSuccess(int success, int total, int failed) {
    return 'Применено к $success/$total скриншотам. $failed не удалось.';
  }

  @override
  String aiAssistantUnexpectedError(String error) {
    return 'Неожиданная ошибка: $error';
  }

  @override
  String get aiSuggestionAddGradient => 'Добавить градиентный фон';

  @override
  String get aiSuggestionLightMode => 'Переключить на светлую тему';

  @override
  String get aiSuggestionDarkMode => 'Переключить на тёмную тему';

  @override
  String get aiSuggestionAddHeadline => 'Добавить цепляющий заголовок';

  @override
  String get aiSuggestionBiggerTitle => 'Увеличить заголовок';

  @override
  String get aiSuggestionAddSubtitle => 'Добавить подзаголовок';

  @override
  String get aiSuggestionTiltFrame => 'Наклонить рамку';

  @override
  String get aiSuggestionRoundCorners => 'Скруглить углы';

  @override
  String get aiSuggestionWriteHeadline => 'Написать цепляющий заголовок';

  @override
  String get aiSuggestionColorPalette => 'Предложить цветовую палитру';

  @override
  String get aiSuggestionAddDoodle => 'Добавить фон с рисунком';

  @override
  String get aiSuggestionEmojiDoodle => 'Использовать эмодзи-паттерн';

  @override
  String get aiSuggestionAdd3DTilt => 'Добавить 3D-наклон';

  @override
  String get aiSuggestionTransparentBg => 'Прозрачный фон';

  @override
  String get aiSuggestionLandscapeMode => 'Альбомная ориентация';

  @override
  String get magnifierShapeLabel => 'Форма';

  @override
  String get magnifierShapeCircle => 'Круг';

  @override
  String get magnifierShapeRounded => 'Скруглённый';

  @override
  String get magnifierShapeStar => 'Звезда';

  @override
  String get magnifierShapeHexagon => 'Шестиугольник';

  @override
  String get magnifierShapeDiamond => 'Ромб';

  @override
  String get magnifierShapeHeart => 'Сердце';

  @override
  String magnifierCorner(int value) {
    return 'Угол: $value';
  }

  @override
  String magnifierPoints(int value) {
    return 'Точки: $value';
  }

  @override
  String magnifierZoom(String value) {
    return 'Масштаб: $value×';
  }

  @override
  String magnifierWidth(int value) {
    return 'Ширина: $value';
  }

  @override
  String magnifierHeight(int value) {
    return 'Высота: $value';
  }

  @override
  String magnifierBorder(String value) {
    return 'Граница: $value';
  }

  @override
  String magnifierSourceX(int value) {
    return 'Источник X: $value';
  }

  @override
  String magnifierSourceY(int value) {
    return 'Источник Y: $value';
  }

  @override
  String magnifierOpacity(int value) {
    return 'Непрозрачность: $value%';
  }

  @override
  String get bringForward => 'На передний план';

  @override
  String get sendBackward => 'На задний план';

  @override
  String get inFrontOfFrame => 'Перед рамкой';

  @override
  String get behindFrame => 'За рамкой';
}
