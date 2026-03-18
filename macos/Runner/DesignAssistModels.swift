import Foundation

#if canImport(FoundationModels)
  import FoundationModels
#endif

// MARK: - Design Assist Response (Optimized per Apple TN3193)

/// Structured response for the design assistant.
///
/// Only fields the user asked to change are populated — optional
/// properties default to `nil`, meaning "no change".
///
/// Schema is kept minimal to conserve the 4,096-token context window.
/// See: https://developer.apple.com/documentation/technotes/tn3193
@available(macOS 26, iOS 26, *)
@Generable(description: "Design changes for a screenshot")
struct DesignAssistResponse {
  // Background
  var backgroundColor: String?

  @Guide(description: "Hex colors", .maximumCount(3))
  var gradientColors: [String]?

  var clearGradient: Bool?

  // Layout
  @Guide(.range(0...500))
  var padding: Int?

  @Guide(.range(0...200))
  var cornerRadius: Int?

  var textAtBottom: Bool?

  // Text edits
  @Guide(.maximumCount(3))
  var textChanges: [TextChange]?

  @Guide(.maximumCount(2))
  var addText: [NewText]?

  // Required
  var explanation: String
}

// MARK: - Text Changes

@available(macOS 26, iOS 26, *)
@Generable(description: "Edit text overlay")
struct TextChange {
  @Guide(description: "0=title, 1=subtitle")
  var index: Int

  var text: String?
  var color: String?

  @Guide(.range(10...300))
  var fontSize: Int?

  var fontWeight: Int?
  var googleFont: String?
  var textAlign: String?
}

@available(macOS 26, iOS 26, *)
@Generable(description: "New text overlay")
struct NewText {
  var text: String
  var color: String?

  @Guide(.range(10...300))
  var fontSize: Int?

  var fontWeight: Int?
  var googleFont: String?
  var textAlign: String?
}

// MARK: - JSON Encoding Helpers

@available(macOS 26, iOS 26, *)
extension DesignAssistResponse {
  /// Convert the structured response into the JSON format expected by the Dart side.
  ///
  /// The Dart `_parseResponse` method expects:
  /// ```json
  /// { "changes": { ... }, "textChanges": [...], "addText": [...], "explanation": "..." }
  /// ```
  func toChannelJSON() throws -> String {
    var result: [String: Any] = [:]

    // Build "changes" dict — only include non-nil values
    var changes: [String: Any] = [:]
    if let v = backgroundColor { changes["backgroundColor"] = v }
    if let v = gradientColors { changes["gradientColors"] = v }
    if let v = clearGradient { changes["clearGradient"] = v }
    if let v = padding { changes["padding"] = v }
    if let v = cornerRadius { changes["cornerRadius"] = v }
    if let v = textAtBottom { changes["textAtBottom"] = v }
    result["changes"] = changes

    // Text changes
    if let tc = textChanges {
      result["textChanges"] = tc.map { t -> [String: Any] in
        var dict: [String: Any] = ["index": t.index]
        if let v = t.text { dict["text"] = v }
        if let v = t.color { dict["color"] = v }
        if let v = t.fontSize { dict["fontSize"] = v }
        if let v = t.fontWeight { dict["fontWeight"] = v }
        if let v = t.googleFont { dict["googleFont"] = v }
        if let v = t.textAlign { dict["textAlign"] = v }
        return dict
      }
    }

    // Add text
    if let at = addText {
      result["addText"] = at.map { t -> [String: Any] in
        var dict: [String: Any] = ["text": t.text]
        if let v = t.color { dict["color"] = v }
        if let v = t.fontSize { dict["fontSize"] = v }
        if let v = t.fontWeight { dict["fontWeight"] = v }
        if let v = t.googleFont { dict["googleFont"] = v }
        if let v = t.textAlign { dict["textAlign"] = v }
        return dict
      }
    }

    result["explanation"] = explanation

    let data = try JSONSerialization.data(withJSONObject: result)
    return String(data: data, encoding: .utf8)!
  }
}
