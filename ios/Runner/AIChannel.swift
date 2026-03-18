import Flutter
import Foundation

#if canImport(FoundationModels)
  import FoundationModels
#endif

/// MethodChannel bridge for on-device AI using Apple Foundation Models (iOS).
///
/// Handles four methods:
/// - `isAvailable`: Returns whether Apple Intelligence / FoundationModels is available.
/// - `translate`: Translates a JSON map of texts from one locale to another.
/// - `generateTemplate`: Generates a screenshot template preset from a description.
/// - `designAssist`: Applies natural-language design changes to an existing screenshot.
class AIChannel {
  static let channelName = "com.appscreenshots/ai"

  static func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isAvailable":
        if #available(iOS 26, *) {
          Task {
            let available = await checkAvailability()
            result(available)
          }
        } else {
          result(false)
        }

      case "translate":
        guard let args = call.arguments as? [String: Any],
          let textsJson = args["texts"] as? String,
          let from = args["from"] as? String,
          let to = args["to"] as? String
        else {
          result(
            FlutterError(
              code: "INVALID_ARGS",
              message: "Missing required arguments: texts, from, to",
              details: nil
            ))
          return
        }

        if #available(iOS 26, *) {
          Task {
            do {
              let translated = try await performTranslation(
                textsJson: textsJson, from: from, to: to
              )
              result(translated)
            } catch {
              result(
                FlutterError(
                  code: "TRANSLATION_ERROR",
                  message: error.localizedDescription,
                  details: nil
                ))
            }
          }
        } else {
          result(
            FlutterError(
              code: "UNAVAILABLE",
              message: "Apple Foundation Model requires iOS 26+",
              details: nil
            ))
        }

      case "generateTemplate":
        guard let args = call.arguments as? [String: Any],
          let description = args["description"] as? String
        else {
          result(
            FlutterError(
              code: "INVALID_ARGS",
              message: "Missing required argument: description",
              details: nil
            ))
          return
        }

        if #available(iOS 26, *) {
          Task {
            do {
              let generated = try await generateTemplate(
                description: description
              )
              result(generated)
            } catch {
              result(
                FlutterError(
                  code: "GENERATION_ERROR",
                  message: error.localizedDescription,
                  details: nil
                ))
            }
          }
        } else {
          result(
            FlutterError(
              code: "UNAVAILABLE",
              message: "Apple Foundation Model requires iOS 26+",
              details: nil
            ))
        }

      case "designAssist":
        guard let args = call.arguments as? [String: Any],
          let prompt = args["prompt"] as? String
        else {
          result(
            FlutterError(
              code: "INVALID_ARGS",
              message: "Missing required argument: prompt",
              details: nil
            ))
          return
        }

        if #available(iOS 26, *) {
          Task {
            do {
              let generated = try await designAssistWithTimeout(
                prompt: prompt, seconds: 90
              )
              result(generated)
            } catch {
              result(
                FlutterError(
                  code: "DESIGN_ASSIST_ERROR",
                  message: error.localizedDescription,
                  details: nil
                ))
            }
          }
        } else {
          result(
            FlutterError(
              code: "UNAVAILABLE",
              message: "Apple Foundation Model requires iOS 26+",
              details: nil
            ))
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  @available(iOS 26, *)
  private static func checkAvailability() async -> Bool {
    #if canImport(FoundationModels)
      let model = SystemLanguageModel.default
      switch model.availability {
      case .available:
        return true
      case .unavailable:
        return false
      }
    #else
      return false
    #endif
  }

  @available(iOS 26, *)
  private static func performTranslation(
    textsJson: String, from: String, to: String
  ) async throws -> String {
    #if canImport(FoundationModels)
      let session = LanguageModelSession()

      let prompt = """
        You are a professional App Store copywriter. Translate the following
        marketing texts from \(from) to \(to).
        Return ONLY a valid JSON object mapping each key to its translation.
        Keep translations concise — they appear as headline text on
        App Store screenshots. Preserve any emoji. Do not add explanations.

        Input:
        \(textsJson)
        """

      let response = try await session.respond(to: prompt)
      return response.content
    #else
      fatalError("Translation functionality is unavailable in this environment.")
    #endif

  }

  @available(iOS 26, *)
  private static func generateTemplate(
    description: String
  ) async throws -> String {
    #if canImport(FoundationModels)
      let session = LanguageModelSession()

      let prompt = """
        You are an expert App Store screenshot designer. Given a user's description,
        generate a beautiful screenshot preset with 5 designs for App Store screenshots.

        User description: "\(description)"

        Return ONLY a valid JSON object with this structure:
        {
          "name": "Preset Name (2-3 words)",
          "description": "Short description (under 40 chars)",
          "titleFont": "A Google Font name (e.g. Poppins, Inter, Montserrat, Outfit, Playfair Display)",
          "thumbnailColors": ["#HEX1", "#HEX2"],
          "textAtBottom": false,
          "titleAlign": "left",
          "designs": [
            {
              "backgroundColor": "#HEX",
              "gradientColors": ["#HEX1", "#HEX2"],
              "gradientBegin": "topLeft",
              "gradientEnd": "bottomRight",
              "title": "Feature Headline",
              "subtitle": "Supporting text",
              "titleSize": 100,
              "titleWeight": 700,
              "titleFontStyle": "normal",
              "titleColor": "#FFFFFF",
              "subtitleSize": 46,
              "subtitleColor": "#FFFFFFB3"
            }
          ]
        }

        Rules:
        1. Generate exactly 5 designs in the "designs" array
        2. Each design should have compelling App Store marketing text
        3. Use \\n for line breaks in titles (max 3 lines)
        4. Colors must be valid hex (6 or 8 digits with #)
        5. Make the color palette harmonious and visually stunning
        6. Choose a font that matches the style/mood
        7. Keep titles short, punchy, and marketing-focused
        """

      let response = try await session.respond(to: prompt)
      return response.content
    #else
      fatalError("Template generation is unavailable in this environment.")
    #endif
  }

  /// Runs Apple FM with structured output and a hard cancellation timeout.
  @available(iOS 26, *)
  private static func designAssistWithTimeout(
    prompt: String, seconds: Int
  ) async throws -> String {
    #if canImport(FoundationModels)
      // Pre-flight: make sure the model is actually available
      let model = SystemLanguageModel.default
      guard case .available = model.availability else {
        throw NSError(
          domain: "AIChannel", code: -2,
          userInfo: [NSLocalizedDescriptionKey: "Apple FM model is not available on this device."]
        )
      }

      NSLog("[AIChannel] designAssist: prompt.count=%d, timeout=%ds", prompt.count, seconds)
      let session = LanguageModelSession(
        instructions: "Only change what the user asks. Keep the explanation short."
      )
      NSLog("[AIChannel] designAssist: session ready, starting race…")

      // Race the AI call against a timeout
      return try await withThrowingTaskGroup(of: String.self) { group in
        group.addTask {
          let response = try await session.respond(
            to: prompt,
            generating: DesignAssistResponse.self
          )
          NSLog("[AIChannel] designAssist: structured response received, converting to JSON…")
          return try response.content.toChannelJSON()
        }
        group.addTask {
          try await Task.sleep(for: .seconds(seconds))
          throw NSError(
            domain: "AIChannel", code: -1,
            userInfo: [NSLocalizedDescriptionKey:
              "Apple FM timed out after \(seconds)s. The on-device model may be overloaded. Try a simpler request or switch to a cloud AI provider."]
          )
        }

        // Whichever finishes first wins; cancel the other
        let result = try await group.next()!
        group.cancelAll()
        return result
      }
    #else
      fatalError("Design assist is unavailable in this environment.")
    #endif
  }
}
