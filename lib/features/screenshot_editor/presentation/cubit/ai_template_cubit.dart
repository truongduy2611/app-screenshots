import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_preset.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/ai_template_service.dart';
import 'package:app_screenshots/features/screenshot_editor/domain/repositories/ai_provider_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'ai_template_state.dart';

/// Cubit managing AI template generation state.
///
/// Handles the lifecycle of generating a [ScreenshotPreset] from a
/// user description via [AiTemplateService].
class AiTemplateCubit extends Cubit<AiTemplateState> {
  final AIProviderRepository _providerRepo;
  late final AiTemplateService _service;

  AiTemplateCubit(this._providerRepo) : super(const AiTemplateState()) {
    _service = AiTemplateService(_providerRepo);
  }

  /// Update the user description text.
  void updateDescription(String description) {
    emit(state.copyWith(description: description, clearError: true));
  }

  /// Generate a preset from the current description.
  Future<void> generate() async {
    final description = state.description.trim();
    if (description.isEmpty) return;

    emit(state.copyWith(status: AiTemplateStatus.generating, clearError: true));

    try {
      final preset = await _service.generate(description);
      emit(state.copyWith(status: AiTemplateStatus.success, preset: preset));
    } on AiTemplateException catch (e) {
      emit(
        state.copyWith(status: AiTemplateStatus.error, errorMessage: e.message),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AiTemplateStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
