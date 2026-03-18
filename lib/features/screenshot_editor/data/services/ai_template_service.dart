import 'dart:convert';

import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_preset.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/ai_provider_config.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/apple_fm_provider.dart';
import 'package:app_screenshots/features/screenshot_editor/domain/repositories/ai_provider_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Generates [ScreenshotPreset] templates from a user description
/// using either Apple Foundation Models (on-device) or Google Gemini.
class AiTemplateService {
  final AIProviderRepository _providerRepo;
  final http.Client _client;

  static const _channel = MethodChannel('com.appscreenshots/ai');

  AiTemplateService(this._providerRepo, {http.Client? client})
    : _client = client ?? http.Client();

  /// Generate a screenshot preset from a user description.
  ///
  /// Tries Apple FM first if available and configured as the active
  /// provider, otherwise falls back to Gemini API.
  Future<ScreenshotPreset> generate(String description) async {
    final config = await _providerRepo.getConfig();

    // Try Apple FM if it's the active provider and available
    if (config.activeProvider == AIProviderType.appleFM) {
      final available = await AppleFMTranslationProvider.isAvailable();
      if (available) {
        return _generateWithAppleFM(description);
      }
    }

    // Fall back to Gemini
    final apiKey = config.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw const AiTemplateException(
        'No API key configured. Please set up a Gemini API key in Settings.',
      );
    }
    return _generateWithGemini(description, apiKey);
  }

  // ---------------------------------------------------------------------------
  // Apple FM
  // ---------------------------------------------------------------------------

  Future<ScreenshotPreset> _generateWithAppleFM(String description) async {
    try {
      final resultJson = await _channel.invokeMethod<String>(
        'generateTemplate',
        {'description': description},
      );

      if (resultJson == null || resultJson.isEmpty) {
        throw const AiTemplateException(
          'Empty response from Apple Foundation Model.',
        );
      }

      // Strip markdown fences if present (Apple FM may wrap in ```)
      String cleaned = resultJson.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
        cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
        cleaned = cleaned.trim();
      }

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return _parsePreset(json);
    } on PlatformException catch (e) {
      throw AiTemplateException('Apple FM error: ${e.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // Gemini
  // ---------------------------------------------------------------------------

  Future<ScreenshotPreset> _generateWithGemini(
    String description,
    String apiKey,
  ) async {
    const model = 'gemini-2.0-flash';
    final prompt = _buildPrompt(description);

    final response = await _client.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta'
        '/models/$model:generateContent?key=$apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'responseMimeType': 'application/json'},
      }),
    );

    if (response.statusCode != 200) {
      throw AiTemplateException(
        'Gemini API error (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = body['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw const AiTemplateException('Gemini returned no candidates.');
    }

    final content = candidates[0]['content']['parts'][0]['text'] as String;
    final json = jsonDecode(content) as Map<String, dynamic>;
    return _parsePreset(json);
  }

  // ---------------------------------------------------------------------------
  // Prompt
  // ---------------------------------------------------------------------------

  static String _buildPrompt(String description) {
    return '''
You are an elite App Store screenshot designer and copywriter.
Screenshots are ADVERTISEMENTS, not documentation. Every slide sells ONE idea.

User description: "$description"

Return a JSON object with this EXACT structure:
{
  "name": "Preset Name (2-3 words)",
  "description": "Short description (under 40 chars)",
  "titleFont": "Google Font name",
  "thumbnailColors": ["#HEX1", "#HEX2"],
  "titleAlign": "left",
  "designs": [
    {
      "backgroundColor": "#HEX",
      "gradientColors": ["#HEX1", "#HEX2"],
      "gradientBegin": "topLeft",
      "gradientEnd": "bottomRight",
      "layout": "centered",
      "title": "Feature\\nHeadline",
      "subtitle": "Supporting text here",
      "titleSize": 100,
      "titleWeight": 700,
      "titleFontStyle": "normal",
      "titleColor": "#FFFFFF",
      "subtitleSize": 46,
      "subtitleColor": "#FFFFFFB3",
      "pills": []
    }
  ]
}

## COPYWRITING RULES (critical)
- Each headline sells ONE idea. NEVER join two ideas with "and".
- 3-5 words per line maximum. Must be readable at thumbnail size.
- Use one of three approaches per slide:
  * Paint a moment: "Check your coffee without opening the app"
  * State an outcome: "A home for every coffee you buy"
  * Kill a pain: "Never waste a great bag of coffee"
- Use \\n for intentional line breaks (max 3 lines).
- Subtitles: concise, one line, under 35 chars. Set subtitleSize=0 and subtitle="" to omit.

## NARRATIVE ARC (slide sequence)
- Slide 1: HERO — Main benefit, the #1 thing the app does. Big, bold.
- Slide 2: DIFFERENTIATOR — What makes this unique vs competitors.
- Slides 3-4: CORE FEATURES — One feature per slide, most important first.
- Slide 5: TRUST/MORE — Either a trust signal or a "more features" pill slide.
  For pill slides, set pills: ["Feature A", "Feature B", ...] (4-8 short labels).

## LAYOUT VARIETY (critical — never repeat same layout consecutively)
Each design MUST specify a "layout" field. Available:
- "centered": phone centered, text above (default hero, feature slides)
- "text-bottom": phone at top, headline below the frame
- "left-offset": phone pushed left with slight tilt, text on right
- "right-offset": phone pushed right with slight tilt, text on left
- "hero-only": NO phone frame — large centered text only (great for slide 1 or 5)
Vary layouts across all 5 slides. NEVER use the same layout twice in a row.

## VISUAL CONTRAST
- At least ONE slide must use an inverted/contrasting background for visual rhythm.
  Dark presets: include one light slide. Light presets: include one dark slide.
- Use gradients — even subtle ones add depth. Avoid plain solid colors.

## FONT MATCHING
Pick a Google Font that matches the mood:
- Tech/modern: Inter, Space Grotesk, Outfit
- Premium/elegant: Playfair Display, Lora
- Playful/fun: Quicksand, Poppins, Fredoka
- Bold/dramatic: Oswald, Montserrat
- Clean/minimal: Inter, DM Sans

## TECHNICAL RULES
1. Generate exactly 5 designs.
2. titleWeight: 400, 600, 700, 800, or 900.
3. titleFontStyle: "normal" or "italic".
4. Colors: valid hex (6 or 8 digits with #).
5. gradientBegin/End: "topLeft", "topCenter", "topRight", "centerLeft", "center", "centerRight", "bottomLeft", "bottomCenter", "bottomRight".
6. titleAlign: "left", "center", or "right".
7. pills array: only on the last slide if using a "more features" pattern. Each pill is a short string (1-3 words).
8. Make the overall palette harmonious and visually stunning.
''';
  }

  // ---------------------------------------------------------------------------
  // JSON → ScreenshotPreset
  // ---------------------------------------------------------------------------

  /// Resolve layout type string to concrete positions.
  static _LayoutPositions _layoutPositions(
    String layout,
    TextAlign titleAlign,
  ) {
    final isCenter = titleAlign == TextAlign.center;
    final double textX = isCenter ? 0 : 80;
    final double? textWidth = isCenter ? 1290 : null;

    return switch (layout) {
      'text-bottom' => _LayoutPositions(
        titlePos: Offset(textX, 2100),
        subtitlePos: Offset(textX, 2400),
        imagePos: const Offset(0, -300),
        textWidth: textWidth,
        frameRotation: 0,
      ),
      'left-offset' => _LayoutPositions(
        titlePos: Offset(textX, 100),
        subtitlePos: Offset(textX, 420),
        imagePos: const Offset(-200, 300),
        textWidth: textWidth,
        frameRotation: -3.0,
      ),
      'right-offset' => _LayoutPositions(
        titlePos: Offset(textX, 100),
        subtitlePos: Offset(textX, 420),
        imagePos: const Offset(200, 300),
        textWidth: textWidth,
        frameRotation: 3.0,
      ),
      'hero-only' => _LayoutPositions(
        titlePos: const Offset(0, 900),
        subtitlePos: const Offset(0, 1200),
        imagePos: const Offset(0, 5000), // off-screen — no phone
        textWidth: 1290,
        frameRotation: 0,
        forceCenter: true,
      ),
      _ => _LayoutPositions(
        // 'centered' — default
        titlePos: Offset(textX, 100),
        subtitlePos: Offset(textX, 420),
        imagePos: const Offset(0, 300),
        textWidth: textWidth,
        frameRotation: 0,
      ),
    };
  }

  static ScreenshotPreset _parsePreset(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'AI Template';
    final description =
        json['description'] as String? ?? 'AI-generated template';
    final titleFont = json['titleFont'] as String? ?? 'Inter';
    final titleAlignStr = json['titleAlign'] as String? ?? 'left';

    final thumbnailColorStrs =
        (json['thumbnailColors'] as List?)?.cast<String>() ??
        ['#6366F1', '#8B5CF6'];
    final thumbnailColors = thumbnailColorStrs.map(_parseHexColor).toList();

    final titleAlign = switch (titleAlignStr) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    };

    final designsJson = (json['designs'] as List?) ?? [];
    if (designsJson.isEmpty) {
      throw const AiTemplateException('AI response missing designs array.');
    }

    final designs = List<ScreenshotDesign>.generate(5, (i) {
      final d = designsJson[i % designsJson.length] as Map<String, dynamic>;

      final bgColor = _parseHexColor(
        d['backgroundColor'] as String? ?? '#000000',
      );
      final gradientColorStrs = (d['gradientColors'] as List?)?.cast<String>();

      Gradient? gradient;
      if (gradientColorStrs != null && gradientColorStrs.length >= 2) {
        gradient = LinearGradient(
          begin: _parseAlignment(d['gradientBegin'] as String?),
          end: _parseAlignment(d['gradientEnd'] as String?),
          colors: gradientColorStrs.map(_parseHexColor).toList(),
        );
      }

      final title = d['title'] as String? ?? 'Feature ${i + 1}';
      final subtitle = d['subtitle'] as String? ?? '';
      final titleSize = (d['titleSize'] as num?)?.toDouble() ?? 100;
      final titleWeightVal = (d['titleWeight'] as num?)?.toInt() ?? 700;
      final titleFontStyleStr = d['titleFontStyle'] as String? ?? 'normal';
      final titleColor = _parseHexColor(
        d['titleColor'] as String? ?? '#FFFFFF',
      );
      final subtitleSize = (d['subtitleSize'] as num?)?.toDouble() ?? 46;
      final subtitleColor = _parseHexColor(
        d['subtitleColor'] as String? ?? '#FFFFFFB3',
      );

      final titleWeight = _parseFontWeight(titleWeightVal);
      final titleFontStyle = titleFontStyleStr == 'italic'
          ? FontStyle.italic
          : FontStyle.normal;

      // Layout variation
      final layout = d['layout'] as String? ?? 'centered';
      final lp = _layoutPositions(layout, titleAlign);
      final effectiveAlign = lp.forceCenter ? TextAlign.center : titleAlign;

      final id = 'ai_${name.replaceAll(' ', '_').toLowerCase()}';
      final overlays = <TextOverlay>[
        TextOverlay(
          id: '${id}_${i}_title',
          text: title,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: titleWeight,
            fontStyle: titleFontStyle,
            color: titleColor,
          ),
          googleFont: titleFont,
          position: lp.titlePos,
          textAlign: effectiveAlign,
          width: lp.textWidth,
        ),
        if (subtitleSize > 0 && subtitle.isNotEmpty)
          TextOverlay(
            id: '${id}_${i}_sub',
            text: subtitle,
            style: TextStyle(
              fontSize: subtitleSize,
              fontWeight: FontWeight.w400,
              color: subtitleColor,
            ),
            googleFont: titleFont,
            position: lp.subtitlePos,
            textAlign: effectiveAlign,
            width: lp.textWidth,
          ),
      ];

      // "More Features" pill overlays
      final pillsJson = (d['pills'] as List?)?.cast<String>() ?? [];
      if (pillsJson.isNotEmpty) {
        const pillFontSize = 40.0;
        const pillY0 = 1500.0;
        const pillSpacingY = 100.0;
        const pillSpacingX = 400.0;
        final pillBgColor = titleColor.withValues(alpha: 0.15);

        for (var p = 0; p < pillsJson.length; p++) {
          final row = p ~/ 2;
          final col = p % 2;
          final px = 100.0 + col * pillSpacingX;
          final py = pillY0 + row * pillSpacingY;
          overlays.add(
            TextOverlay(
              id: '${id}_${i}_pill_$p',
              text: pillsJson[p],
              style: TextStyle(
                fontSize: pillFontSize,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
              googleFont: titleFont,
              position: Offset(px, py),
              backgroundColor: pillBgColor,
              borderRadius: 20,
              horizontalPadding: 20,
              verticalPadding: 10,
            ),
          );
        }
      }

      return ScreenshotDesign(
        backgroundColor: bgColor,
        backgroundGradient: gradient,
        padding: 200,
        imagePosition: lp.imagePos,
        frameRotation: lp.frameRotation,
        overlays: overlays,
      );
    });

    return ScreenshotPreset(
      id: 'ai_generated_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      thumbnailColors: thumbnailColors,
      titleFont: titleFont,
      designs: designs,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static Color _parseHexColor(String hex) {
    String h = hex.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }

  static FontWeight _parseFontWeight(int weight) {
    return switch (weight) {
      100 => FontWeight.w100,
      200 => FontWeight.w200,
      300 => FontWeight.w300,
      400 => FontWeight.w400,
      500 => FontWeight.w500,
      600 => FontWeight.w600,
      700 => FontWeight.w700,
      800 => FontWeight.w800,
      900 => FontWeight.w900,
      _ => FontWeight.w700,
    };
  }

  static Alignment _parseAlignment(String? value) {
    return switch (value) {
      'topLeft' => Alignment.topLeft,
      'topCenter' => Alignment.topCenter,
      'topRight' => Alignment.topRight,
      'centerLeft' => Alignment.centerLeft,
      'center' => Alignment.center,
      'centerRight' => Alignment.centerRight,
      'bottomLeft' => Alignment.bottomLeft,
      'bottomCenter' => Alignment.bottomCenter,
      'bottomRight' => Alignment.bottomRight,
      _ => Alignment.topLeft,
    };
  }
}

/// Internal helper holding resolved layout positions.
class _LayoutPositions {
  final Offset titlePos;
  final Offset subtitlePos;
  final Offset imagePos;
  final double? textWidth;
  final double frameRotation;
  final bool forceCenter;

  const _LayoutPositions({
    required this.titlePos,
    required this.subtitlePos,
    required this.imagePos,
    required this.textWidth,
    required this.frameRotation,
    this.forceCenter = false,
  });
}

/// Exception thrown when AI template generation fails.
class AiTemplateException implements Exception {
  final String message;
  const AiTemplateException(this.message);

  @override
  String toString() => 'AiTemplateException: $message';
}
