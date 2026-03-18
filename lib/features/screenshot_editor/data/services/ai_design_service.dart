import 'dart:convert';

import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/ai_provider_config.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/apple_fm_provider.dart';
import 'package:app_screenshots/features/screenshot_editor/domain/repositories/ai_provider_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/manual_design_assist_dialog.dart';

/// Processes natural-language design requests and returns a modified
/// [ScreenshotDesign]. Uses the same AI provider config as translations.
class AiDesignService {
  final AIProviderRepository _providerRepo;
  final http.Client _client;

  static const _channel = MethodChannel('com.appscreenshots/ai');

  /// Set this to a [BuildContext] in debug mode to enable the manual
  /// copy/paste dialog before each AI call. Should be set in the cubit/page.
  static BuildContext? debugContext;

  AiDesignService(this._providerRepo, {http.Client? client})
    : _client = client ?? http.Client();

  /// Process a user's design request and return the updated design + explanation.
  ///
  /// [conversationHistory] is an optional list of previous messages for context.
  Future<AiDesignResponse> processRequest(
    ScreenshotDesign currentDesign,
    String userPrompt, {
    List<Map<String, String>>? conversationHistory,
  }) async {
    final config = await _providerRepo.getConfig();
    final designJson = jsonEncode(currentDesign.toJson());

    // --- Debug mode: show manual copy/paste dialog ---
    if (kDebugMode && debugContext != null) {
      final providerLabel = config.activeProvider.name.toUpperCase();
      // Build the prompt that would be sent
      String prompt;
      if (config.activeProvider == AIProviderType.appleFM) {
        prompt = _buildAppleFMPrompt(
          currentDesign,
          userPrompt,
          conversationHistory: conversationHistory,
        );
      } else {
        prompt = _buildFullPrompt(
          designJson,
          userPrompt,
          conversationHistory: conversationHistory,
        );
      }

      final manualResult = await ManualDesignAssistDialog.show(
        context: debugContext!,
        sourceRect: Rect.zero,
        prompt: prompt,
        providerLabel: providerLabel,
      );

      // null = cancelled
      if (manualResult == null) {
        throw const AiDesignException('Debug: cancelled by user.');
      }
      // '__SKIP__' = skip debug, use real AI
      if (manualResult != '__SKIP__') {
        return _parseResponse(manualResult, currentDesign);
      }
    }

    // Try Apple FM first
    if (config.activeProvider == AIProviderType.appleFM) {
      final available = await AppleFMTranslationProvider.isAvailable();
      if (available) {
        return _processWithAppleFM(
          designJson,
          userPrompt,
          currentDesign,
          conversationHistory: conversationHistory,
        );
      }
    }

    // Fall back to cloud API
    final apiKey = config.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw const AiDesignException(
        'No API key configured. Please set up an API key in Settings.',
      );
    }

    if (config.activeProvider == AIProviderType.openai) {
      return _processWithOpenAI(
        designJson,
        userPrompt,
        currentDesign,
        apiKey,
        config.customModel ?? 'gpt-4o-mini',
        conversationHistory: conversationHistory,
      );
    }

    return _processWithGemini(
      designJson,
      userPrompt,
      currentDesign,
      apiKey,
      conversationHistory: conversationHistory,
    );
  }

  // ---------------------------------------------------------------------------
  // Apple FM
  // ---------------------------------------------------------------------------

  Future<AiDesignResponse> _processWithAppleFM(
    String designJson,
    String userPrompt,
    ScreenshotDesign currentDesign, {
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      // Build a lean prompt for Apple FM — the @Generable struct on the Swift
      // side already enforces the output schema, so we skip format instructions
      // and send only a compact design summary + the user request.
      final prompt = _buildAppleFMPrompt(
        currentDesign,
        userPrompt,
        conversationHistory: conversationHistory,
      );
      debugPrint(
        '[AiDesignService] Apple FM designAssist: '
        'prompt.length=${prompt.length}',
      );
      if (kDebugMode) {
        debugPrint('=== APPLE FM INPUT PROMPT ===');
        debugPrint(prompt);
        debugPrint('=== END INPUT PROMPT ===');
      }
      final result = await _channel
          .invokeMethod<String>('designAssist', {'prompt': prompt})
          .timeout(
            const Duration(seconds: 120),
            onTimeout: () => throw const AiDesignException(
              'Apple FM timed out after 120 seconds. '
              'On-device AI may be too slow for this request. '
              'Try a simpler prompt or switch to a cloud provider.',
            ),
          );
      debugPrint(
        '[AiDesignService] Apple FM designAssist: '
        'response.length=${result?.length}',
      );
      if (kDebugMode) {
        debugPrint('=== APPLE FM OUTPUT RESPONSE ===');
        debugPrint(result ?? '(null)');
        debugPrint('=== END OUTPUT RESPONSE ===');
      }

      if (result == null || result.isEmpty) {
        throw const AiDesignException('Empty response from Apple FM.');
      }

      return _parseResponse(result, currentDesign);
    } on PlatformException catch (e) {
      throw AiDesignException('Apple FM error: ${e.message}');
    }
  }

  /// Builds a compact prompt optimized for Apple FM's on-device model.
  ///
  /// Key differences from [_buildFullPrompt]:
  /// - No JSON format instructions (handled by Swift @Generable)
  /// - Stripped design JSON (only fields relevant to design changes)
  /// - Concise behavioral rules instead of verbose documentation
  static String _buildAppleFMPrompt(
    ScreenshotDesign design,
    String userPrompt, {
    List<Map<String, String>>? conversationHistory,
  }) {
    // Build a minimal design summary instead of the full JSON
    final summary = StringBuffer();
    summary.writeln(
      'Background: #${design.backgroundColor.toARGB32().toRadixString(16).padLeft(8, '0')}',
    );
    if (design.backgroundGradient != null) {
      final g = design.backgroundGradient!;
      if (g is LinearGradient) {
        final hexColors = g.colors
            .map((c) => '#${c.toARGB32().toRadixString(16).padLeft(8, '0')}')
            .join(', ');
        summary.writeln('Gradient: linear [$hexColors]');
      }
    }
    summary.writeln(
      'Padding: ${design.padding.toInt()}, CornerRadius: ${design.cornerRadius.toInt()}',
    );
    if (design.frameRotation != 0) {
      summary.writeln('FrameRotation: ${design.frameRotation.toInt()}°');
    }
    // Text overlays — compact summary
    for (var i = 0; i < design.overlays.length; i++) {
      final t = design.overlays[i];
      final weight = ((t.style.fontWeight?.value ?? 3) * 100 + 100);
      summary.write(
        'Text[$i]: "${t.text}" '
        'size=${t.style.fontSize?.toInt()} weight=$weight '
        'color=#${t.style.color?.toARGB32().toRadixString(16).padLeft(8, '0')}',
      );
      if (t.googleFont != null) summary.write(' font=${t.googleFont}');
      summary.writeln();
    }

    final buf = StringBuffer();
    buf.writeln('You are an App Store screenshot design assistant.');
    buf.writeln(
      'Only change what the user asks. Never touch rotation unless asked.',
    );
    buf.writeln();
    buf.writeln('CURRENT DESIGN:');
    buf.write(summary);
    buf.writeln();
    // Conversation history (compact)
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      buf.writeln('HISTORY:');
      for (final msg in conversationHistory) {
        buf.writeln('${msg['role']}: ${msg['content']}');
      }
      buf.writeln();
    }
    buf.writeln('REQUEST: "$userPrompt"');
    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // Gemini
  // ---------------------------------------------------------------------------

  Future<AiDesignResponse> _processWithGemini(
    String designJson,
    String userPrompt,
    ScreenshotDesign currentDesign,
    String apiKey, {
    List<Map<String, String>>? conversationHistory,
  }) async {
    const model = 'gemini-2.0-flash';
    final prompt = _buildFullPrompt(
      designJson,
      userPrompt,
      conversationHistory: conversationHistory,
    );
    if (kDebugMode) {
      debugPrint('=== GEMINI INPUT PROMPT ===');
      debugPrint(prompt);
      debugPrint('=== END INPUT PROMPT ===');
    }

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
      throw AiDesignException(
        'Gemini API error (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = body['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw const AiDesignException('Gemini returned no candidates.');
    }

    final content = candidates[0]['content']['parts'][0]['text'] as String;
    if (kDebugMode) {
      debugPrint('=== GEMINI OUTPUT RESPONSE ===');
      debugPrint(content);
      debugPrint('=== END OUTPUT RESPONSE ===');
    }
    return _parseResponse(content, currentDesign);
  }

  // ---------------------------------------------------------------------------
  // OpenAI
  // ---------------------------------------------------------------------------

  Future<AiDesignResponse> _processWithOpenAI(
    String designJson,
    String userPrompt,
    ScreenshotDesign currentDesign,
    String apiKey,
    String model, {
    List<Map<String, String>>? conversationHistory,
  }) async {
    final prompt = _buildFullPrompt(
      designJson,
      userPrompt,
      conversationHistory: conversationHistory,
    );
    if (kDebugMode) {
      debugPrint('=== OPENAI INPUT PROMPT ===');
      debugPrint(prompt);
      debugPrint('=== END INPUT PROMPT ===');
    }

    final response = await _client.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw AiDesignException(
        'OpenAI API error (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = body['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw const AiDesignException('OpenAI returned no choices.');
    }

    final content = choices[0]['message']['content'] as String;
    if (kDebugMode) {
      debugPrint('=== OPENAI OUTPUT RESPONSE ===');
      debugPrint(content);
      debugPrint('=== END OUTPUT RESPONSE ===');
    }
    return _parseResponse(content, currentDesign);
  }

  // ---------------------------------------------------------------------------
  // Prompt
  // ---------------------------------------------------------------------------

  static String _buildFullPrompt(
    String currentDesignJson,
    String userPrompt, {
    List<Map<String, String>>? conversationHistory,
  }) {
    return '''
You are an AI design assistant for App Store screenshots. The user has an existing
screenshot design and wants to modify it via natural language.

CURRENT DESIGN (JSON):
$currentDesignJson

USER REQUEST: "$userPrompt"

Respond with a JSON object containing ONLY the changes to apply. Structure:
{
  "changes": {
    // Top-level design properties (include ONLY what the user asked to change):
    "backgroundColor": "#HEXCOLOR",
    "gradientColors": ["#HEX1", "#HEX2"],
    "gradientType": "linear|radial|sweep",
    "gradientBegin": "topLeft|topCenter|topRight|centerLeft|center|centerRight|bottomLeft|bottomCenter|bottomRight",
    "gradientEnd": "topLeft|...|bottomRight",
    "clearGradient": true,
    "padding": 200,
    "cornerRadius": 80,
    "textAtBottom": true
    // ADVANCED (only include when EXPLICITLY asked):
    // "frameRotation": 10, "frameRotationX": 10, "frameRotationY": 10,
    // "transparentBackground": true, "orientation": "landscape",
    // "doodle": {"enabled": true, "emoji": ["🏋️"], "opacity": 0.08, "size": 40, "spacing": 60}
  },
  "textChanges": [
    // Modify existing text overlays by index (0 = first/title, 1 = subtitle)
    {
      "index": 0,
      "text": "New Title Text",
      "fontSize": 100,
      "fontWeight": 700,
      "fontStyle": "normal|italic",
      "color": "#FFFFFF",
      "googleFont": "Inter",
      "textAlign": "left|center|right",
      "rotation": 0.0,
      "decoration": "none|underline|lineThrough",
      "backgroundColor": "#RRGGBBAA",
      "borderColor": "#RRGGBBAA",
      "borderWidth": 2.0,
      "borderRadius": 8.0,
      "horizontalPadding": 16.0,
      "verticalPadding": 8.0,
      "scale": 1.0
    }
  ],
  "addText": [
    // Add NEW text overlays (e.g. when user asks "add a subtitle")
    {
      "text": "New subtitle here",
      "fontSize": 46,
      "fontWeight": 400,
      "color": "#FFFFFFB3",
      "googleFont": "Inter",
      "textAlign": "center"
    }
  ],
  "explanation": "Brief description of what was changed (1 sentence)"
}

CRITICAL CONSTRAINTS (MUST FOLLOW):
- NEVER include "frameRotation", "frameRotationX", or "frameRotationY" unless the user explicitly says words like "rotate", "tilt", "angle", "skew", "perspective", or "3D". If the user asks about colors, text, backgrounds, or anything else, do NOT touch rotation at all.
- NEVER include "orientation" unless the user explicitly says "landscape" or "portrait" or "orientation".
- NEVER include properties the user did not ask about. If they say "change background to blue", respond ONLY with backgroundColor.

Rules:
1. CRITICAL: Only include properties that the user EXPLICITLY asked to change — omit everything else. If the user says "tilt the frame", ONLY return frameRotation, nothing else. If the user says "make it blue", ONLY return backgroundColor.
2. Colors must be valid hex (#RRGGBB or #RRGGBBAA)
3. fontWeight: 400=regular, 500=medium, 600=semibold, 700=bold, 800=extrabold, 900=black
4. If the user asks for text content, update the "text" field in textChanges
5. If the user asks for a color scheme, update both background and text colors harmoniously
6. Keep the explanation concise and friendly
7. "clearGradient": true removes any existing gradient
8. gradientBegin/gradientEnd control LinearGradient alignment
9. textAlign: "left", "center", or "right" for text alignment
10. decoration: "underline" or "lineThrough" to decorate text
11. backgroundColor on textChanges adds a colored container/pill behind the text
12. frameRotation tilts the device screenshot in degrees (positive = clockwise). Use small values: 5-15 degrees for subtle tilt, never exceed 20 degrees. ONLY include if user explicitly asks.
13. textAtBottom: true puts text below the device; false puts text above (default)
14. Use addText[] when the user asks to add a NEW overlay; use textChanges[] to edit existing ones
15. For copywriting requests (headlines, subtitles), be creative and marketing-focused
16. FORBIDDEN: Do NOT include frameRotation, frameRotationX, or frameRotationY unless user explicitly asks to rotate/tilt/angle/skew the frame. This is the #1 most common mistake.
17. Do NOT include properties that match the current design values — only return what actually changes.
18. When the user asks for ONE specific change (e.g. "tilt frame"), respond with ONLY that property. Do not "improve" other properties at the same time.
19. frameRotationX/frameRotationY add 3D perspective tilt along X/Y axes. Use small values: 5-15 degrees. Only include when user asks for 3D tilt or perspective effect.
20. "doodle" enables a repeating icon/emoji pattern background. Use "emoji" array for emoji doodles. Set "enabled": false to disable. Only include when user asks for doodle/pattern.
21. "gradientType" selects the gradient shape: "linear" (default), "radial" (circular), or "sweep" (angular). Only include when user asks for a specific gradient type.
22. "transparentBackground": true makes the background see-through for export. Only include when user explicitly asks for transparency.
23. "orientation" switches between "portrait" and "landscape". Only include when user explicitly asks to change orientation.
${_buildConversationContext(conversationHistory)}
''';
  }

  static String _buildConversationContext(List<Map<String, String>>? history) {
    if (history == null || history.isEmpty) return '';
    final buffer = StringBuffer('\nPREVIOUS CONVERSATION CONTEXT:\n');
    for (final msg in history) {
      final role = msg['role'] ?? 'user';
      final content = msg['content'] ?? '';
      buffer.writeln('$role: $content');
    }
    buffer.writeln(
      '\nUse the conversation context to understand follow-up requests.',
    );
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Response Parsing
  // ---------------------------------------------------------------------------

  AiDesignResponse _parseResponse(
    String rawJson,
    ScreenshotDesign currentDesign,
  ) {
    String cleaned = rawJson.trim();

    // Strip markdown fences
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
      cleaned = cleaned.trim();
    }

    final json = jsonDecode(cleaned) as Map<String, dynamic>;
    final changes = json['changes'] as Map<String, dynamic>? ?? {};
    final textChanges = (json['textChanges'] as List?) ?? [];
    final addTextList = (json['addText'] as List?) ?? [];
    final explanation = json['explanation'] as String? ?? 'Design updated';

    // Apply background/layout changes
    var design = currentDesign;

    if (changes.containsKey('backgroundColor')) {
      design = design.copyWith(
        backgroundColor: _parseHexColor(changes['backgroundColor'] as String),
      );
    }

    if (changes.containsKey('gradientColors')) {
      final colors = (changes['gradientColors'] as List)
          .cast<String>()
          .map(_parseHexColor)
          .toList();
      final gradientType = changes['gradientType'] as String? ?? 'linear';
      final Gradient gradient;
      switch (gradientType) {
        case 'radial':
          gradient = RadialGradient(colors: colors);
        case 'sweep':
          gradient = SweepGradient(colors: colors);
        default:
          final begin = _parseAlignment(changes['gradientBegin'] as String?);
          final end = _parseAlignment(changes['gradientEnd'] as String?);
          gradient = LinearGradient(begin: begin, end: end, colors: colors);
      }
      design = design.copyWith(
        backgroundGradient: gradient,
        clearMeshGradient: true,
      );
    } else if (changes['clearGradient'] == true) {
      design = design.copyWith(clearGradient: true);
    }

    if (changes.containsKey('padding')) {
      design = design.copyWith(padding: (changes['padding'] as num).toDouble());
    }

    if (changes.containsKey('cornerRadius')) {
      design = design.copyWith(
        cornerRadius: (changes['cornerRadius'] as num).toDouble(),
      );
    }

    if (changes.containsKey('frameRotation')) {
      design = design.copyWith(
        frameRotation: (changes['frameRotation'] as num).toDouble(),
      );
    }

    if (changes.containsKey('frameRotationX')) {
      design = design.copyWith(
        frameRotationX: (changes['frameRotationX'] as num).toDouble(),
      );
    }

    if (changes.containsKey('frameRotationY')) {
      design = design.copyWith(
        frameRotationY: (changes['frameRotationY'] as num).toDouble(),
      );
    }

    if (changes.containsKey('transparentBackground')) {
      design = design.copyWith(
        transparentBackground: changes['transparentBackground'] as bool,
      );
    }

    if (changes.containsKey('orientation')) {
      design = design.copyWith(
        orientation: (changes['orientation'] as String) == 'landscape'
            ? Orientation.landscape
            : Orientation.portrait,
      );
    }

    // Doodle background settings
    if (changes.containsKey('doodle')) {
      final doodleJson = changes['doodle'] as Map<String, dynamic>;
      final enabled = doodleJson['enabled'] as bool? ?? true;

      if (!enabled) {
        design = design.copyWith(clearDoodle: true);
      } else {
        final emojiList = (doodleJson['emoji'] as List?)
            ?.map((e) => e.toString())
            .toList();
        final hasEmoji = emojiList != null && emojiList.isNotEmpty;

        design = design.copyWith(
          doodleSettings: DoodleSettings(
            enabled: true,
            iconSource: hasEmoji
                ? DoodleIconSource.emoji
                : (design.doodleSettings?.iconSource ??
                      DoodleIconSource.sfSymbols),
            emojiCharacters: hasEmoji
                ? emojiList
                : (design.doodleSettings?.emojiCharacters ?? const []),
            iconCodePoints: design.doodleSettings?.iconCodePoints ?? const [],
            iconColor: doodleJson.containsKey('color')
                ? _parseHexColor(doodleJson['color'] as String)
                : (design.doodleSettings?.iconColor ?? Colors.white),
            iconOpacity:
                (doodleJson['opacity'] as num?)?.toDouble() ??
                design.doodleSettings?.iconOpacity ??
                0.08,
            iconSize:
                (doodleJson['size'] as num?)?.toDouble() ??
                design.doodleSettings?.iconSize ??
                40.0,
            spacing:
                (doodleJson['spacing'] as num?)?.toDouble() ??
                design.doodleSettings?.spacing ??
                60.0,
            rotation:
                (doodleJson['rotation'] as num?)?.toDouble() ??
                design.doodleSettings?.rotation ??
                0.0,
            randomizeRotation:
                doodleJson['randomizeRotation'] as bool? ??
                design.doodleSettings?.randomizeRotation ??
                false,
          ),
        );
      }
    }

    // Apply text overlay changes
    var overlays = List<TextOverlay>.from(design.overlays);

    if (textChanges.isNotEmpty) {
      for (final tc in textChanges) {
        final change = tc as Map<String, dynamic>;
        final index = (change['index'] as num).toInt();
        if (index >= overlays.length) continue;

        final existing = overlays[index];
        var style = existing.style;

        if (change.containsKey('fontSize')) {
          style = style.copyWith(
            fontSize: (change['fontSize'] as num).toDouble(),
          );
        }
        if (change.containsKey('fontWeight')) {
          style = style.copyWith(
            fontWeight: _parseFontWeight((change['fontWeight'] as num).toInt()),
          );
        }
        if (change.containsKey('fontStyle')) {
          style = style.copyWith(
            fontStyle: change['fontStyle'] == 'italic'
                ? FontStyle.italic
                : FontStyle.normal,
          );
        }
        if (change.containsKey('color')) {
          style = style.copyWith(
            color: _parseHexColor(change['color'] as String),
          );
        }

        overlays[index] = existing.copyWith(
          text: change['text'] as String? ?? existing.text,
          style: style,
          googleFont: change['googleFont'] as String? ?? existing.googleFont,
          textAlign: _parseTextAlign(change['textAlign'] as String?),
          rotation: change.containsKey('rotation')
              ? (change['rotation'] as num).toDouble()
              : null,
          decoration: _parseTextDecoration(change['decoration'] as String?),
          backgroundColor: change.containsKey('backgroundColor')
              ? _parseHexColor(change['backgroundColor'] as String)
              : null,
          borderColor: change.containsKey('borderColor')
              ? _parseHexColor(change['borderColor'] as String)
              : null,
          borderWidth: change.containsKey('borderWidth')
              ? (change['borderWidth'] as num).toDouble()
              : null,
          borderRadius: change.containsKey('borderRadius')
              ? (change['borderRadius'] as num).toDouble()
              : null,
          horizontalPadding: change.containsKey('horizontalPadding')
              ? (change['horizontalPadding'] as num).toDouble()
              : null,
          verticalPadding: change.containsKey('verticalPadding')
              ? (change['verticalPadding'] as num).toDouble()
              : null,
          scale: change.containsKey('scale')
              ? (change['scale'] as num).toDouble()
              : null,
        );
      }
    }

    // Add new text overlays
    if (addTextList.isNotEmpty) {
      for (final addItem in addTextList) {
        final item = addItem as Map<String, dynamic>;
        final text = item['text'] as String? ?? '';
        final fontSize = (item['fontSize'] as num?)?.toDouble() ?? 46.0;
        final fontWeight = _parseFontWeight(
          (item['fontWeight'] as num?)?.toInt() ?? 400,
        );
        final color = item.containsKey('color')
            ? _parseHexColor(item['color'] as String)
            : Colors.white;

        overlays.add(
          TextOverlay(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}_${overlays.length}',
            text: text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
            ),
            position: Offset(0, 200.0 + overlays.length * 80),
            googleFont: item['googleFont'] as String?,
            textAlign:
                _parseTextAlign(item['textAlign'] as String?) ??
                TextAlign.center,
          ),
        );
      }
    }

    design = design.copyWith(overlays: overlays);

    return AiDesignResponse(
      updatedDesign: design,
      explanation: explanation,
      rawDiff: json,
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

  static TextAlign? _parseTextAlign(String? value) {
    return switch (value) {
      'left' => TextAlign.left,
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => null,
    };
  }

  static TextDecoration? _parseTextDecoration(String? value) {
    return switch (value) {
      'underline' => TextDecoration.underline,
      'lineThrough' => TextDecoration.lineThrough,
      'none' => TextDecoration.none,
      _ => null,
    };
  }
}

/// The result of an AI design request.
class AiDesignResponse {
  final ScreenshotDesign updatedDesign;
  final String explanation;
  final Map<String, dynamic> rawDiff;

  const AiDesignResponse({
    required this.updatedDesign,
    required this.explanation,
    required this.rawDiff,
  });
}

/// Exception thrown when AI design assistance fails.
class AiDesignException implements Exception {
  final String message;
  const AiDesignException(this.message);

  @override
  String toString() => 'AiDesignException: $message';
}
