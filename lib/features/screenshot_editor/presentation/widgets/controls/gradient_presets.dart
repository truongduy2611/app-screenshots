import 'package:app_screenshots/features/screenshot_editor/data/models/mesh_gradient_settings.dart';
import 'package:flutter/material.dart';

/// Centralised collection of gradient presets used by [GradientEditor].
///
/// Keeping the pure-data constants in a dedicated file keeps the
/// widget files lean and focused on UI logic.
abstract final class GradientPresets {
  // ── Linear Gradient Presets ──────────────────────────────────────────────
  static const List<LinearGradient> linearPresets = [
    // ── Warm & Sunset ──
    LinearGradient(
      colors: [Color(0xFFFF9A9E), Color(0xFFFAD0C4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFFFECD2), Color(0xFFFCB69F)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    LinearGradient(
      colors: [Color(0xFFF6D365), Color(0xFFFDA085)],
      begin: Alignment(-0.5, -0.87),
      end: Alignment(0.5, 0.87),
    ),
    LinearGradient(
      colors: [Color(0xFFFA709A), Color(0xFFFEE140)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    LinearGradient(
      colors: [Color(0xFFF83600), Color(0xFFF9D423)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    LinearGradient(
      colors: [Color(0xFFFF5858), Color(0xFFF09819)],
      begin: Alignment(0.5, -0.87),
      end: Alignment(-0.5, 0.87),
    ),
    LinearGradient(
      colors: [Color(0xFFFC6076), Color(0xFFFF9A44)],
      begin: Alignment(0.34, -0.94),
      end: Alignment(-0.34, 0.94),
    ),
    LinearGradient(
      colors: [Color(0xFFF9D423), Color(0xFFFF4E50)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    // ── Pink & Rose ──
    LinearGradient(
      colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    LinearGradient(
      colors: [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    LinearGradient(
      colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
      begin: Alignment(-0.5, -0.87),
      end: Alignment(0.5, 0.87),
    ),
    LinearGradient(
      colors: [Color(0xFFFF0844), Color(0xFFFFB199)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    LinearGradient(
      colors: [Color(0xFFFF758C), Color(0xFFFF7EB3)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    LinearGradient(
      colors: [Color(0xFFF77062), Color(0xFFFE5196)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    LinearGradient(
      colors: [Color(0xFFF794A4), Color(0xFFFDD6BD)],
      begin: Alignment(0.34, -0.94),
      end: Alignment(-0.34, 0.94),
    ),
    LinearGradient(
      colors: [Color(0xFFED6EA0), Color(0xFFEC8C69)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    // ── Purple & Violet ──
    LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFC471F5), Color(0xFFFA71CD)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    LinearGradient(
      colors: [Color(0xFFB721FF), Color(0xFF21D4FD)],
      begin: Alignment(0.34, -0.94),
      end: Alignment(-0.34, 0.94),
    ),
    LinearGradient(
      colors: [Color(0xFF5F72BD), Color(0xFF9B23EA)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    LinearGradient(
      colors: [Color(0xFFCC208E), Color(0xFF6713D2)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    LinearGradient(
      colors: [Color(0xFFB224EF), Color(0xFF7579FF)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    LinearGradient(
      colors: [Color(0xFFAC32E4), Color(0xFF7918F2), Color(0xFF4801FF)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    LinearGradient(
      colors: [Color(0xFFA445B2), Color(0xFFD41872), Color(0xFFFF0066)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    // ── Blue & Sky ──
    LinearGradient(
      colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    LinearGradient(
      colors: [Color(0xFFA1C4FD), Color(0xFFC2E9FB)],
      begin: Alignment(-0.5, -0.87),
      end: Alignment(0.5, 0.87),
    ),
    LinearGradient(
      colors: [Color(0xFF89F7FE), Color(0xFF66A6FF)],
      begin: Alignment(-0.5, -0.87),
      end: Alignment(0.5, 0.87),
    ),
    LinearGradient(
      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    LinearGradient(
      colors: [Color(0xFF48C6EF), Color(0xFF6F86D6)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    LinearGradient(
      colors: [Color(0xFF00C6FB), Color(0xFF005BEA)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    LinearGradient(
      colors: [Color(0xFF0ACFFE), Color(0xFF495AFF)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    LinearGradient(
      colors: [Color(0xFF5D9FFF), Color(0xFFB8DCFF), Color(0xFF6BBBFF)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    // ── Aqua & Teal ──
    LinearGradient(
      colors: [Color(0xFF84FAB0), Color(0xFF8FD3F4)],
      begin: Alignment(-0.5, -0.87),
      end: Alignment(0.5, 0.87),
    ),
    LinearGradient(
      colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    LinearGradient(
      colors: [Color(0xFF13547A), Color(0xFF80D0C7)],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    ),
    LinearGradient(
      colors: [Color(0xFF92FE9D), Color(0xFF00C9FF)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    LinearGradient(
      colors: [Color(0xFF00CDAC), Color(0xFF8DDAD5)],
      begin: Alignment(0.34, -0.94),
      end: Alignment(-0.34, 0.94),
    ),
    LinearGradient(
      colors: [Color(0xFF209CFF), Color(0xFF68E0CF)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    LinearGradient(
      colors: [Color(0xFF30CFD0), Color(0xFF330867)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    // ── Green & Mint ──
    LinearGradient(
      colors: [Color(0xFFD4FC79), Color(0xFF96E6A1)],
      begin: Alignment(-0.5, -0.87),
      end: Alignment(0.5, 0.87),
    ),
    LinearGradient(
      colors: [Color(0xFF0BA360), Color(0xFF3CBA92)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    LinearGradient(
      colors: [Color(0xFF16A085), Color(0xFFF4D03F)],
      begin: Alignment(0.5, -0.87),
      end: Alignment(-0.5, 0.87),
    ),
    LinearGradient(
      colors: [Color(0xFF0FD850), Color(0xFFF9F047)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    LinearGradient(
      colors: [Color(0xFF9BE15D), Color(0xFF00E3AE)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    LinearGradient(
      colors: [Color(0xFF50CC7F), Color(0xFFF5D100)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    // ── Multi-color ──
    LinearGradient(
      colors: [
        Color(0xFF3D3393),
        Color(0xFF2B76B9),
        Color(0xFF2CACD1),
        Color(0xFF35EB93),
      ],
      begin: Alignment(-0.5, -0.87),
      end: Alignment(0.5, 0.87),
    ),
    LinearGradient(
      colors: [Color(0xFF2CD8D5), Color(0xFFC5C1FF), Color(0xFFFFBAC3)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    LinearGradient(
      colors: [Color(0xFF2CD8D5), Color(0xFF6B8DD6), Color(0xFF8E37D7)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    LinearGradient(
      colors: [Color(0xFFFFE29F), Color(0xFFFFA99F), Color(0xFFFF719A)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    LinearGradient(
      colors: [Color(0xFF69EACB), Color(0xFFEACCF8), Color(0xFF6654F1)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    LinearGradient(
      colors: [
        Color(0xFF231557),
        Color(0xFF44107A),
        Color(0xFFFF1361),
        Color(0xFFFFF800),
      ],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    LinearGradient(
      colors: [Color(0xFF3B41C5), Color(0xFFA981BB), Color(0xFFFFC8A9)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    LinearGradient(
      colors: [Color(0xFFFF3CAC), Color(0xFF562B7C), Color(0xFF2B86C5)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    // ── NEW: Aurora & Neon Multi-Stop ──
    LinearGradient(
      colors: [
        Color(0xFF00C9FF),
        Color(0xFF92FE9D),
        Color(0xFF6654F1),
        Color(0xFFFF3CAC),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFFF0099), Color(0xFF493240), Color(0xFF00D2FF)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    LinearGradient(
      colors: [
        Color(0xFF8E2DE2),
        Color(0xFF4A00E0),
        Color(0xFF00DBDE),
        Color(0xFFFC00FF),
      ],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    LinearGradient(
      colors: [
        Color(0xFF11998E),
        Color(0xFF38EF7D),
        Color(0xFFF9D423),
        Color(0xFFFF4E50),
      ],
      begin: Alignment(-0.5, -0.87),
      end: Alignment(0.5, 0.87),
    ),
    LinearGradient(
      colors: [
        Color(0xFFFDCB82),
        Color(0xFFD4F0FC),
        Color(0xFFA7D7F1),
        Color(0xFFC4A8FF),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // ── Light & Soft ──
    LinearGradient(
      colors: [Color(0xFFF5F7FA), Color(0xFFC3CFE2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFCFD9DF), Color(0xFFE2EBF0)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    LinearGradient(
      colors: [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    LinearGradient(
      colors: [Color(0xFFE3FDF5), Color(0xFFFFE6FA)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    // ── Dark & Moody ──
    LinearGradient(
      colors: [Color(0xFF434343), Color(0xFF000000)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    LinearGradient(
      colors: [Color(0xFF09203F), Color(0xFF537895)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    LinearGradient(
      colors: [Color(0xFF29323C), Color(0xFF485563)],
      begin: Alignment(-0.5, -0.87),
      end: Alignment(0.5, 0.87),
    ),
    LinearGradient(
      colors: [Color(0xFF473B7B), Color(0xFF3584A7), Color(0xFF30D2BE)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    // ── Apple-Inspired ──
    // macOS Sequoia — deep teal to warm amber
    LinearGradient(
      colors: [
        Color(0xFF0A3D62),
        Color(0xFF1B6B5A),
        Color(0xFFC49B3E),
        Color(0xFFE8B84A),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // macOS Sonoma — rolling golden hills
    LinearGradient(
      colors: [
        Color(0xFF5B86E5),
        Color(0xFFA0C4FF),
        Color(0xFFF5C842),
        Color(0xFFD4950A),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    // macOS Ventura — warm sunset to deep ocean
    LinearGradient(
      colors: [
        Color(0xFF1A0533),
        Color(0xFF4A1942),
        Color(0xFFBD3F32),
        Color(0xFFEF8C44),
      ],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    ),
    // macOS Monterey — vibrant flowing colors
    LinearGradient(
      colors: [
        Color(0xFF3C1053),
        Color(0xFFAD5389),
        Color(0xFFF09FFF),
        Color(0xFF5B2C8B),
      ],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    // iOS 18 — rich purple to teal
    LinearGradient(
      colors: [
        Color(0xFF2D1461),
        Color(0xFF5B3B99),
        Color(0xFF0EA5E9),
        Color(0xFF14B8A6),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // iOS 17 — warm sunset bloom
    LinearGradient(
      colors: [
        Color(0xFF8B1A4A),
        Color(0xFFF43F5E),
        Color(0xFFFF8C42),
        Color(0xFFFBBF24),
      ],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    // iPadOS — soft sky blue to violet
    LinearGradient(
      colors: [
        Color(0xFF1E3A5F),
        Color(0xFF4A90D9),
        Color(0xFF93C5FD),
        Color(0xFFC4B5FD),
      ],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    ),
    // Apple Dark — deep charcoal with blue undertone
    LinearGradient(
      colors: [
        Color(0xFF0A0A0F),
        Color(0xFF1A1A2E),
        Color(0xFF16213E),
        Color(0xFF0F3460),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ];

  // ── Radial Gradient Presets ─────────────────────────────────────────────
  static const List<RadialGradient> radialPresets = [
    // Spotlight
    RadialGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFF000000)],
      center: Alignment.center,
      radius: 0.8,
    ),
    // Warm Orb
    RadialGradient(
      colors: [Color(0xFFFF9A9E), Color(0xFF2D0015)],
      center: Alignment.center,
      radius: 0.7,
    ),
    // Cool Core
    RadialGradient(
      colors: [Color(0xFF00F2FE), Color(0xFF4FACFE), Color(0xFF0B0B3B)],
      center: Alignment.center,
      radius: 0.8,
    ),
    // Sun Burst
    RadialGradient(
      colors: [Color(0xFFFFF200), Color(0xFFFF6B35), Color(0xFF1A0000)],
      center: Alignment.center,
      radius: 0.9,
    ),
    // Vignette
    RadialGradient(
      colors: [Color(0xFFf5f5f5), Color(0xFF333333)],
      center: Alignment.center,
      radius: 1.2,
    ),
    // Purple Haze
    RadialGradient(
      colors: [Color(0xFFDA22FF), Color(0xFF9733EE), Color(0xFF1A0033)],
      center: Alignment(-0.3, -0.3),
      radius: 1.0,
    ),
    // Ocean Depth
    RadialGradient(
      colors: [Color(0xFF43E97B), Color(0xFF0077B6), Color(0xFF000033)],
      center: Alignment(0.2, 0.3),
      radius: 0.9,
    ),
    // Golden Ring
    RadialGradient(
      colors: [Color(0xFFFFD700), Color(0xFFFF8C00), Color(0xFF2A0000)],
      center: Alignment.center,
      radius: 0.6,
    ),
    // Neon Ball
    RadialGradient(
      colors: [Color(0xFF00FF87), Color(0xFF60EFFF), Color(0xFF0B0B45)],
      center: Alignment.center,
      radius: 0.7,
    ),
    // Soft Pink
    RadialGradient(
      colors: [Color(0xFFFFE6FA), Color(0xFFF093FB), Color(0xFF4A0033)],
      center: Alignment.center,
      radius: 0.9,
    ),
    // Deep Blue
    RadialGradient(
      colors: [Color(0xFF5D9FFF), Color(0xFF6A11CB), Color(0xFF000022)],
      center: Alignment(0.0, -0.2),
      radius: 0.8,
    ),
    // Ember
    RadialGradient(
      colors: [Color(0xFFFF4E50), Color(0xFFF9D423), Color(0xFF1A0000)],
      center: Alignment(0.0, 0.4),
      radius: 0.8,
    ),
    // ── Apple-Inspired ──
    // macOS Sonoma Light — warm golden sunburst
    RadialGradient(
      colors: [
        Color(0xFFF5D76E),
        Color(0xFFE8A838),
        Color(0xFF86622D),
        Color(0xFF2C1810),
      ],
      center: Alignment(0.0, 0.3),
      radius: 1.2,
    ),
    // macOS Sequoia — forest light ray
    RadialGradient(
      colors: [
        Color(0xFF40C4AA),
        Color(0xFF1B6B5A),
        Color(0xFF0A3D62),
        Color(0xFF051A2C),
      ],
      center: Alignment(-0.2, -0.1),
      radius: 1.0,
    ),
    // iOS Bloom — soft pink center bloom
    RadialGradient(
      colors: [
        Color(0xFFFFE4E8),
        Color(0xFFF9A8D4),
        Color(0xFFC084FC),
        Color(0xFF3B0764),
      ],
      center: Alignment(0.0, 0.0),
      radius: 1.1,
    ),
    // Apple Spotlight — dramatic stage light
    RadialGradient(
      colors: [
        Color(0xFF60A5FA),
        Color(0xFF1E40AF),
        Color(0xFF0F172A),
        Color(0xFF000000),
      ],
      center: Alignment(0.0, -0.3),
      radius: 0.9,
    ),
  ];

  // ── Sweep (Angular) Gradient Presets ──────────────────────────────────
  static const List<SweepGradient> sweepPresets = [
    // Color Wheel
    SweepGradient(
      colors: [
        Color(0xFFFF0000),
        Color(0xFFFFFF00),
        Color(0xFF00FF00),
        Color(0xFF00FFFF),
        Color(0xFF0000FF),
        Color(0xFFFF00FF),
        Color(0xFFFF0000),
      ],
      center: Alignment.center,
    ),
    // Sunset Sweep
    SweepGradient(
      colors: [
        Color(0xFFFF6B35),
        Color(0xFFF7931E),
        Color(0xFFFFCD38),
        Color(0xFFFF6B35),
      ],
      center: Alignment.center,
    ),
    // Cool Sweep
    SweepGradient(
      colors: [
        Color(0xFF667EEA),
        Color(0xFF00F2FE),
        Color(0xFF43E97B),
        Color(0xFF667EEA),
      ],
      center: Alignment.center,
    ),
    // Pink Spin
    SweepGradient(
      colors: [
        Color(0xFFFF6B95),
        Color(0xFFC44FE2),
        Color(0xFF7B61FF),
        Color(0xFFFF6B95),
      ],
      center: Alignment.center,
    ),
    // Monochrome
    SweepGradient(
      colors: [Color(0xFF000000), Color(0xFFFFFFFF), Color(0xFF000000)],
      center: Alignment.center,
    ),
    // Neon Spin
    SweepGradient(
      colors: [
        Color(0xFF00F5FF),
        Color(0xFFFF00FF),
        Color(0xFFFFFF00),
        Color(0xFF00F5FF),
      ],
      center: Alignment.center,
    ),
    // Earth Tones
    SweepGradient(
      colors: [
        Color(0xFF8B4513),
        Color(0xFFF4D03F),
        Color(0xFF0BA360),
        Color(0xFF8B4513),
      ],
      center: Alignment.center,
    ),
    // Pastel Sweep
    SweepGradient(
      colors: [
        Color(0xFFFBC2EB),
        Color(0xFFA8EDEA),
        Color(0xFFFED6E3),
        Color(0xFFFBC2EB),
      ],
      center: Alignment.center,
    ),
    // Metallic
    SweepGradient(
      colors: [Color(0xFFC0C0C0), Color(0xFFFFD700), Color(0xFFC0C0C0)],
      center: Alignment.center,
    ),
    // Ocean Sweep
    SweepGradient(
      colors: [
        Color(0xFF0077B6),
        Color(0xFF00B4D8),
        Color(0xFF90E0EF),
        Color(0xFF0077B6),
      ],
      center: Alignment.center,
    ),
  ];

  // ── Mesh Gradient Presets ───────────────────────────────────────────────
  static final List<MeshGradientSettings> meshPresets = [
    // ── Aurora Borealis — rich greens, teals, and violet shimmer ──
    MeshGradientSettings(
      blend: 3.5,
      noiseIntensity: 0.04,
      points: [
        MeshPoint(position: Offset(0.05, 0.05), color: Color(0xFF0D1B2A)),
        MeshPoint(position: Offset(0.55, 0.08), color: Color(0xFF1B998B)),
        MeshPoint(position: Offset(0.95, 0.15), color: Color(0xFF2EC4B6)),
        MeshPoint(position: Offset(0.30, 0.50), color: Color(0xFF7209B7)),
        MeshPoint(position: Offset(0.75, 0.55), color: Color(0xFF3A0CA3)),
        MeshPoint(position: Offset(0.10, 0.90), color: Color(0xFF0D1B2A)),
      ],
    ),
    // ── Sunset Horizon — warm oranges bleeding into deep purple sky ──
    MeshGradientSettings(
      blend: 3.0,
      points: [
        MeshPoint(position: Offset(0.10, 0.10), color: Color(0xFF2D1B69)),
        MeshPoint(position: Offset(0.85, 0.05), color: Color(0xFF7B2D8E)),
        MeshPoint(position: Offset(0.50, 0.40), color: Color(0xFFE44D26)),
        MeshPoint(position: Offset(0.15, 0.65), color: Color(0xFFF97316)),
        MeshPoint(position: Offset(0.80, 0.70), color: Color(0xFFFFBB5C)),
        MeshPoint(position: Offset(0.50, 0.95), color: Color(0xFFEF4444)),
      ],
    ),
    // ── Ocean Abyss — deep navy to luminous aquamarine ──
    MeshGradientSettings(
      blend: 4.0,
      noiseIntensity: 0.03,
      points: [
        MeshPoint(position: Offset(0.05, 0.10), color: Color(0xFF03045E)),
        MeshPoint(position: Offset(0.60, 0.05), color: Color(0xFF0077B6)),
        MeshPoint(position: Offset(0.90, 0.35), color: Color(0xFF00B4D8)),
        MeshPoint(position: Offset(0.35, 0.55), color: Color(0xFF023E8A)),
        MeshPoint(position: Offset(0.70, 0.75), color: Color(0xFF48CAE4)),
        MeshPoint(position: Offset(0.15, 0.92), color: Color(0xFF0A1628)),
      ],
    ),
    // ── Cotton Candy — soft pastel pinks, lavenders, and mint ──
    MeshGradientSettings(
      blend: 3.5,
      points: [
        MeshPoint(position: Offset(0.08, 0.12), color: Color(0xFFFFC8DD)),
        MeshPoint(position: Offset(0.55, 0.05), color: Color(0xFFBDE0FE)),
        MeshPoint(position: Offset(0.92, 0.20), color: Color(0xFFCDB4DB)),
        MeshPoint(position: Offset(0.25, 0.60), color: Color(0xFFA2D2FF)),
        MeshPoint(position: Offset(0.75, 0.65), color: Color(0xFFFFAFCC)),
        MeshPoint(position: Offset(0.45, 0.95), color: Color(0xFFC1FBA4)),
      ],
    ),
    // ── Cyberpunk — electric neon against dark backgrounds ──
    MeshGradientSettings(
      blend: 2.5,
      noiseIntensity: 0.06,
      points: [
        MeshPoint(position: Offset(0.10, 0.08), color: Color(0xFF0A0A0A)),
        MeshPoint(position: Offset(0.65, 0.10), color: Color(0xFFFF006E)),
        MeshPoint(position: Offset(0.90, 0.40), color: Color(0xFF0A0A0A)),
        MeshPoint(position: Offset(0.20, 0.55), color: Color(0xFF8338EC)),
        MeshPoint(position: Offset(0.75, 0.70), color: Color(0xFF00F5FF)),
        MeshPoint(position: Offset(0.40, 0.92), color: Color(0xFF0A0A0A)),
      ],
    ),
    // ── Emerald Forest — rich greens with golden light filtering through ──
    MeshGradientSettings(
      blend: 3.0,
      noiseIntensity: 0.05,
      points: [
        MeshPoint(position: Offset(0.12, 0.08), color: Color(0xFF0B3D2E)),
        MeshPoint(position: Offset(0.75, 0.12), color: Color(0xFF1A7D4E)),
        MeshPoint(position: Offset(0.40, 0.45), color: Color(0xFFA3B86C)),
        MeshPoint(position: Offset(0.85, 0.50), color: Color(0xFFF0C929)),
        MeshPoint(position: Offset(0.20, 0.80), color: Color(0xFF064E3B)),
        MeshPoint(position: Offset(0.65, 0.90), color: Color(0xFF059669)),
      ],
    ),
    // ── Cosmic Nebula — deep space purples with stellar highlights ──
    MeshGradientSettings(
      blend: 3.5,
      noiseIntensity: 0.08,
      points: [
        MeshPoint(position: Offset(0.10, 0.05), color: Color(0xFF0C0A2A)),
        MeshPoint(position: Offset(0.60, 0.12), color: Color(0xFF2E1065)),
        MeshPoint(position: Offset(0.85, 0.35), color: Color(0xFF7C3AED)),
        MeshPoint(position: Offset(0.30, 0.50), color: Color(0xFF1E1B4B)),
        MeshPoint(position: Offset(0.70, 0.65), color: Color(0xFFC084FC)),
        MeshPoint(position: Offset(0.15, 0.85), color: Color(0xFF9333EA)),
      ],
    ),
    // ── Coral Reef — warm corals, turquoise, and sand ──
    MeshGradientSettings(
      blend: 3.0,
      points: [
        MeshPoint(position: Offset(0.08, 0.15), color: Color(0xFFFF6B6B)),
        MeshPoint(position: Offset(0.70, 0.08), color: Color(0xFFFECA57)),
        MeshPoint(position: Offset(0.90, 0.45), color: Color(0xFF48DBFB)),
        MeshPoint(position: Offset(0.25, 0.55), color: Color(0xFFFF9FF3)),
        MeshPoint(position: Offset(0.55, 0.80), color: Color(0xFF0ABDE3)),
        MeshPoint(position: Offset(0.15, 0.90), color: Color(0xFFEE5A24)),
      ],
    ),
    // ── Midnight Blue — elegant dark blues with sapphire accents ──
    MeshGradientSettings(
      blend: 4.0,
      points: [
        MeshPoint(position: Offset(0.05, 0.05), color: Color(0xFF0F172A)),
        MeshPoint(position: Offset(0.65, 0.10), color: Color(0xFF1E3A5F)),
        MeshPoint(position: Offset(0.90, 0.40), color: Color(0xFF3B82F6)),
        MeshPoint(position: Offset(0.20, 0.60), color: Color(0xFF0F172A)),
        MeshPoint(position: Offset(0.75, 0.75), color: Color(0xFF1E40AF)),
        MeshPoint(position: Offset(0.40, 0.95), color: Color(0xFF1D4ED8)),
      ],
    ),
    // ── Peach Fuzz — warm peaches, terracotta, and cream ──
    MeshGradientSettings(
      blend: 3.0,
      points: [
        MeshPoint(position: Offset(0.10, 0.10), color: Color(0xFFFEDEB9)),
        MeshPoint(position: Offset(0.70, 0.08), color: Color(0xFFFFBE98)),
        MeshPoint(position: Offset(0.90, 0.50), color: Color(0xFFE07A5F)),
        MeshPoint(position: Offset(0.30, 0.45), color: Color(0xFFF2CC8F)),
        MeshPoint(position: Offset(0.55, 0.80), color: Color(0xFFCE796B)),
        MeshPoint(position: Offset(0.15, 0.85), color: Color(0xFFF4A261)),
      ],
    ),
    // ── Northern Lights — vivid greens and magentas on dark sky ──
    MeshGradientSettings(
      blend: 3.5,
      noiseIntensity: 0.05,
      points: [
        MeshPoint(position: Offset(0.05, 0.08), color: Color(0xFF0D1117)),
        MeshPoint(position: Offset(0.50, 0.10), color: Color(0xFF39D353)),
        MeshPoint(position: Offset(0.90, 0.25), color: Color(0xFF0D1117)),
        MeshPoint(position: Offset(0.25, 0.55), color: Color(0xFFE040FB)),
        MeshPoint(position: Offset(0.70, 0.60), color: Color(0xFF26A641)),
        MeshPoint(position: Offset(0.45, 0.92), color: Color(0xFF161B22)),
      ],
    ),
    // ── Holographic Foil — iridescent rainbow shimmer ──
    MeshGradientSettings(
      blend: 2.5,
      noiseIntensity: 0.07,
      points: [
        MeshPoint(position: Offset(0.08, 0.12), color: Color(0xFFE0C3FC)),
        MeshPoint(position: Offset(0.55, 0.05), color: Color(0xFF8EC5FC)),
        MeshPoint(position: Offset(0.92, 0.30), color: Color(0xFFFFD6E0)),
        MeshPoint(position: Offset(0.20, 0.60), color: Color(0xFF98EECC)),
        MeshPoint(position: Offset(0.75, 0.55), color: Color(0xFFD0BFFF)),
        MeshPoint(position: Offset(0.45, 0.90), color: Color(0xFFFFC6FF)),
      ],
    ),
    // ── Apple Wallpaper-Inspired ──
    // macOS Sequoia — deep forest with golden light breaking through canopy
    MeshGradientSettings(
      blend: 3.5,
      noiseIntensity: 0.03,
      points: [
        MeshPoint(position: Offset(0.05, 0.05), color: Color(0xFF051A2C)),
        MeshPoint(position: Offset(0.60, 0.08), color: Color(0xFF0A3D62)),
        MeshPoint(position: Offset(0.92, 0.25), color: Color(0xFF1B6B5A)),
        MeshPoint(position: Offset(0.35, 0.45), color: Color(0xFF40C4AA)),
        MeshPoint(position: Offset(0.80, 0.60), color: Color(0xFFC49B3E)),
        MeshPoint(position: Offset(0.25, 0.88), color: Color(0xFFE8B84A)),
      ],
    ),
    // macOS Sonoma — golden rolling hills and blue sky
    MeshGradientSettings(
      blend: 3.0,
      points: [
        MeshPoint(position: Offset(0.05, 0.05), color: Color(0xFF5B86E5)),
        MeshPoint(position: Offset(0.55, 0.10), color: Color(0xFFA0C4FF)),
        MeshPoint(position: Offset(0.92, 0.15), color: Color(0xFF87CEEB)),
        MeshPoint(position: Offset(0.15, 0.50), color: Color(0xFFF5C842)),
        MeshPoint(position: Offset(0.70, 0.55), color: Color(0xFFD4950A)),
        MeshPoint(position: Offset(0.45, 0.88), color: Color(0xFF86622D)),
      ],
    ),
    // macOS Ventura — sunset canyon with warm and cool tones
    MeshGradientSettings(
      blend: 3.0,
      noiseIntensity: 0.04,
      points: [
        MeshPoint(position: Offset(0.08, 0.08), color: Color(0xFF1A0533)),
        MeshPoint(position: Offset(0.55, 0.05), color: Color(0xFF4A1942)),
        MeshPoint(position: Offset(0.90, 0.20), color: Color(0xFFBD3F32)),
        MeshPoint(position: Offset(0.20, 0.50), color: Color(0xFF2D0A3B)),
        MeshPoint(position: Offset(0.75, 0.55), color: Color(0xFFEF8C44)),
        MeshPoint(position: Offset(0.35, 0.90), color: Color(0xFFD4622A)),
      ],
    ),
    // macOS Monterey — fluid purple-pink flowing colors
    MeshGradientSettings(
      blend: 3.5,
      points: [
        MeshPoint(position: Offset(0.10, 0.10), color: Color(0xFF3C1053)),
        MeshPoint(position: Offset(0.65, 0.05), color: Color(0xFFAD5389)),
        MeshPoint(position: Offset(0.90, 0.35), color: Color(0xFFF09FFF)),
        MeshPoint(position: Offset(0.25, 0.55), color: Color(0xFF5B2C8B)),
        MeshPoint(position: Offset(0.70, 0.65), color: Color(0xFFE879F9)),
        MeshPoint(position: Offset(0.35, 0.90), color: Color(0xFFD946EF)),
      ],
    ),
    // iOS 18 — deep purple to ocean teal
    MeshGradientSettings(
      blend: 3.0,
      noiseIntensity: 0.03,
      points: [
        MeshPoint(position: Offset(0.08, 0.05), color: Color(0xFF2D1461)),
        MeshPoint(position: Offset(0.55, 0.10), color: Color(0xFF5B3B99)),
        MeshPoint(position: Offset(0.92, 0.30), color: Color(0xFF0EA5E9)),
        MeshPoint(position: Offset(0.20, 0.55), color: Color(0xFF4C1D95)),
        MeshPoint(position: Offset(0.75, 0.60), color: Color(0xFF14B8A6)),
        MeshPoint(position: Offset(0.40, 0.90), color: Color(0xFF0369A1)),
      ],
    ),
    // iOS 17 — warm sunrise bloom
    MeshGradientSettings(
      blend: 3.0,
      points: [
        MeshPoint(position: Offset(0.10, 0.08), color: Color(0xFF8B1A4A)),
        MeshPoint(position: Offset(0.60, 0.05), color: Color(0xFFF43F5E)),
        MeshPoint(position: Offset(0.90, 0.30), color: Color(0xFFFF8C42)),
        MeshPoint(position: Offset(0.25, 0.50), color: Color(0xFFBE185D)),
        MeshPoint(position: Offset(0.75, 0.65), color: Color(0xFFFBBF24)),
        MeshPoint(position: Offset(0.45, 0.92), color: Color(0xFFE11D48)),
      ],
    ),
    // Apple Dark Mode — elegant charcoal with subtle blue
    MeshGradientSettings(
      blend: 4.0,
      points: [
        MeshPoint(position: Offset(0.05, 0.05), color: Color(0xFF0A0A0F)),
        MeshPoint(position: Offset(0.55, 0.10), color: Color(0xFF1A1A2E)),
        MeshPoint(position: Offset(0.92, 0.25), color: Color(0xFF16213E)),
        MeshPoint(position: Offset(0.20, 0.55), color: Color(0xFF0F3460)),
        MeshPoint(position: Offset(0.75, 0.60), color: Color(0xFF1A1A2E)),
        MeshPoint(position: Offset(0.40, 0.90), color: Color(0xFF0A0A0F)),
      ],
    ),
  ];
}
