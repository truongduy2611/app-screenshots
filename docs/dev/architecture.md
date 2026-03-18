# 🏗️ App Screenshots — Architecture Reference

## Overview

App Screenshots follows **Clean Architecture** (simplified, no use cases) with **BLoC/Cubit** for state management and **TDD** as the development methodology.

```
┌──────────────────────────────────────────┐
│              Presentation                │
│  (Pages, Widgets, Cubits, States)        │
├──────────────────────────────────────────┤
│                Domain                    │
│  (Repository Interfaces, Entities)       │
├──────────────────────────────────────────┤
│                 Data                     │
│  (Repository Implementations, Models,   │
│   Services, Data Sources)               │
└──────────────────────────────────────────┘
```

> [!IMPORTANT]
> **No Use Cases layer.** For simplicity, Cubits interact directly with Repository interfaces. Use cases should only be introduced if business logic becomes complex enough to warrant reuse across multiple Cubits.

---

## Directory Structure

```
lib/
├── main.dart                          # Entry point: init DI → runApp
├── app.dart                           # Root MaterialApp with BlocProviders
├── home_screen.dart                   # Primary screen shell
│
├── core/
│   ├── di/
│   │   └── service_locator.dart       # GetIt dependency registration
│   ├── theme/
│   │   └── app_theme.dart             # Material 3 light/dark themes
│   └── extensions/
│       └── context_extensions.dart    # BuildContext convenience getters
│
└── features/
    └── <feature_name>/
        ├── data/
        │   ├── models/                # Data models (JSON serializable)
        │   ├── services/              # External service wrappers
        │   └── repositories/          # Repository implementations
        ├── domain/
        │   └── repositories/          # Abstract repository interfaces
        └── presentation/
            ├── cubit/                 # Cubits + States
            ├── pages/                 # Full-screen pages
            └── widgets/               # Reusable UI components
```

---

## Layer Rules

### Presentation → Domain → Data

| Rule | Description |
|------|-------------|
| **Presentation depends on Domain** | Cubits reference repository interfaces, never implementations |
| **Data depends on Domain** | Implementations fulfill domain interfaces |
| **Domain depends on nothing** | Pure Dart, no Flutter imports (except `material.dart` for enums like `ThemeMode`) |
| **No cross-feature imports** | Features communicate through DI or shared core utilities |

### Dependency Flow

```
Cubit ──→ Repository (interface) ←── RepositoryImpl ──→ Service / DataSource
  │                                          │
  └── injected via GetIt ──────────────────────┘
```

---

## State Management: BLoC / Cubit

### When to use Cubit vs Bloc

| Use | When |
|-----|------|
| **Cubit** | Simple state transitions with methods (most cases) |
| **Bloc** | Complex event-driven flows with multiple event types |

### Cubit Pattern

```dart
// State — immutable, Equatable
class FeatureState extends Equatable {
  final SomeData data;
  final bool isLoading;

  const FeatureState({this.data, this.isLoading = false});

  FeatureState copyWith({SomeData? data, bool? isLoading}) {
    return FeatureState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [data, isLoading];
}

// Cubit — methods, not events
class FeatureCubit extends Cubit<FeatureState> {
  final FeatureRepository _repository;

  FeatureCubit(this._repository) : super(const FeatureState());

  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true));
    final data = await _repository.getData();
    emit(state.copyWith(data: data, isLoading: false));
  }
}
```

### State Patterns

| Pattern | Usage |
|---------|-------|
| **Single state + `copyWith`** | Simple features (Settings, Theme) |
| **Abstract state + subclasses** | Features with distinct modes (Initial, Loading, Loaded, Error) |

---

## Dependency Injection

### GetIt Service Locator

```dart
final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // 1. External dependencies (async)
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // 2. Repositories (lazy singletons)
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl()),
  );

  // 3. Cubits (factory — new instance per use)
  sl.registerFactory(() => ThemeCubit(sl()));
}
```

### Registration Rules

| Type | Registration | When |
|------|-------------|------|
| **External deps** | `registerSingleton` | `SharedPreferences`, DB instances |
| **Repositories** | `registerLazySingleton` | One instance, created on first use |
| **Cubits** | `registerFactory` | New instance each time (BlocProvider creates) |
| **Services** | `registerLazySingleton` | Persistence, API clients |

---

## TDD Approach

### Test Structure (Mirror)

```
test/
└── features/
    └── <feature_name>/
        ├── data/
        │   └── repositories/
        │       └── <repo>_impl_test.dart
        └── presentation/
            └── cubit/
                └── <cubit>_test.dart
```

### Test Types

| Type | Tools | What to test |
|------|-------|--------------|
| **Unit (Cubit)** | `bloc_test`, `mocktail` | State transitions, method calls |
| **Unit (Repository)** | `flutter_test`, `mocktail` | Data mapping, persistence logic |
| **Widget** | `flutter_test` | UI rendering, user interactions |
| **Integration** | `integration_test` | End-to-end flows |

### Cubit Test Pattern

```dart
class MockRepository extends Mock implements FeatureRepository {}

void main() {
  late MockRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(SomeFallback()); // for mocktail's any()
  });

  setUp(() {
    mockRepo = MockRepository();
  });

  // Initial state
  test('initial state is correct', () {
    final cubit = FeatureCubit(mockRepo);
    expect(cubit.state, const FeatureState());
  });

  // Behavior
  blocTest<FeatureCubit, FeatureState>(
    'loadData emits loaded state',
    build: () {
      when(() => mockRepo.getData()).thenAnswer((_) async => someData);
      return FeatureCubit(mockRepo);
    },
    act: (cubit) => cubit.loadData(),
    expect: () => [
      const FeatureState(isLoading: true),
      FeatureState(data: someData, isLoading: false),
    ],
  );
}
```

### Repository Test Pattern

```dart
void main() {
  late RepositoryImpl repo;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = RepositoryImpl(prefs);
  });

  test('returns default when no value stored', () async {
    final result = await repo.getValue();
    expect(result, defaultValue);
  });

  test('persists and returns value', () async {
    await repo.setValue(newValue);
    final result = await repo.getValue();
    expect(result, newValue);
  });
}
```

---

## Adding a New Feature — Checklist

1. **Create directory structure:**
   ```
   lib/features/<name>/data/models/
   lib/features/<name>/data/repositories/
   lib/features/<name>/domain/repositories/
   lib/features/<name>/presentation/cubit/
   lib/features/<name>/presentation/pages/
   lib/features/<name>/presentation/widgets/
   ```

2. **Domain layer first:**
   - Define repository interface in `domain/repositories/`
   - Define entities/models if needed

3. **Write tests (TDD):**
   - Create test files mirroring the source structure
   - Write failing tests for repository and cubit

4. **Data layer:**
   - Implement repository in `data/repositories/`
   - Create data models in `data/models/`

5. **Presentation layer:**
   - Create Cubit + State in `presentation/cubit/`
   - Create pages and widgets

6. **Register in DI:**
   - Add repository and cubit to `service_locator.dart`

7. **Wire up in UI:**
   - Add `BlocProvider` in `app.dart` or at the page level

---

## Conventions

| Convention | Standard |
|------------|----------|
| **File naming** | `snake_case.dart` |
| **Class naming** | `PascalCase` |
| **Feature folders** | `snake_case` |
| **State class** | `part of` cubit file |
| **Equatable** | All states must extend `Equatable` |
| **Icons** | `material_symbols_icons` (Rounded variant) |
| **Fonts** | `google_fonts` (Inter) |
| **Theme** | `context.theme`, `context.colorScheme`, `context.textTheme` via extensions |
| **Imports** | Absolute (`package:app_screenshots/...`) |
| **Linting** | `flutter_lints` rules |
