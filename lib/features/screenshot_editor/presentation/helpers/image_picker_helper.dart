import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:app_screenshots/core/extensions/context_extensions.dart';

class ImagePickerHelper {
  /// Prompts the user to select an image source (Camera or Gallery/Files)
  /// and returns the selected files.
  /// If [allowMultiple] is true and Gallery is selected, multiple files can be selected.
  static Future<List<File>> pickImage({
    required BuildContext context,
    bool allowMultiple = false,
  }) async {
    final isMobile = Platform.isIOS || Platform.isAndroid;

    if (!isMobile) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: allowMultiple,
      );
      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((f) => f.path != null)
            .map((f) => File(f.path!))
            .toList();
      }
      return const [];
    }

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  context.l10n.selectSource,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Symbols.photo_camera_rounded,
                  color: context.colorScheme.primary,
                ),
                title: Text(context.l10n.takePhoto),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(
                  Symbols.image_rounded,
                  color: context.colorScheme.primary,
                ),
                title: Text(context.l10n.chooseFromGallery),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return const [];

    if (source == ImageSource.camera) {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.camera);
      if (file != null) {
        return [File(file.path)];
      }
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: allowMultiple,
      );
      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((f) => f.path != null)
            .map((f) => File(f.path!))
            .toList();
      }
    }
    return const [];
  }
}
