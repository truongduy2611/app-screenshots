// TECH_DEBT: Color.value deprecated in Flutter 3.27 — used by device_frame package internals
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'models/screenshot_design.dart';
import 'models/screenshot_preset.dart';

/// Static catalog of all available screenshot presets.
class ScreenshotPresets {
  ScreenshotPresets._();

  static final List<ScreenshotPreset> all = [
    snapchatYellow,
    instagramDark,
    oceanBreeze,
    sunsetGlow,
    minimalWhite,
    neonNight,
    forestGreen,
    candyPop,
    chromeClean,
    lemon8Cream,
    threadsDark,
    xBold,
    storyArc,
    darkPremium,
    appStoreHero,
  ];

  // ===========================================================================
  // 1. Snapchat Yellow — Bold black titles on bright yellow
  // ===========================================================================
  static final snapchatYellow = _simple(
    id: 'snapchat_yellow',
    name: 'Snapchat Yellow',
    description: 'Bold titles on bright yellow',
    thumbnailColors: [Color(0xFFFFFC00), Color(0xFFFFF200)],
    titleFont: 'Poppins',
    bg: Color(0xFFFFFC00),
    titleSize: 120,
    titleWeight: FontWeight.w900,
    titleColor: Colors.black,
    subtitleSize: 48,
    subtitleColor: Color(0xDD000000),
    titles: [
      'FEATURE ONE',
      'FEATURE TWO',
      'FEATURE THREE',
      'FEATURE FOUR',
      'FEATURE FIVE',
    ],
    subtitles: [
      'Describe your first feature',
      'Describe your second feature',
      'Explore this amazing feature',
      'Discover something new',
      'One more great feature',
    ],
    iconBuilder: (i, id) => [
      IconOverlay(
        id: '${id}_${i}_icon',
        codePoint: 0x10031E, // SF camera
        fontFamily: 'sficons',
        fontPackage: 'flutter_sficon',
        color: Colors.black,
        size: 80,
        position: const Offset(80, 530),
      ),
    ],
  );

  // ===========================================================================
  // 2. Instagram Dark — White italic serif on black
  // ===========================================================================
  static final instagramDark = _simple(
    id: 'instagram_dark',
    name: 'Instagram Dark',
    description: 'Elegant italic text on dark background',
    thumbnailColors: [Color(0xFF000000), Color(0xFF1A1A2E)],
    titleFont: 'Playfair Display',
    bg: Color(0xFF000000),
    titleSize: 90,
    titleWeight: FontWeight.w700,
    titleFontStyle: FontStyle.italic,
    titleColor: Colors.white,
    subtitleSize: 0, // no subtitle
    titles: [
      'Engage with\nyour favorite\ncreators',
      'Share with\nthe people who\nget you',
      'Send messages,\nmemes,\nand more',
      'Post the\nlittle moments',
      'Stay close with\nyour friends',
    ],
    subtitles: ['', '', '', '', ''],
    titleAlign: TextAlign.center,
  );

  // ===========================================================================
  // 3. Ocean Breeze — White text on blue gradient
  // ===========================================================================
  static final oceanBreeze = _simple(
    id: 'ocean_breeze',
    name: 'Ocean Breeze',
    description: 'Cool blue gradient with clean text',
    thumbnailColors: [Color(0xFF0077B6), Color(0xFF00B4D8), Color(0xFF90E0EF)],
    titleFont: 'Outfit',
    bg: Color(0xFF0077B6),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0077B6), Color(0xFF00B4D8), Color(0xFF90E0EF)],
    ),
    titleSize: 100,
    titleWeight: FontWeight.w700,
    titleColor: Colors.white,
    subtitleSize: 46,
    subtitleColor: Color(0xB3FFFFFF),
    titles: [
      'Dive Into\nSomething New',
      'Seamless\nExperience',
      'Smart\nFeatures',
      'Stay\nConnected',
      'Your World\nYour Way',
    ],
    subtitles: [
      'Start your journey today',
      'Everything at your fingertips',
      'Powered by intelligence',
      'Always in sync',
      'Customize everything',
    ],
  );

  // ===========================================================================
  // 4. Sunset Glow — White text on warm orange-pink gradient
  // ===========================================================================
  static final sunsetGlow = _simple(
    id: 'sunset_glow',
    name: 'Sunset Glow',
    description: 'Warm orange to pink gradient',
    thumbnailColors: [Color(0xFFFF6B35), Color(0xFFF7931E), Color(0xFFFFCD38)],
    titleFont: 'Montserrat',
    bg: Color(0xFFFF6B35),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF6B35), Color(0xFFF7931E), Color(0xFFFFCD38)],
    ),
    titleSize: 105,
    titleWeight: FontWeight.w800,
    titleColor: Colors.white,
    subtitleSize: 44,
    subtitleColor: Color(0xCCFFFFFF),
    titles: [
      'Welcome to\nthe Future',
      'Capture\nEvery Moment',
      'Share Your\nStory',
      'Discover\nMore',
      'Join the\nCommunity',
    ],
    subtitles: [
      'A new way to explore',
      'Never miss a thing',
      'Your voice matters',
      'Endless possibilities',
      'Millions trust us',
    ],
  );

  // ===========================================================================
  // 5. Minimal White — Dark text on clean white
  // ===========================================================================
  static final minimalWhite = _simple(
    id: 'minimal_white',
    name: 'Minimal White',
    description: 'Clean and simple on white',
    thumbnailColors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
    titleFont: 'Inter',
    bg: Color(0xFFFFFFFF),
    titleSize: 90,
    titleWeight: FontWeight.w600,
    titleColor: Color(0xFF1A1A1A),
    subtitleSize: 44,
    subtitleColor: Color(0xFF757575),
    titles: [
      'Simple.\nPowerful.',
      'Designed for\nProductivity',
      'Fast and\nReliable',
      'Your Data,\nYour Rules',
      'Get Started\nToday',
    ],
    subtitles: [
      'Everything you need',
      'Work smarter, not harder',
      'Built for performance',
      'Privacy first',
      'It only takes a minute',
    ],
  );

  // ===========================================================================
  // 6. Neon Night — Cyan text on dark purple gradient (text at bottom)
  // ===========================================================================
  static final neonNight = _simple(
    id: 'neon_night',
    name: 'Neon Night',
    description: 'Glowing text on dark purple',
    thumbnailColors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
    titleFont: 'Space Grotesk',
    bg: Color(0xFF0F0C29),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
    ),
    titleSize: 100,
    titleWeight: FontWeight.w700,
    titleColor: Color(0xFF00F5FF),
    subtitleSize: 44,
    subtitleColor: Color(0xB3FFFFFF),
    textAtBottom: true,
    titles: [
      'NEXT GEN\nEXPERIENCE',
      'ULTRA FAST\nPERFORMANCE',
      'SMART\nAUTOMATION',
      'SEAMLESS\nINTEGRATION',
      'INFINITE\nPOSSIBILITIES',
    ],
    subtitles: [
      'The future is now',
      'Speed like never before',
      'Let AI do the work',
      'Everything connected',
      'No limits',
    ],
    iconBuilder: (i, id) => [
      IconOverlay(
        id: '${id}_${i}_icon',
        codePoint: 0x1002E5, // SF bolt
        fontFamily: 'sficons',
        fontPackage: 'flutter_sficon',
        color: const Color(0xFF00F5FF),
        size: 60,
        position: const Offset(80, 2530),
      ),
    ],
  );

  // ===========================================================================
  // 7. Forest Green — White italic text on green gradient
  // ===========================================================================
  static final forestGreen = _simple(
    id: 'forest_green',
    name: 'Forest Green',
    description: 'Nature-inspired green gradient',
    thumbnailColors: [Color(0xFF134E5E), Color(0xFF71B280)],
    titleFont: 'Lora',
    bg: Color(0xFF134E5E),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF134E5E), Color(0xFF71B280)],
    ),
    titleSize: 95,
    titleWeight: FontWeight.w700,
    titleFontStyle: FontStyle.italic,
    titleColor: Colors.white,
    subtitleSize: 44,
    subtitleColor: Color(0xB3FFFFFF),
    titles: [
      'Breathe Easy',
      'Stay Organized',
      'Grow Together',
      'Natural Flow',
      'Eco Friendly',
    ],
    subtitles: [
      'Nature-inspired design',
      'Keep your life in order',
      'Build your community',
      'Intuitive experience',
      'Good for the planet',
    ],
    titleAlign: TextAlign.center,
  );

  // ===========================================================================
  // 8. Candy Pop — White text on pink-to-purple gradient
  // ===========================================================================
  static final candyPop = _simple(
    id: 'candy_pop',
    name: 'Candy Pop',
    description: 'Fun pink-to-purple gradient',
    thumbnailColors: [Color(0xFFFF6B95), Color(0xFFC44FE2), Color(0xFF7B61FF)],
    titleFont: 'Quicksand',
    bg: Color(0xFFFF6B95),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF6B95), Color(0xFFC44FE2), Color(0xFF7B61FF)],
    ),
    titleSize: 100,
    titleWeight: FontWeight.w700,
    titleColor: Colors.white,
    subtitleSize: 46,
    subtitleColor: Color(0xCCFFFFFF),
    titles: [
      'Make It\nYours ✨',
      'Fun &\nPlayful 🎉',
      'Share the\nJoy 💖',
      'Create\nMagic 🌈',
      'Be Bold\nBe You 💫',
    ],
    subtitles: [
      'Customize everything',
      'Entertainment redefined',
      'Spread happiness',
      'Unleash creativity',
      'Express yourself',
    ],
  );

  // ===========================================================================
  // 9. Chrome Clean — White bg with colored keyword pill badges
  // ===========================================================================
  static final chromeClean = ScreenshotPreset(
    id: 'chrome_clean',
    name: 'Chrome Clean',
    description: 'White with colored keyword pills',
    thumbnailColors: [Color(0xFFFFFFFF), Color(0xFFE8F0FE)],
    titleFont: 'Inter',
    designs: _buildChromeDesigns(),
  );

  static List<ScreenshotDesign> _buildChromeDesigns() {
    const pillColors = [
      Color(0xFF4285F4), // blue
      Color(0xFF34A853), // green
      Color(0xFFEA4335), // red
      Color(0xFFFBBC05), // amber
      Color(0xFF9C27B0), // purple
    ];
    const pillWords = ['Browse', 'Search', 'Translate', 'Autofill', 'Manage'];
    const bodyTexts = [
      'fast with\nyour app',
      'what you see\nwith ease',
      'content\ninstantly',
      'passwords and\npayment info',
      'your tabs\nwith ease',
    ];

    return List.generate(5, (i) {
      return ScreenshotDesign(
        backgroundColor: Colors.white,
        padding: 200,
        imagePosition: const Offset(0, 350),
        overlays: [
          // Keyword pill
          TextOverlay(
            id: 'chrome_${i}_pill',
            text: pillWords[i],
            style: TextStyle(
              fontSize: 65,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            googleFont: 'Inter',
            position: const Offset(80, 100),
            backgroundColor: pillColors[i],
            borderRadius: 24,
            horizontalPadding: 24,
            verticalPadding: 12,
          ),
          // Body text
          TextOverlay(
            id: 'chrome_${i}_body',
            text: bodyTexts[i],
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
            googleFont: 'Inter',
            position: const Offset(80, 210),
            textAlign: TextAlign.left,
          ),
        ],
      );
    });
  }

  // ===========================================================================
  // 10. Lemon8 Cream — Dark text on warm light yellow
  // ===========================================================================
  static final lemon8Cream = _simple(
    id: 'lemon8_cream',
    name: 'Lemon8 Cream',
    description: 'Warm lifestyle on light yellow',
    thumbnailColors: [Color(0xFFFFF9E0), Color(0xFFFFF3B0)],
    titleFont: 'Poppins',
    bg: Color(0xFFFFF9E0),
    titleSize: 90,
    titleWeight: FontWeight.w600,
    titleColor: Color(0xFF1A1A1A),
    subtitleSize: 44,
    subtitleColor: Color(0x88000000),
    titles: [
      'Find inspiration',
      'Share your style',
      'Connect with others',
      'Get useful tips',
      'Create with ease',
    ],
    subtitles: [
      'Discover trends and ideas',
      'Express your creativity',
      'Build your community',
      'Learn something new',
      'Tools at your fingertips',
    ],
    titleAlign: TextAlign.center,
  );

  // ===========================================================================
  // 11. Threads Dark — White italic serif on black
  // ===========================================================================
  static final threadsDark = _simple(
    id: 'threads_dark',
    name: 'Threads Dark',
    description: 'Elegant italic serif on black',
    thumbnailColors: [Color(0xFF000000), Color(0xFF111111)],
    titleFont: 'Playfair Display',
    bg: Color(0xFF000000),
    titleSize: 95,
    titleWeight: FontWeight.w700,
    titleFontStyle: FontStyle.italic,
    titleColor: Colors.white,
    subtitleSize: 0,
    titles: [
      'Ask the\ncommunity',
      'Discover\nnew opinions',
      'See what\'s\ntrending',
      'Share your\nideas',
      'Follow the\nconversation',
    ],
    subtitles: ['', '', '', '', ''],
  );

  // ===========================================================================
  // 12. X Bold — White all-caps bold on black, left-aligned
  // ===========================================================================
  static final xBold = _simple(
    id: 'x_bold',
    name: 'X Bold',
    description: 'Bold dramatic all-caps on black',
    thumbnailColors: [Color(0xFF000000), Color(0xFF0A0A0A)],
    titleFont: 'Oswald',
    bg: Color(0xFF000000),
    titleSize: 130,
    titleWeight: FontWeight.w700,
    titleColor: Colors.white,
    subtitleSize: 0,
    titleAlign: TextAlign.center,
    titles: [
      'BE THE\nFIRST TO\nKNOW',
      'FIND YOUR\nCOMMUNITY',
      'WATCH\nLIVE',
      'GET\nFOLLOWERS',
      'JOIN THE\nCONVERSATION',
    ],
    subtitles: ['', '', '', '', ''],
  );

  // ===========================================================================
  // 13. Story Arc — mixed light/dark, varied layouts, narrative sequence
  // ===========================================================================
  static final storyArc = ScreenshotPreset(
    id: 'story_arc',
    name: 'Story Arc',
    description: 'Narrative sequence with varied layouts',
    thumbnailColors: [Color(0xFF6366F1), Color(0xFFEC4899)],
    titleFont: 'Outfit',
    designs: _buildStoryArcDesigns(),
  );

  static List<ScreenshotDesign> _buildStoryArcDesigns() {
    // Slide 1: hero-only — large centered text, no phone frame
    final hero = ScreenshotDesign(
      backgroundColor: Color(0xFF0F172A),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
      ),
      padding: 200,
      imagePosition: const Offset(0, 5000), // off-screen
      overlays: [
        TextOverlay(
          id: 'story_0_title',
          text: 'Your Story\nStarts Here',
          style: TextStyle(
            fontSize: 120,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          googleFont: 'Outfit',
          position: const Offset(0, 900),
          textAlign: TextAlign.center,
          width: 1290,
        ),
        TextOverlay(
          id: 'story_0_sub',
          text: 'The easiest way to get started',
          style: TextStyle(
            fontSize: 46,
            fontWeight: FontWeight.w400,
            color: Color(0xB3FFFFFF),
          ),
          googleFont: 'Outfit',
          position: const Offset(0, 1250),
          textAlign: TextAlign.center,
          width: 1290,
        ),
      ],
    );

    // Slide 2: centered phone, text above — light contrast
    final differentiator = ScreenshotDesign(
      backgroundColor: Color(0xFFF8FAFC),
      padding: 200,
      imagePosition: const Offset(0, 300),
      overlays: [
        TextOverlay(
          id: 'story_1_title',
          text: 'Built Different',
          style: TextStyle(
            fontSize: 105,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
          googleFont: 'Outfit',
          position: const Offset(80, 100),
        ),
        TextOverlay(
          id: 'story_1_sub',
          text: 'What sets us apart',
          style: TextStyle(
            fontSize: 46,
            fontWeight: FontWeight.w400,
            color: Color(0x88000000),
          ),
          googleFont: 'Outfit',
          position: const Offset(80, 280),
        ),
      ],
    );

    // Slide 3: left-offset phone, text right — back to dark
    final feature1 = ScreenshotDesign(
      backgroundColor: Color(0xFF1E1B4B),
      backgroundGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
      ),
      padding: 200,
      imagePosition: const Offset(-200, 300),
      frameRotation: -0.0524, // -3 degrees in radians
      overlays: [
        TextOverlay(
          id: 'story_2_title',
          text: 'Smart\nFeatures',
          style: TextStyle(
            fontSize: 100,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          googleFont: 'Outfit',
          position: const Offset(80, 100),
        ),
        TextOverlay(
          id: 'story_2_sub',
          text: 'Powered by intelligence',
          style: TextStyle(
            fontSize: 46,
            fontWeight: FontWeight.w400,
            color: Color(0xB3FFFFFF),
          ),
          googleFont: 'Outfit',
          position: const Offset(80, 400),
        ),
      ],
    );

    // Slide 4: text-bottom layout — phone top, text below
    final feature2 = ScreenshotDesign(
      backgroundColor: Color(0xFF0F172A),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
      ),
      padding: 200,
      imagePosition: const Offset(0, -300),
      overlays: [
        TextOverlay(
          id: 'story_3_title',
          text: 'Seamless\nExperience',
          style: TextStyle(
            fontSize: 100,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          googleFont: 'Outfit',
          position: const Offset(80, 2100),
        ),
        TextOverlay(
          id: 'story_3_sub',
          text: 'Everything just works',
          style: TextStyle(
            fontSize: 46,
            fontWeight: FontWeight.w400,
            color: Color(0xCCFFFFFF),
          ),
          googleFont: 'Outfit',
          position: const Offset(80, 2400),
        ),
      ],
    );

    // Slide 5: more-features pill slide
    final morePills = _moreFeaturesPill(
      id: 'story_4',
      bgColor: Color(0xFF0F172A),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
      ),
      headline: 'And so\nmuch more.',
      headlineColor: Colors.white,
      pillLabels: [
        'Dark Mode',
        'Widgets',
        'Cloud Sync',
        'Shortcuts',
        'Themes',
        'Export',
      ],
      pillColor: Colors.white,
      font: 'Outfit',
    );

    return [hero, differentiator, feature1, feature2, morePills];
  }

  // ===========================================================================
  // 14. Dark Premium — elegant dark with subtle purple accents
  // ===========================================================================
  static final darkPremium = ScreenshotPreset(
    id: 'dark_premium',
    name: 'Dark Premium',
    description: 'Elegant dark with purple accents',
    thumbnailColors: [Color(0xFF0A0A0F), Color(0xFF8B5CF6)],
    titleFont: 'Playfair Display',
    designs: _buildDarkPremiumDesigns(),
  );

  static List<ScreenshotDesign> _buildDarkPremiumDesigns() {
    const font = 'Playfair Display';
    const titleColor = Colors.white;
    const subtitleColor = Color(0xB3FFFFFF);

    // Slide 1: text-top, dark with subtle indigo undertone
    final slide1 = ScreenshotDesign(
      backgroundColor: Color(0xFF0A0A0F),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F0F1A), Color(0xFF0A0A0F)],
      ),
      padding: 200,
      imagePosition: const Offset(0, 300),
      overlays: [
        TextOverlay(
          id: 'dprem_0_title',
          text: 'Crafted with\nPrecision',
          style: TextStyle(
            fontSize: 100,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: titleColor,
          ),
          googleFont: font,
          position: const Offset(80, 100),
        ),
        TextOverlay(
          id: 'dprem_0_sub',
          text: 'Every detail matters',
          style: TextStyle(
            fontSize: 46,
            fontWeight: FontWeight.w400,
            color: subtitleColor,
          ),
          googleFont: font,
          position: const Offset(80, 420),
        ),
      ],
    );

    // Slide 2: text-bottom, dark with deeper purple hint
    final slide2 = ScreenshotDesign(
      backgroundColor: Color(0xFF0A0A0F),
      backgroundGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0A0A0F), Color(0xFF12101F)],
      ),
      padding: 200,
      imagePosition: const Offset(0, -300),
      overlays: [
        TextOverlay(
          id: 'dprem_1_title',
          text: 'Powerful\nSimplicity',
          style: TextStyle(
            fontSize: 100,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: titleColor,
          ),
          googleFont: font,
          position: const Offset(80, 2100),
        ),
      ],
    );

    // Slide 3: text-top, dark with soft purple gradient
    final slide3 = ScreenshotDesign(
      backgroundColor: Color(0xFF0D0B1A),
      backgroundGradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF0D0B1A), Color(0xFF1A1535)],
      ),
      padding: 200,
      imagePosition: const Offset(0, 300),
      overlays: [
        TextOverlay(
          id: 'dprem_2_title',
          text: 'Designed\nfor You',
          style: TextStyle(
            fontSize: 100,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: titleColor,
          ),
          googleFont: font,
          position: const Offset(80, 100),
        ),
        TextOverlay(
          id: 'dprem_2_sub',
          text: 'Personal. Intuitive. Beautiful.',
          style: TextStyle(
            fontSize: 46,
            fontWeight: FontWeight.w400,
            color: subtitleColor,
          ),
          googleFont: font,
          position: const Offset(80, 420),
        ),
      ],
    );

    // Slide 4: text-top, slightly offset phone, purple accent
    final slide4 = ScreenshotDesign(
      backgroundColor: Color(0xFF100E1F),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF100E1F), Color(0xFF1E1640)],
      ),
      padding: 200,
      imagePosition: const Offset(100, 300),
      frameRotation: 0.0524, // 3 degrees in radians
      overlays: [
        TextOverlay(
          id: 'dprem_3_title',
          text: 'Effortless\nControl',
          style: TextStyle(
            fontSize: 100,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: titleColor,
          ),
          googleFont: font,
          position: const Offset(80, 100),
        ),
      ],
    );

    // Slide 5: pill slide, dark
    final slide5 = _moreFeaturesPill(
      id: 'dprem_4',
      bgColor: Color(0xFF0A0A0F),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0A0A0F), Color(0xFF12101F)],
      ),
      headline: 'And so\nmuch more.',
      headlineColor: titleColor,
      pillLabels: [
        'Themes',
        'Sync',
        'Analytics',
        'Sharing',
        'Offline',
        'Widgets',
      ],
      pillColor: titleColor,
      font: font,
    );

    return [slide1, slide2, slide3, slide4, slide5];
  }

  // ===========================================================================
  // 15. App Store Hero — bold hero-first with varied phone positions
  // ===========================================================================
  static final appStoreHero = ScreenshotPreset(
    id: 'app_store_hero',
    name: 'App Store Hero',
    description: 'Bold hero slide with varied layouts',
    thumbnailColors: [Color(0xFF059669), Color(0xFF10B981)],
    titleFont: 'Montserrat',
    designs: _buildAppStoreHeroDesigns(),
  );

  static List<ScreenshotDesign> _buildAppStoreHeroDesigns() {
    const font = 'Montserrat';

    // Slide 1: hero-only — bold, large text, no phone
    final slide1 = ScreenshotDesign(
      backgroundColor: Color(0xFF059669),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
      ),
      padding: 200,
      imagePosition: const Offset(0, 5000),
      overlays: [
        TextOverlay(
          id: 'hero_0_title',
          text: 'THE APP\nYOU NEED',
          style: TextStyle(
            fontSize: 130,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
          googleFont: font,
          position: const Offset(0, 850),
          textAlign: TextAlign.center,
          width: 1290,
        ),
        TextOverlay(
          id: 'hero_0_sub',
          text: 'Simple. Powerful. Yours.',
          style: TextStyle(
            fontSize: 50,
            fontWeight: FontWeight.w400,
            color: Color(0xDDFFFFFF),
          ),
          googleFont: font,
          position: const Offset(0, 1250),
          textAlign: TextAlign.center,
          width: 1290,
        ),
      ],
    );

    // Slide 2: centered, same green base
    final slide2 = ScreenshotDesign(
      backgroundColor: Color(0xFF059669),
      backgroundGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF047857), Color(0xFF059669)],
      ),
      padding: 200,
      imagePosition: const Offset(0, 300),
      overlays: [
        TextOverlay(
          id: 'hero_1_title',
          text: 'Lightning\nFast',
          style: TextStyle(
            fontSize: 110,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          googleFont: font,
          position: const Offset(80, 100),
        ),
      ],
    );

    // Slide 3: CONTRAST — light slide, left-offset
    final slide3 = ScreenshotDesign(
      backgroundColor: Color(0xFFF0FDF4),
      padding: 200,
      imagePosition: const Offset(-200, 300),
      frameRotation: -0.0524, // -3 degrees in radians
      overlays: [
        TextOverlay(
          id: 'hero_2_title',
          text: 'Smart\nDesign',
          style: TextStyle(
            fontSize: 105,
            fontWeight: FontWeight.w800,
            color: Color(0xFF064E3B),
          ),
          googleFont: font,
          position: const Offset(80, 100),
        ),
        TextOverlay(
          id: 'hero_2_sub',
          text: 'Built for humans',
          style: TextStyle(
            fontSize: 46,
            fontWeight: FontWeight.w400,
            color: Color(0x88064E3B),
          ),
          googleFont: font,
          position: const Offset(80, 380),
        ),
      ],
    );

    // Slide 4: text-bottom, dark green
    final slide4 = ScreenshotDesign(
      backgroundColor: Color(0xFF064E3B),
      backgroundGradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF064E3B), Color(0xFF047857)],
      ),
      padding: 200,
      imagePosition: const Offset(0, -300),
      overlays: [
        TextOverlay(
          id: 'hero_3_title',
          text: 'Always\nIn Sync',
          style: TextStyle(
            fontSize: 105,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          googleFont: font,
          position: const Offset(80, 2100),
        ),
      ],
    );

    // Slide 5: pill slide
    final slide5 = _moreFeaturesPill(
      id: 'hero_4',
      bgColor: Color(0xFF022C22),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF022C22), Color(0xFF064E3B)],
      ),
      headline: 'And so\nmuch more.',
      headlineColor: Color(0xFF34D399),
      pillLabels: [
        'Reminders',
        'Charts',
        'Export',
        'Dark Mode',
        'Widgets',
        'Sharing',
      ],
      pillColor: Color(0xFF34D399),
      font: font,
    );

    return [slide1, slide2, slide3, slide4, slide5];
  }

  // ===========================================================================
  // Helper — builds a standard 5-design preset with contrast slide
  // ===========================================================================
  static ScreenshotPreset _simple({
    required String id,
    required String name,
    required String description,
    required List<Color> thumbnailColors,
    required String titleFont,
    required Color bg,
    Gradient? gradient,
    double padding = 200,
    bool textAtBottom = false,
    required double titleSize,
    FontWeight titleWeight = FontWeight.w700,
    FontStyle titleFontStyle = FontStyle.normal,
    Color titleColor = Colors.white,
    required double subtitleSize,
    Color subtitleColor = Colors.white70,
    Offset? titlePosition,
    TextAlign titleAlign = TextAlign.left,
    TextAlign? subtitleAlign,
    required List<String> titles,
    required List<String> subtitles,
    List<IconOverlay> Function(int index, String id)? iconBuilder,
    int contrastSlideIndex = -1,
  }) {
    final isCenter = titleAlign == TextAlign.center;
    // For centered text, position at x=0 and use full canvas width to center.
    // For left-aligned text, use x=80 margin with no width constraint.
    final double textX = isCenter ? 0 : 80;
    final double? textWidth = isCenter ? 1290 : null;

    final tPos =
        titlePosition ??
        (textAtBottom ? Offset(textX, 2100) : Offset(textX, 100));
    final sPos = textAtBottom ? Offset(textX, 2400) : Offset(textX, 420);
    final imgPos = textAtBottom ? const Offset(0, -300) : const Offset(0, 300);

    // Derive contrast colors based on background luminance.
    final bool isDark = bg.computeLuminance() < 0.4;
    final contrastBg = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF0F0F0F);
    final contrastTitleColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final contrastSubtitleColor = isDark
        ? const Color(0xFF757575)
        : const Color(0xB3FFFFFF);

    return ScreenshotPreset(
      id: id,
      name: name,
      description: description,
      thumbnailColors: thumbnailColors,
      titleFont: titleFont,
      designs: List.generate(5, (i) {
        final isContrast = i == contrastSlideIndex;

        final effectiveBg = isContrast ? contrastBg : bg;
        final effectiveTitleColor = isContrast ? contrastTitleColor : titleColor;
        final effectiveSubtitleColor =
            isContrast ? contrastSubtitleColor : subtitleColor;
        // Drop gradient on contrast slide for a clean inversion.
        final effectiveGradient = isContrast ? null : gradient;

        final overlays = <TextOverlay>[
          TextOverlay(
            id: '${id}_${i}_title',
            text: titles[i],
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: titleWeight,
              fontStyle: titleFontStyle,
              color: effectiveTitleColor,
            ),
            googleFont: titleFont,
            position: tPos,
            textAlign: titleAlign,
            width: textWidth,
          ),
          if (subtitleSize > 0 && subtitles[i].isNotEmpty)
            TextOverlay(
              id: '${id}_${i}_sub',
              text: subtitles[i],
              style: TextStyle(
                fontSize: subtitleSize,
                fontWeight: FontWeight.w400,
                color: effectiveSubtitleColor,
              ),
              googleFont: titleFont,
              position: sPos,
              textAlign: subtitleAlign ?? titleAlign,
              width: textWidth,
            ),
        ];

        return ScreenshotDesign(
          backgroundColor: effectiveBg,
          backgroundGradient: effectiveGradient,
          padding: padding,
          imagePosition: imgPos,
          overlays: overlays,
          iconOverlays: iconBuilder?.call(i, id) ?? const [],
        );
      }),
    );
  }

  // ===========================================================================
  // Helper — builds a "More Features" pill slide
  // ===========================================================================
  static ScreenshotDesign _moreFeaturesPill({
    required String id,
    required Color bgColor,
    Gradient? gradient,
    required String headline,
    required Color headlineColor,
    required List<String> pillLabels,
    required Color pillColor,
    required String font,
  }) {
    final overlays = <TextOverlay>[
      TextOverlay(
        id: '${id}_headline',
        text: headline,
        style: TextStyle(
          fontSize: 110,
          fontWeight: FontWeight.w700,
          color: headlineColor,
        ),
        googleFont: font,
        position: const Offset(0, 700),
        textAlign: TextAlign.center,
        width: 1290,
      ),
    ];

    const pillFontSize = 42.0;
    const pillY0 = 1200.0;
    const pillSpacingY = 110.0;
    const pillSpacingX = 420.0;
    final pillBgColor = pillColor.withValues(alpha: 0.12);

    for (var p = 0; p < pillLabels.length; p++) {
      final row = p ~/ 2;
      final col = p % 2;
      final px = 120.0 + col * pillSpacingX;
      final py = pillY0 + row * pillSpacingY;
      overlays.add(
        TextOverlay(
          id: '${id}_pill_$p',
          text: pillLabels[p],
          style: TextStyle(
            fontSize: pillFontSize,
            fontWeight: FontWeight.w600,
            color: pillColor,
          ),
          googleFont: font,
          position: Offset(px, py),
          backgroundColor: pillBgColor,
          borderRadius: 22,
          horizontalPadding: 22,
          verticalPadding: 12,
        ),
      );
    }

    return ScreenshotDesign(
      backgroundColor: bgColor,
      backgroundGradient: gradient,
      padding: 200,
      imagePosition: const Offset(0, 5000), // no phone
      overlays: overlays,
    );
  }
}
