import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prefer color-emoji fonts so single-codepoint emoji (e.g. soccer ball U+26BD) render correctly.
TextStyle emojiGlyphStyle(double fontSize, {double height = 1.0}) {
  final String? emojiFont = switch (defaultTargetPlatform) {
    TargetPlatform.windows => 'Segoe UI Emoji',
    TargetPlatform.iOS || TargetPlatform.macOS => 'Apple Color Emoji',
    _ => null,
  };
  return TextStyle(
    fontSize: fontSize,
    height: height,
    fontFamily: emojiFont,
    fontFamilyFallback: const [
      'Noto Color Emoji',
      'Segoe UI Emoji',
      'Apple Color Emoji',
      'Segoe UI Symbol',
    ],
  );
}

void main() {
  // Lets plugins (e.g. shared_preferences) safely use platform channels before the first frame.
  // Avoids "flutter/lifecycle channel was discarded" when listeners are not registered yet.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LeftRightApp());
}

class LeftRightApp extends StatefulWidget {
  const LeftRightApp({super.key});

  @override
  State<LeftRightApp> createState() => _LeftRightAppState();
}

class _LeftRightAppState extends State<LeftRightApp> {
  int _themeIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final stats = await SessionStats.load();
    if (!mounted) return;
    setState(() {
      _themeIndex =
          min(max(0, stats.selectedThemeIndex), max(0, stats.unlockedThemes - 1));
    });
  }

  void _onThemeChanged(int index) {
    if (!mounted) return;
    setState(() {
      _themeIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.all[_themeIndex.clamp(0, AppThemes.all.length - 1)];
    final isDarkish = theme.background.first.computeLuminance() < 0.2;
    return MaterialApp(
      title: 'LeftRight Rush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: theme.seedColor,
          brightness: isDarkish ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(onThemeChanged: _onThemeChanged),
    );
  }
}

class AppTheme {
  const AppTheme({
    required this.name,
    required this.icon,
    required this.seedColor,
    required this.background,
    required this.effect,
  });

  final String name;
  final IconData icon;
  final Color seedColor;
  final List<Color> background;
  final ThemeVisualEffect effect;
}

enum ThemeVisualEffect {
  none,
  neonPulse,
  starfield,
  jungleDrift,
  candyBubbles,
  oceanWave,
  sunsetOrbs,
  galaxySpiral,
  snowfall,
}

class AppThemes {
  /// Unlock strip order (left → right). **Jungle** then **Candy**, then Space / Galaxy Pink.
  static const List<AppTheme> all = [
    AppTheme(
      name: 'Default',
      icon: Icons.palette_rounded,
      seedColor: Color(0xFF9CA3AF),
      background: [Color(0xFFE4E4E7), Color(0xFFF4F4F5)],
      effect: ThemeVisualEffect.none,
    ),
    AppTheme(
      name: 'Ice',
      icon: Icons.cloudy_snowing,
      seedColor: Color(0xFF0EA5E9),
      background: [Color(0xFFEFF6FF), Color(0xFFE0F2FE)],
      effect: ThemeVisualEffect.snowfall,
    ),
    AppTheme(
      name: 'Sunset',
      icon: Icons.wb_twilight_rounded,
      seedColor: Color(0xFFF97316),
      background: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
      effect: ThemeVisualEffect.sunsetOrbs,
    ),
    AppTheme(
      name: 'Ocean',
      icon: Icons.water_rounded,
      seedColor: Color(0xFF06B6D4),
      background: [Color(0xFFE0F2FE), Color(0xFFECFEFF)],
      effect: ThemeVisualEffect.oceanWave,
    ),
    AppTheme(
      name: 'Neon Pop',
      icon: Icons.electric_bolt_rounded,
      seedColor: Color(0xFF3B82F6),
      background: [Color(0xFFEEF2FF), Color(0xFFFFF1F2)],
      effect: ThemeVisualEffect.neonPulse,
    ),
    AppTheme(
      name: 'Jungle',
      icon: Icons.park_rounded,
      seedColor: Color(0xFF16A34A),
      background: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
      effect: ThemeVisualEffect.jungleDrift,
    ),
    AppTheme(
      name: 'Candy',
      icon: Icons.cake_rounded,
      seedColor: Color(0xFFEC4899),
      background: [Color(0xFFFFF1F2), Color(0xFFFFF7ED)],
      effect: ThemeVisualEffect.candyBubbles,
    ),
    AppTheme(
      name: 'Space',
      icon: Icons.rocket_launch_rounded,
      seedColor: Color(0xFF7C3AED),
      background: [Color(0xFF0B102A), Color(0xFF1B2A6B)],
      effect: ThemeVisualEffect.starfield,
    ),
    AppTheme(
      name: 'Galaxy Pink',
      icon: Icons.auto_awesome_rounded,
      seedColor: Color(0xFFDB2777),
      background: [Color(0xFF1F1147), Color(0xFF3A0A3A)],
      effect: ThemeVisualEffect.galaxySpiral,
    ),
  ];
}

/// Home screen surfaces tinted from the active theme so **light** themes (Neon, Jungle, …)
/// feel as “full-page” as dark themes (Space, Galaxy) instead of generic white cards.
/// [Default] uses the same neutral styling as the old “plain” home.
class HomeThemePalette {
  HomeThemePalette(this.theme);

  final AppTheme? theme;

  bool get isPlain => theme == null || theme!.name == 'Default';

  bool get isDark =>
      theme != null && theme!.background.first.computeLuminance() < 0.22;

  /// Play / Themes / Progress outer sections — translucent so theme gradient + floaties show through.
  Color get sectionSheet {
    if (isPlain) return Colors.white.withValues(alpha: 0.40);
    if (isDark) return Colors.white.withValues(alpha: 0.12);
    return Color.alphaBlend(
      theme!.seedColor.withValues(alpha: 0.16),
      Colors.white.withValues(alpha: 0.38),
    );
  }

  /// Nested rows (mode cards inside Play)
  Color get nestedSheet {
    if (isPlain) return Colors.white.withValues(alpha: 0.32);
    if (isDark) return Colors.white.withValues(alpha: 0.08);
    return Color.alphaBlend(
      theme!.seedColor.withValues(alpha: 0.12),
      Colors.white.withValues(alpha: 0.30),
    );
  }

  /// Frosted panel edge, consistent across light/dark themes.
  BorderSide get panelBorder => BorderSide(
        color: isPlain
            ? Colors.black.withValues(alpha: 0.14)
            : isDark
                ? Colors.white.withValues(alpha: 0.32)
                : Color.alphaBlend(
                    seedOrNeutral.withValues(alpha: 0.42),
                    Colors.black.withValues(alpha: 0.10),
                  ),
        width: 1.25,
      );

  Color get titleColor {
    if (isPlain) return Colors.black87;
    return isDark ? Colors.white : Color.lerp(Colors.black87, theme!.seedColor, 0.38)!;
  }

  Color get bodyColor => titleColor.withValues(alpha: isDark ? 0.82 : 0.90);

  Color get mutedColor => titleColor.withValues(alpha: isDark ? 0.68 : 0.74);

  Color get headerIconBg {
    if (isPlain) return Colors.white.withValues(alpha: 0.52);
    if (isDark) return Colors.white.withValues(alpha: 0.14);
    return Color.alphaBlend(
      theme!.seedColor.withValues(alpha: 0.22),
      Colors.white.withValues(alpha: 0.34),
    );
  }

  Color get seedOrNeutral => theme?.seedColor ?? const Color(0xFF9CA3AF);
}

enum SideChoice { left, right }
enum GameMode { objectSprint, arrowRush }

/// Object Side Sprint item: [id], [emoji], optional [icon], optional [emojiAsset] (full-color PNG, e.g. Twemoji).
typedef ObjectItem = (String id, String emoji, IconData? icon, String? emojiAsset);

class ObjectRound {
  ObjectRound({
    required this.leftItem,
    required this.rightItem,
    required this.answerOptions,
    required this.askSide,
  });

  final ObjectItem leftItem;
  final ObjectItem rightItem;
  final List<ObjectItem> answerOptions;
  final SideChoice askSide;
}

class GameResult {
  GameResult({
    required this.mode,
    required this.totalScore,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.averageReactionMs,
    required this.bestStreak,
    required this.maxDifficulty,
    required this.starsEarned,
  });

  final GameMode mode;
  final int totalScore;
  final int correctAnswers;
  final int wrongAnswers;
  final int averageReactionMs;
  final int bestStreak;
  final int maxDifficulty;
  final int starsEarned;

  int get totalAnswers => correctAnswers + wrongAnswers;

  double get accuracy =>
      totalAnswers == 0 ? 0 : (correctAnswers / totalAnswers) * 100;
}

class SessionStats {
  SessionStats({
    this.bestScore = 0,
    this.bestAccuracy = 0,
    this.bestStreak = 0,
    this.fastestAverageReactionMs = 0,
    this.gamesPlayed = 0,
    this.totalStars = 0,
    this.unlockedThemes = 1,
    this.selectedThemeIndex = 0,
  });

  static const int starsPerThemeUnlock = 10;

  /// First theme ([Default]) is free; each further theme costs [starsPerThemeUnlock] stars.
  static int unlockedSlotsForStars(int totalStars) =>
      min(AppThemes.all.length, 1 + (totalStars ~/ starsPerThemeUnlock));

  /// Debug-only: all themes unlocked, enough ★, progress stats cleared.
  factory SessionStats.devExplorationBaseline() {
    return SessionStats(
      bestScore: 0,
      bestAccuracy: 0,
      bestStreak: 0,
      fastestAverageReactionMs: 0,
      gamesPlayed: 0,
      totalStars: (AppThemes.all.length - 1) * starsPerThemeUnlock,
      unlockedThemes: AppThemes.all.length,
      selectedThemeIndex: 0,
    );
  }

  final int bestScore;
  final double bestAccuracy;
  final int bestStreak;
  final int fastestAverageReactionMs;
  final int gamesPlayed;
  final int totalStars;
  final int unlockedThemes;
  final int selectedThemeIndex;

  static const _bestScoreKey = 'best_score';
  static const _bestAccuracyKey = 'best_accuracy';
  static const _bestStreakKey = 'best_streak';
  static const _fastestAvgKey = 'fastest_avg_reaction';
  static const _gamesPlayedKey = 'games_played';
  static const _totalStarsKey = 'total_stars';
  static const _unlockedThemesKey = 'unlocked_themes';
  static const _selectedThemeKey = 'selected_theme';
  static const _statsV2Key = 'stats_v2_default_theme';
  static const _themeOrderV3Key = 'theme_order_v3_galaxy_last';
  static const _themeOrderV4Key = 'theme_order_v4_ice_sunset_strip';
  static const _themeOrderV5Key = 'theme_order_v5_jungle_before_candy';

  /// Indices before [AppThemes] put Space & Galaxy Pink at the end (for prefs migration).
  static const List<String> _themeNamesBeforeOrderV3 = [
    'Default',
    'Neon Pop',
    'Space',
    'Jungle',
    'Candy',
    'Ocean',
    'Sunset',
    'Galaxy Pink',
    'Ice',
  ];

  /// Order immediately before v4 (Ice after Default, Jungle before Space/Galaxy).
  static const List<String> _themeNamesBeforeOrderV4 = [
    'Default',
    'Neon Pop',
    'Jungle',
    'Candy',
    'Ocean',
    'Sunset',
    'Ice',
    'Space',
    'Galaxy Pink',
  ];

  /// Order before Jungle / Candy swap (Candy was immediately before Jungle).
  static const List<String> _themeNamesBeforeOrderV5 = [
    'Default',
    'Ice',
    'Sunset',
    'Ocean',
    'Neon Pop',
    'Candy',
    'Jungle',
    'Space',
    'Galaxy Pink',
  ];

  static const _devActiveKey = 'dev_mode_active';
  static const _devBakBest = 'dev_bak_best_score';
  static const _devBakAcc = 'dev_bak_best_accuracy';
  static const _devBakStreak = 'dev_bak_best_streak';
  static const _devBakFast = 'dev_bak_fastest_avg';
  static const _devBakGames = 'dev_bak_games_played';
  static const _devBakStars = 'dev_bak_total_stars';
  static const _devBakUnlocked = 'dev_bak_unlocked_themes';
  static const _devBakSel = 'dev_bak_selected_theme';

  static Future<void> _migrateV2IfNeeded(SharedPreferences prefs) async {
    if (prefs.getBool(_statsV2Key) ?? false) return;

    final hasData = prefs.containsKey(_unlockedThemesKey) ||
        prefs.containsKey(_gamesPlayedKey) ||
        (prefs.getInt(_totalStarsKey) ?? 0) > 0;

    if (hasData) {
      final oldU = prefs.getInt(_unlockedThemesKey) ?? 0;
      final oldS = prefs.getInt(_selectedThemeKey) ?? -1;
      final nu = oldU <= 0 && oldS < 0
          ? 1
          : min(AppThemes.all.length, max(1, oldU + 1));
      final nsel = oldS < 0 ? 0 : min(oldS + 1, nu - 1);
      await prefs.setInt(_unlockedThemesKey, nu);
      await prefs.setInt(_selectedThemeKey, nsel);
    }
    await prefs.setBool(_statsV2Key, true);
  }

  static Future<void> _migrateThemeOrderV3IfNeeded(SharedPreferences prefs) async {
    if (prefs.getBool(_themeOrderV3Key) ?? false) return;

    int newIndexForName(String name) {
      final i = AppThemes.all.indexWhere((t) => t.name == name);
      return i >= 0 ? i : 0;
    }

    String nameForOldIndex(int oldIdx) {
      if (oldIdx < 0 || oldIdx >= _themeNamesBeforeOrderV3.length) {
        return AppThemes.all.first.name;
      }
      return _themeNamesBeforeOrderV3[oldIdx];
    }

    int remapOldIndex(int oldIdx) => newIndexForName(nameForOldIndex(oldIdx));

    if (prefs.containsKey(_selectedThemeKey)) {
      final oldS = prefs.getInt(_selectedThemeKey) ?? 0;
      await prefs.setInt(_selectedThemeKey, remapOldIndex(oldS));
    }

    final oldU = prefs.getInt(_unlockedThemesKey) ?? 1;
    var newU = 1;
    for (var oldIdx = 0;
        oldIdx < oldU && oldIdx < _themeNamesBeforeOrderV3.length;
        oldIdx++) {
      newU = max(newU, remapOldIndex(oldIdx) + 1);
    }
    await prefs.setInt(_unlockedThemesKey, min(newU, AppThemes.all.length));

    if (prefs.containsKey(_devBakSel)) {
      await prefs.setInt(_devBakSel, remapOldIndex(prefs.getInt(_devBakSel) ?? 0));
    }
    if (prefs.containsKey(_devBakUnlocked)) {
      final oldBU = prefs.getInt(_devBakUnlocked) ?? 1;
      var newBU = 1;
      for (var oldIdx = 0;
          oldIdx < oldBU && oldIdx < _themeNamesBeforeOrderV3.length;
          oldIdx++) {
        newBU = max(newBU, remapOldIndex(oldIdx) + 1);
      }
      await prefs.setInt(_devBakUnlocked, min(newBU, AppThemes.all.length));
    }

    await prefs.setBool(_themeOrderV3Key, true);
  }

  static Future<void> _migrateThemeOrderV4IfNeeded(SharedPreferences prefs) async {
    if (prefs.getBool(_themeOrderV4Key) ?? false) return;

    int newIndexForName(String name) {
      final i = AppThemes.all.indexWhere((t) => t.name == name);
      return i >= 0 ? i : 0;
    }

    String nameForOldIndex(int oldIdx) {
      if (oldIdx < 0 || oldIdx >= _themeNamesBeforeOrderV4.length) {
        return AppThemes.all.first.name;
      }
      return _themeNamesBeforeOrderV4[oldIdx];
    }

    int remapOldIndex(int oldIdx) => newIndexForName(nameForOldIndex(oldIdx));

    if (prefs.containsKey(_selectedThemeKey)) {
      final oldS = prefs.getInt(_selectedThemeKey) ?? 0;
      await prefs.setInt(_selectedThemeKey, remapOldIndex(oldS));
    }

    final oldU = prefs.getInt(_unlockedThemesKey) ?? 1;
    var newU = 1;
    for (var oldIdx = 0;
        oldIdx < oldU && oldIdx < _themeNamesBeforeOrderV4.length;
        oldIdx++) {
      newU = max(newU, remapOldIndex(oldIdx) + 1);
    }
    await prefs.setInt(_unlockedThemesKey, min(newU, AppThemes.all.length));

    if (prefs.containsKey(_devBakSel)) {
      await prefs.setInt(_devBakSel, remapOldIndex(prefs.getInt(_devBakSel) ?? 0));
    }
    if (prefs.containsKey(_devBakUnlocked)) {
      final oldBU = prefs.getInt(_devBakUnlocked) ?? 1;
      var newBU = 1;
      for (var oldIdx = 0;
          oldIdx < oldBU && oldIdx < _themeNamesBeforeOrderV4.length;
          oldIdx++) {
        newBU = max(newBU, remapOldIndex(oldIdx) + 1);
      }
      await prefs.setInt(_devBakUnlocked, min(newBU, AppThemes.all.length));
    }

    await prefs.setBool(_themeOrderV4Key, true);
  }

  static Future<void> _migrateThemeOrderV5IfNeeded(SharedPreferences prefs) async {
    if (prefs.getBool(_themeOrderV5Key) ?? false) return;

    int newIndexForName(String name) {
      final i = AppThemes.all.indexWhere((t) => t.name == name);
      return i >= 0 ? i : 0;
    }

    String nameForOldIndex(int oldIdx) {
      if (oldIdx < 0 || oldIdx >= _themeNamesBeforeOrderV5.length) {
        return AppThemes.all.first.name;
      }
      return _themeNamesBeforeOrderV5[oldIdx];
    }

    int remapOldIndex(int oldIdx) => newIndexForName(nameForOldIndex(oldIdx));

    if (prefs.containsKey(_selectedThemeKey)) {
      final oldS = prefs.getInt(_selectedThemeKey) ?? 0;
      await prefs.setInt(_selectedThemeKey, remapOldIndex(oldS));
    }

    final oldU = prefs.getInt(_unlockedThemesKey) ?? 1;
    var newU = 1;
    for (var oldIdx = 0;
        oldIdx < oldU && oldIdx < _themeNamesBeforeOrderV5.length;
        oldIdx++) {
      newU = max(newU, remapOldIndex(oldIdx) + 1);
    }
    await prefs.setInt(_unlockedThemesKey, min(newU, AppThemes.all.length));

    if (prefs.containsKey(_devBakSel)) {
      await prefs.setInt(_devBakSel, remapOldIndex(prefs.getInt(_devBakSel) ?? 0));
    }
    if (prefs.containsKey(_devBakUnlocked)) {
      final oldBU = prefs.getInt(_devBakUnlocked) ?? 1;
      var newBU = 1;
      for (var oldIdx = 0;
          oldIdx < oldBU && oldIdx < _themeNamesBeforeOrderV5.length;
          oldIdx++) {
        newBU = max(newBU, remapOldIndex(oldIdx) + 1);
      }
      await prefs.setInt(_devBakUnlocked, min(newBU, AppThemes.all.length));
    }

    await prefs.setBool(_themeOrderV5Key, true);
  }

  static Future<bool> isDevModeActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_devActiveKey) ?? false;
  }

  static Future<void> setDevModeActive(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_devActiveKey, value);
  }

  static Future<void> saveDevBackup(SessionStats s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_devBakBest, s.bestScore);
    await prefs.setDouble(_devBakAcc, s.bestAccuracy);
    await prefs.setInt(_devBakStreak, s.bestStreak);
    await prefs.setInt(_devBakFast, s.fastestAverageReactionMs);
    await prefs.setInt(_devBakGames, s.gamesPlayed);
    await prefs.setInt(_devBakStars, s.totalStars);
    await prefs.setInt(_devBakUnlocked, s.unlockedThemes);
    await prefs.setInt(_devBakSel, s.selectedThemeIndex);
  }

  static Future<SessionStats?> loadDevBackup() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_devBakUnlocked)) return null;
    return SessionStats(
      bestScore: prefs.getInt(_devBakBest) ?? 0,
      bestAccuracy: prefs.getDouble(_devBakAcc) ?? 0,
      bestStreak: prefs.getInt(_devBakStreak) ?? 0,
      fastestAverageReactionMs: prefs.getInt(_devBakFast) ?? 0,
      gamesPlayed: prefs.getInt(_devBakGames) ?? 0,
      totalStars: prefs.getInt(_devBakStars) ?? 0,
      unlockedThemes: prefs.getInt(_devBakUnlocked) ?? 1,
      selectedThemeIndex: prefs.getInt(_devBakSel) ?? 0,
    );
  }

  static Future<void> clearDevBackup() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in [
      _devBakBest,
      _devBakAcc,
      _devBakStreak,
      _devBakFast,
      _devBakGames,
      _devBakStars,
      _devBakUnlocked,
      _devBakSel,
    ]) {
      await prefs.remove(k);
    }
  }

  static Future<SessionStats> load() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateV2IfNeeded(prefs);
    await _migrateThemeOrderV3IfNeeded(prefs);
    await _migrateThemeOrderV4IfNeeded(prefs);
    await _migrateThemeOrderV5IfNeeded(prefs);

    var u = prefs.getInt(_unlockedThemesKey) ?? 1;
    var s = prefs.getInt(_selectedThemeKey) ?? 0;
    u = u.clamp(1, AppThemes.all.length);
    s = s.clamp(0, u - 1);

    return SessionStats(
      bestScore: prefs.getInt(_bestScoreKey) ?? 0,
      bestAccuracy: prefs.getDouble(_bestAccuracyKey) ?? 0,
      bestStreak: prefs.getInt(_bestStreakKey) ?? 0,
      fastestAverageReactionMs: prefs.getInt(_fastestAvgKey) ?? 0,
      gamesPlayed: prefs.getInt(_gamesPlayedKey) ?? 0,
      totalStars: prefs.getInt(_totalStarsKey) ?? 0,
      unlockedThemes: u,
      selectedThemeIndex: s,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bestScoreKey, bestScore);
    await prefs.setDouble(_bestAccuracyKey, bestAccuracy);
    await prefs.setInt(_bestStreakKey, bestStreak);
    await prefs.setInt(_fastestAvgKey, fastestAverageReactionMs);
    await prefs.setInt(_gamesPlayedKey, gamesPlayed);
    await prefs.setInt(_totalStarsKey, totalStars);
    await prefs.setInt(_unlockedThemesKey, unlockedThemes);
    await prefs.setInt(_selectedThemeKey, selectedThemeIndex);
  }

  SessionStats mergeGame(GameResult result) {
    final isFastestAverage = fastestAverageReactionMs == 0 ||
        (result.averageReactionMs > 0 &&
            result.averageReactionMs < fastestAverageReactionMs);
    final nextStars = totalStars + result.starsEarned;
    final themeUnlocks = unlockedSlotsForStars(nextStars);
    final safeSel = selectedThemeIndex < 0 ? 0 : selectedThemeIndex;
    final nextSelected = min(safeSel, themeUnlocks - 1);

    return SessionStats(
      bestScore: max(bestScore, result.totalScore),
      bestAccuracy: max(bestAccuracy, result.accuracy),
      bestStreak: max(bestStreak, result.bestStreak),
      fastestAverageReactionMs:
          isFastestAverage ? result.averageReactionMs : fastestAverageReactionMs,
      gamesPlayed: gamesPlayed + 1,
      totalStars: nextStars,
      unlockedThemes: themeUnlocks,
      selectedThemeIndex: nextSelected,
    );
  }
}

class ScoreEngine {
  static const int basePoints = 100;
  static const int maxSpeedBonus = 100;
  static const int wrongPenalty = 50;

  int scoreForCorrect({
    required int reactionMs,
    required int streak,
  }) {
    final speedBonus = max(0, maxSpeedBonus - (reactionMs / 20).round());
    final multiplier = 1 + min(1.0, streak * 0.1);
    return ((basePoints + speedBonus) * multiplier).round();
  }

  int scoreForWrong() => -wrongPenalty;
}

class DifficultyController {
  const DifficultyController();

  int levelForAnswered(int answered) => min(10, 1 + (answered ~/ 5));

  int timePenaltyMs(int level) => 1000 + (level * 120);

  bool showHintText(int level) => level <= 4;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onThemeChanged});

  final ValueChanged<int> onThemeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SessionStats? _stats;
  bool _devModeActive = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await SessionStats.load();
    final devActive = await SessionStats.isDevModeActive();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _devModeActive = devActive;
    });
    widget.onThemeChanged(stats.selectedThemeIndex);
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final unlocked = stats == null
        ? 1
        : stats.unlockedThemes.clamp(1, AppThemes.all.length);
    final selectedTheme = stats?.selectedThemeIndex ?? 0;
    final activeTheme =
        AppThemes.all[min(selectedTheme, unlocked - 1).clamp(0, AppThemes.all.length - 1)];
    final palette = HomeThemePalette(activeTheme);
    final borderSide = palette.panelBorder;

    return Scaffold(
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: activeTheme.background,
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Positioned.fill(
            child: ThemeEffectLayer(theme: activeTheme),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _header(theme: activeTheme, palette: palette)),
                      if (kDebugMode)
                        IconButton(
                          tooltip: _devModeActive
                              ? 'Exit developer mode and restore your save'
                              : 'Developer mode: unlock all themes for exploration',
                          onPressed: () => _onDevBaselinePressed(context),
                          icon: Icon(
                            _devModeActive ? Icons.build_circle : Icons.developer_mode,
                            color: palette.titleColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Card(
                    elevation: 0,
                    color: palette.sectionSheet,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: borderSide,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Play',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: palette.titleColor,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 12),
                          _modeCard(
                            context: context,
                            palette: palette,
                            title: 'Object Side Sprint',
                            subtitle:
                                'Two objects appear left/right. Choose which icon is on the asked side.',
                            icon: Icons.dashboard_customize,
                            accent: palette.seedOrNeutral,
                            onPressed: _playObjectSprint,
                          ),
                          const SizedBox(height: 10),
                          _modeCard(
                            context: context,
                            palette: palette,
                            title: 'Arrow Rush',
                            subtitle:
                                'Arrows flash fast. Buttons are stacked so you can’t just tap the arrow side.',
                            icon: Icons.bolt,
                            accent: palette.seedOrNeutral,
                            onPressed: _playArrowRush,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: palette.sectionSheet,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: borderSide,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Themes',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: palette.titleColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              Text(
                                '$unlocked/${AppThemes.all.length} unlocked',
                                style: TextStyle(
                                  color: palette.mutedColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (stats == null)
                            const LinearProgressIndicator()
                          else
                            SizedBox(
                              height: 52,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: AppThemes.all.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final t = AppThemes.all[index];
                                  final locked = index >= unlocked;
                                  final selected = !locked && index == selectedTheme;
                                  return _themePill(
                                    theme: t,
                                    locked: locked,
                                    selected: selected,
                                    palette: palette,
                                    onTap: locked
                                        ? null
                                        : () async {
                                            final current = await SessionStats.load();
                                            final updated = SessionStats(
                                              bestScore: current.bestScore,
                                              bestAccuracy: current.bestAccuracy,
                                              bestStreak: current.bestStreak,
                                              fastestAverageReactionMs:
                                                  current.fastestAverageReactionMs,
                                              gamesPlayed: current.gamesPlayed,
                                              totalStars: current.totalStars,
                                              unlockedThemes: current.unlockedThemes,
                                              selectedThemeIndex: index,
                                            );
                                            await updated.save();
                                            if (!mounted) return;
                                            setState(() => _stats = updated);
                                            widget.onThemeChanged(index);
                                          },
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            palette.isPlain
                                ? 'Default is always free. Earn ${SessionStats.starsPerThemeUnlock} total stars per extra theme unlock.'
                                : 'Themes change the app colors and background. Earn ${SessionStats.starsPerThemeUnlock} stars per unlock.',
                            style: TextStyle(
                              color: palette.mutedColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (stats != null) ...[
                            Builder(builder: (context) {
                              final per = SessionStats.starsPerThemeUnlock;
                              final unlockedSlots =
                                  SessionStats.unlockedSlotsForStars(stats.totalStars);
                              final towardNextTier = unlockedSlots >= AppThemes.all.length
                                  ? 1.0
                                  : ((stats.totalStars - (unlockedSlots - 1) * per) / per)
                                      .clamp(0.0, 1.0);
                              final needForNextTheme = unlockedSlots >= AppThemes.all.length
                                  ? 0
                                  : unlockedSlots * per - stats.totalStars;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: towardNextTier,
                                    color: palette.seedOrNeutral,
                                    backgroundColor: palette.nestedSheet.withValues(
                                      alpha: palette.isDark ? 0.45 : 0.65,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    unlockedSlots >= AppThemes.all.length
                                        ? 'All themes unlocked!'
                                        : needForNextTheme <= 0
                                            ? 'Theme unlocked — pick it above!'
                                            : '$needForNextTheme more stars → ${AppThemes.all[unlockedSlots].name}',
                                    style: TextStyle(
                                      color: palette.mutedColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: stats == null
                        ? const Center(child: CircularProgressIndicator())
                        : Card(
                            elevation: 0,
                            color: palette.sectionSheet,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: borderSide,
                            ),
                            child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                Text(
                                  'Progress',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: palette.titleColor,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                _statRow('Games Played', '${stats.gamesPlayed}',
                                    palette: palette),
                                _statRow('Best Score', '${stats.bestScore}',
                                    palette: palette),
                                _statRow('Total Stars', '${stats.totalStars}',
                                    palette: palette),
                                _statRow(
                                  'Best Accuracy',
                                  '${stats.bestAccuracy.toStringAsFixed(1)}%',
                                  palette: palette,
                                ),
                                _statRow('Best Streak', '${stats.bestStreak}',
                                    palette: palette),
                                _statRow(
                                  'Fastest Avg Reaction',
                                  stats.fastestAverageReactionMs == 0
                                      ? '-'
                                      : '${stats.fastestAverageReactionMs} ms',
                                  palette: palette,
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header({required AppTheme theme, required HomeThemePalette palette}) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: palette.headerIconBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: palette.seedOrNeutral.withValues(
                alpha: palette.isPlain ? 0.35 : (palette.isDark ? 0.25 : 0.35),
              ),
            ),
          ),
          child: Center(
            child: Icon(
              theme.icon,
              size: 24,
              color: palette.titleColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LeftRight Rush',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: palette.titleColor,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                'Fast, fun left/right brain training',
                style: TextStyle(
                  color: palette.mutedColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _themePill({
    required AppTheme theme,
    required bool locked,
    required bool selected,
    required HomeThemePalette palette,
    VoidCallback? onTap,
  }) {
    final base = palette.nestedSheet;
    final seed = theme.seedColor;
    final idleBorder = palette.isPlain
        ? Colors.black.withValues(alpha: 0.12)
        : seed.withValues(alpha: palette.isDark ? 0.12 : 0.22);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? seed.withValues(alpha: palette.isDark ? 0.30 : 0.26) : base,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? seed.withValues(alpha: 0.75) : idleBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(locked ? Icons.lock_rounded : theme.icon, size: 18, color: palette.titleColor),
            const SizedBox(width: 8),
            Text(
              theme.name,
              style: TextStyle(
                color: palette.titleColor,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeCard({
    required BuildContext context,
    required HomeThemePalette palette,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Future<void> Function() onPressed,
  }) {
    return Card(
      elevation: 0,
      color: palette.nestedSheet,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accent.withValues(alpha: palette.isDark ? 0.28 : 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: palette.isDark ? 0.22 : 0.20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: palette.titleColor,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: palette.bodyColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(backgroundColor: accent),
              child: const Text('Play'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onDevBaselinePressed(BuildContext context) async {
    if (_devModeActive) {
      final restore = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Exit developer mode?'),
          content: const Text(
            'Restore your progress, stars, and theme unlocks from before developer mode.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );
      if (restore != true || !mounted) return;

      final back = await SessionStats.loadDevBackup() ?? SessionStats();
      await back.save();
      await SessionStats.clearDevBackup();
      await SessionStats.setDevModeActive(false);
      if (!mounted) return;
      setState(() {
        _stats = back;
        _devModeActive = false;
      });
      widget.onThemeChanged(back.selectedThemeIndex);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Developer mode off — progress restored')),
      );
      return;
    }

    final apply = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter developer mode?'),
        content: Text(
          'Unlock all ${AppThemes.all.length} themes (${SessionStats.starsPerThemeUnlock}★ each), '
          'and reset games played / best scores / streaks so you can explore from a clean slate. '
          'Tap the button again to restore your previous save.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enter'),
          ),
        ],
      ),
    );
    if (apply != true || !mounted) return;

    final current = _stats ?? await SessionStats.load();
    await SessionStats.saveDevBackup(current);

    final baseline = SessionStats.devExplorationBaseline();
    await baseline.save();
    await SessionStats.setDevModeActive(true);
    if (!mounted) return;
    setState(() {
      _stats = baseline;
      _devModeActive = true;
    });
    widget.onThemeChanged(baseline.selectedThemeIndex);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Developer mode on (debug build only)')),
    );
  }

  AppTheme _gameplayTheme(SessionStats s) {
    final u = s.unlockedThemes.clamp(1, AppThemes.all.length);
    final i = s.selectedThemeIndex.clamp(0, u - 1);
    return AppThemes.all[i];
  }

  Future<void> _playObjectSprint() async {
    final stats = _stats ?? SessionStats();
    final theme = _gameplayTheme(stats);
    final result = await Navigator.of(context).push<GameResult>(
      MaterialPageRoute(builder: (_) => ObjectSideSprintScreen(theme: theme)),
    );
    await _persistResult(result);
  }

  Future<void> _playArrowRush() async {
    final stats = _stats ?? SessionStats();
    final theme = _gameplayTheme(stats);
    final result = await Navigator.of(context).push<GameResult>(
      MaterialPageRoute(builder: (_) => ArrowRushScreen(theme: theme)),
    );
    await _persistResult(result);
  }

  Future<void> _persistResult(GameResult? result) async {
    final stats = _stats;
    if (result == null) return;
    final updated = (stats ?? SessionStats()).mergeGame(result);
    await updated.save();
    if (!mounted) return;
    setState(() => _stats = updated);
    widget.onThemeChanged(updated.selectedThemeIndex);
  }

  Widget _statRow(String label, String value, {required HomeThemePalette palette}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: palette.bodyColor)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: palette.titleColor,
            ),
          ),
        ],
      ),
    );
  }
}

class ObjectSideSprintScreen extends StatefulWidget {
  const ObjectSideSprintScreen({super.key, required this.theme});

  final AppTheme theme;

  @override
  State<ObjectSideSprintScreen> createState() => _ObjectSideSprintScreenState();
}

class _ObjectSideSprintScreenState extends State<ObjectSideSprintScreen> {
  static const int gameLengthSeconds = 45;
  static const List<ObjectItem> _objectPool = [
    ('ball', '', null, 'assets/emoji/soccer_ball.png'),
    ('apple', '🍎', null, null),
    ('star', '⭐', null, null),
    ('rocket', '🚀', null, null),
    ('gift', '🎁', null, null),
    ('book', '📘', null, null),
    ('car', '🚗', null, null),
    ('moon', '🌙', null, null),
    ('pizza', '🍕', null, null),
    ('teddy', '🧸', null, null),
  ];

  final ScoreEngine _scoreEngine = ScoreEngine();
  final DifficultyController _difficulty = const DifficultyController();
  final Random _random = Random();
  final List<int> _reactionHistory = [];

  ObjectRound? _round;
  DateTime? _roundStart;
  Timer? _timer;

  int _timeLeftSeconds = gameLengthSeconds;
  int _score = 0;
  int _correct = 0;
  int _wrong = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _difficultyLevel = 1;

  @override
  void initState() {
    super.initState();
    _nextRound();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timeLeftSeconds--;
        if (_timeLeftSeconds <= 0) {
          _finishGame();
        }
      });
    });
  }

  void _nextRound() {
    final leftIndex = _random.nextInt(_objectPool.length);
    int rightIndex = _random.nextInt(_objectPool.length);
    while (rightIndex == leftIndex) {
      rightIndex = _random.nextInt(_objectPool.length);
    }
    final leftItem = _objectPool[leftIndex];
    final rightItem = _objectPool[rightIndex];
    final options = <ObjectItem>[leftItem, rightItem]..shuffle(_random);
    final askSide = _random.nextBool() ? SideChoice.left : SideChoice.right;

    setState(() {
      _round = ObjectRound(
        leftItem: leftItem,
        rightItem: rightItem,
        answerOptions: options,
        askSide: askSide,
      );
      _roundStart = DateTime.now();
    });
  }

  void _select(ObjectItem selectedItem) {
    final round = _round;
    final start = _roundStart;
    if (round == null || start == null) return;

    final reactionMs = DateTime.now().difference(start).inMilliseconds;
    _reactionHistory.add(reactionMs);

    setState(() {
      final correctItem =
          round.askSide == SideChoice.left ? round.leftItem : round.rightItem;
      if (selectedItem.$1 == correctItem.$1) {
        HapticFeedback.selectionClick();
        _correct++;
        _streak++;
        _bestStreak = max(_bestStreak, _streak);
        _score += _scoreEngine.scoreForCorrect(reactionMs: reactionMs, streak: _streak);
      } else {
        HapticFeedback.heavyImpact();
        _wrong++;
        _streak = 0;
        _score += _scoreEngine.scoreForWrong();
        final penaltyMs = _difficulty.timePenaltyMs(_difficultyLevel);
        final newTimeMs = (_timeLeftSeconds * 1000) - penaltyMs;
        _timeLeftSeconds = max(0, (newTimeMs / 1000).ceil());
      }
      _difficultyLevel = _difficulty.levelForAnswered(_correct + _wrong);

      if (_timeLeftSeconds <= 0) {
        _finishGame();
        return;
      }
    });

    _nextRound();
  }

  void _finishGame() {
    _timer?.cancel();
    _timer = null;

    final avgReaction = _reactionHistory.isEmpty
        ? 0
        : (_reactionHistory.reduce((a, b) => a + b) / _reactionHistory.length)
            .round();

    final result = GameResult(
      mode: GameMode.objectSprint,
      totalScore: _score,
      correctAnswers: _correct,
      wrongAnswers: _wrong,
      averageReactionMs: avgReaction,
      bestStreak: _bestStreak,
      maxDifficulty: _difficultyLevel,
      starsEarned: _starsEarned(),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(result: result, theme: widget.theme),
      ),
      result: result,
    );
  }

  int _starsEarned() {
    if (_score >= 1800 && _correct >= 15 && _difficultyLevel >= 6) return 3;
    if (_score >= 1100 && _correct >= 10) return 2;
    return 1;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final round = _round;
    if (round == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Object Side Sprint')),
      body: SafeArea(
        child: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.primary.withValues(alpha: 0.12),
                    scheme.tertiary.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
            Positioned.fill(child: ThemeEffectLayer(theme: widget.theme)),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _chip('Time', '${_timeLeftSeconds}s'),
                    _chip('Score', '$_score'),
                    _chip('Streak', '$_streak'),
                    _chip('Lvl', '$_difficultyLevel'),
                  ],
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    round.askSide == SideChoice.left
                        ? 'Which item is on the left?'
                        : 'Which item is on the right?',
                    key: ValueKey(
                      '${round.leftItem.$1}_${round.rightItem.$1}_${_correct + _wrong}',
                    ),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 170,
                  child: Row(
                    children: [
                      Expanded(
                        child: _sidePanel(
                          item: round.leftItem,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _sidePanel(
                          item: round.rightItem,
                          color: scheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _answerButton(round.answerOptions[0], scheme),
                      const SizedBox(height: 12),
                      _answerButton(round.answerOptions[1], scheme),
                    ],
                  ),
                )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: scheme.primary.withValues(alpha: 0.14),
      side: BorderSide.none,
    );
  }

  Widget _sidePanel({
    required ObjectItem item,
    required Color color,
  }) {
    final Widget glyph = item.$4 != null
        ? Image.asset(
            item.$4!,
            width: 86,
            height: 86,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          )
        : item.$3 != null
            ? Icon(
                item.$3,
                size: 88,
                color: Colors.white,
              )
            : Text(
                item.$2,
                style: emojiGlyphStyle(86),
                textAlign: TextAlign.center,
              );
    return Ink(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(child: glyph),
    );
  }

  Widget _answerButton(ObjectItem option, ColorScheme scheme) {
    return Expanded(
      child: FilledButton(
        onPressed: () => _select(option),
        style: FilledButton.styleFrom(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            option.$4 != null
                ? Image.asset(
                    option.$4!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  )
                : option.$3 != null
                    ? Icon(option.$3, size: 48, color: scheme.onSurface)
                    : Text(
                        option.$2,
                        style: emojiGlyphStyle(48),
                      ),
            const SizedBox(height: 4),
            Text(
              option.$1.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen floating glyphs: on-theme [iconPool] only, with a gentle “fall + sway” path.
class ThemeEffectLayer extends StatelessWidget {
  const ThemeEffectLayer({super.key, required this.theme});

  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    switch (theme.effect) {
      case ThemeVisualEffect.none:
        return FloatingIconBackground(
          iconPool: const [
            Icons.palette_rounded,
            Icons.tune_rounded,
            Icons.brush_rounded,
            Icons.interests_rounded,
          ],
          tint: const Color(0xFF71717A),
          count: 18,
          alpha: 0.082,
          speedMin: 0.07,
          speedMax: 0.32,
          swayCyclesPerPass: 2.2,
          horizontalSway: 0.09,
          minGlyphSize: 11,
          maxGlyphSize: 30,
        );
      case ThemeVisualEffect.neonPulse:
        return FloatingIconBackground(
          iconPool: const [
            Icons.electric_bolt_rounded,
            Icons.bolt_rounded,
            Icons.offline_bolt_rounded,
            Icons.flash_on_rounded,
          ],
          tint: theme.seedColor,
          count: 20,
          alpha: 0.1,
          speedMin: 0.14,
          speedMax: 0.52,
          swayCyclesPerPass: 3.2,
          horizontalSway: 0.07,
          minGlyphSize: 13,
          maxGlyphSize: 32,
        );
      case ThemeVisualEffect.starfield:
        return Stack(
          fit: StackFit.expand,
          children: [
            TwinkleDotsBackground(tint: theme.seedColor.withValues(alpha: 0.95)),
            FloatingIconBackground(
              iconPool: const [
                Icons.rocket_launch_rounded,
                Icons.star_rounded,
                Icons.satellite_alt_rounded,
                Icons.public_rounded,
              ],
              tint: const Color(0xFFC4B5FD),
              count: 18,
              alpha: 0.11,
              speedMin: 0.05,
              speedMax: 0.26,
              swayCyclesPerPass: 1.8,
              horizontalSway: 0.1,
              minGlyphSize: 13,
              maxGlyphSize: 34,
            ),
          ],
        );
      case ThemeVisualEffect.jungleDrift:
        return FloatingIconBackground(
          iconPool: const [
            Icons.forest_rounded,
            Icons.eco_rounded,
            Icons.grass_rounded,
            Icons.local_florist_rounded,
          ],
          tint: const Color(0xFF0F6A3A),
          count: 20,
          alpha: 0.095,
          speedMin: 0.04,
          speedMax: 0.22,
          swayCyclesPerPass: 2.6,
          horizontalSway: 0.12,
          minGlyphSize: 13,
          maxGlyphSize: 34,
        );
      case ThemeVisualEffect.candyBubbles:
        return Stack(
          fit: StackFit.expand,
          children: [
            BubbleBackground(tint: theme.seedColor),
            BubbleBackground(
              tint: Color.lerp(theme.seedColor, const Color(0xFFFBBF24), 0.35)!,
            ),
            FloatingIconBackground(
              iconPool: const [
                Icons.cake_rounded,
                Icons.icecream_rounded,
                Icons.cookie_rounded,
                Icons.emoji_food_beverage_rounded,
              ],
              tint: theme.seedColor,
              count: 20,
              alpha: 0.11,
              speedMin: 0.08,
              speedMax: 0.34,
              swayCyclesPerPass: 2.4,
              horizontalSway: 0.11,
              minGlyphSize: 13,
              maxGlyphSize: 30,
            ),
          ],
        );
      case ThemeVisualEffect.oceanWave:
        return Stack(
          fit: StackFit.expand,
          children: [
            WaveBandsBackground(tint: theme.seedColor),
            FloatingIconBackground(
              iconPool: const [
                Icons.waves_rounded,
                Icons.water_rounded,
                Icons.water_drop_rounded,
                Icons.scuba_diving_rounded,
              ],
              tint: theme.seedColor,
              count: 20,
              alpha: 0.11,
              speedMin: 0.07,
              speedMax: 0.36,
              swayCyclesPerPass: 2.0,
              horizontalSway: 0.1,
              minGlyphSize: 12,
              maxGlyphSize: 32,
            ),
          ],
        );
      case ThemeVisualEffect.sunsetOrbs:
        return FloatingIconBackground(
          iconPool: const [
            Icons.wb_twilight_rounded,
            Icons.wb_sunny_rounded,
            Icons.cloud_rounded,
            Icons.flare_rounded,
          ],
          tint: const Color(0xFFE76F51),
          count: 18,
          alpha: 0.095,
          speedMin: 0.05,
          speedMax: 0.28,
          swayCyclesPerPass: 2.3,
          horizontalSway: 0.1,
          minGlyphSize: 13,
          maxGlyphSize: 34,
        );
      case ThemeVisualEffect.galaxySpiral:
        return Stack(
          fit: StackFit.expand,
          children: [
            SpiralSparkleBackground(tint: theme.seedColor),
            FloatingIconBackground(
              iconPool: const [
                Icons.star_rounded,
                Icons.auto_awesome_rounded,
                Icons.star_border_rounded,
                Icons.flare_rounded,
              ],
              tint: const Color(0xFFF472B6),
              count: 20,
              alpha: 0.095,
              speedMin: 0.05,
              speedMax: 0.3,
              swayCyclesPerPass: 2.8,
              horizontalSway: 0.11,
              minGlyphSize: 11,
              maxGlyphSize: 30,
            ),
          ],
        );
      case ThemeVisualEffect.snowfall:
        return FloatingIconBackground(
          iconPool: const [
            Icons.snowing,
            Icons.cloudy_snowing,
            Icons.severe_cold_rounded,
            Icons.cloud_rounded,
          ],
          tint: const Color(0xFF38BDF8),
          count: 22,
          alpha: 0.1,
          speedMin: 0.05,
          speedMax: 0.22,
          swayCyclesPerPass: 3.5,
          horizontalSway: 0.13,
          minGlyphSize: 11,
          maxGlyphSize: 28,
        );
    }
  }
}

class FloatingIconBackground extends StatefulWidget {
  const FloatingIconBackground({
    super.key,
    required this.iconPool,
    required this.tint,
    this.count = 14,
    this.alpha = 0.10,
    this.speedMin = 0.2,
    this.speedMax = 0.8,
    /// Horizontal oscillations while drifting downward (higher = busier zig-zag).
    this.swayCyclesPerPass = 2.5,
    /// Max horizontal offset as a fraction of screen width (0.08 ≈ 8%).
    this.horizontalSway = 0.09,
    this.minGlyphSize = 14,
    this.maxGlyphSize = 40,
  });

  final List<IconData> iconPool;
  final Color tint;
  final int count;
  final double alpha;
  final double speedMin;
  final double speedMax;
  final double swayCyclesPerPass;
  final double horizontalSway;
  final double minGlyphSize;
  final double maxGlyphSize;

  @override
  State<FloatingIconBackground> createState() => _FloatingIconBackgroundState();
}

class _FloatingIconBackgroundState extends State<FloatingIconBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _rand = Random();
  late List<_Floaty> _floaties;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 14))
          ..repeat();
    _rebuildFloaties();
  }

  /// Flutter reuses this [State] when switching themes (same widget type + key).
  /// Without this, particles keep the **previous** theme’s icons (e.g. Default palette on Ice).
  @override
  void didUpdateWidget(covariant FloatingIconBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameParticleConfig(oldWidget, widget)) {
      _rebuildFloaties();
    }
  }

  bool _sameParticleConfig(FloatingIconBackground a, FloatingIconBackground b) {
    if (a.count != b.count ||
        a.speedMin != b.speedMin ||
        a.speedMax != b.speedMax ||
        a.minGlyphSize != b.minGlyphSize ||
        a.maxGlyphSize != b.maxGlyphSize ||
        a.horizontalSway != b.horizontalSway ||
        a.swayCyclesPerPass != b.swayCyclesPerPass ||
        a.iconPool.length != b.iconPool.length) {
      return false;
    }
    for (var i = 0; i < a.iconPool.length; i++) {
      if (a.iconPool[i].codePoint != b.iconPool[i].codePoint) return false;
    }
    return true;
  }

  void _rebuildFloaties() {
    final sizeSpan = max(4.0, widget.maxGlyphSize - widget.minGlyphSize);
    final n = max(1, widget.iconPool.length);
    _floaties = List.generate(widget.count, (i) {
      return _Floaty(
        icon: widget.iconPool[_rand.nextInt(n)],
        x: _rand.nextDouble(),
        y: _rand.nextDouble(),
        size: widget.minGlyphSize + _rand.nextDouble() * sizeSpan,
        speed: widget.speedMin + _rand.nextDouble() * (widget.speedMax - widget.speedMin),
        swayAmp: widget.horizontalSway * (0.45 + _rand.nextDouble() * 0.55),
        phase: _rand.nextDouble() * pi * 2,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _FloatingIconPainter(
              floaties: _floaties,
              t: _controller.value,
              tint: widget.tint,
              alpha: widget.alpha,
              swayCyclesPerPass: widget.swayCyclesPerPass,
            ),
          );
        },
      ),
    );
  }
}

class _Floaty {
  _Floaty({
    required this.icon,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.swayAmp,
    required this.phase,
  });

  final IconData icon;
  final double x;
  final double y;
  final double size;
  final double speed;
  final double swayAmp;
  final double phase;
}

class _FloatingIconPainter extends CustomPainter {
  _FloatingIconPainter({
    required this.floaties,
    required this.t,
    required this.tint,
    required this.alpha,
    required this.swayCyclesPerPass,
  });

  final List<_Floaty> floaties;
  final double t;
  final Color tint;
  final double alpha;
  final double swayCyclesPerPass;

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in floaties) {
      final p = (f.y + t * f.speed) % 1.0;
      final dy = p;
      final sway =
          sin(p * 2 * pi * swayCyclesPerPass + f.phase) * f.swayAmp;
      var dx = f.x + sway;
      dx = (dx % 1.0 + 1.0) % 1.0;

      final offset = Offset(dx * size.width, dy * size.height);
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(f.icon.codePoint),
          style: TextStyle(
            fontSize: f.size,
            color: tint.withValues(alpha: alpha),
            fontFamily: f.icon.fontFamily ?? 'MaterialIcons',
            package: f.icon.fontPackage,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, offset - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingIconPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.tint != tint ||
        oldDelegate.swayCyclesPerPass != swayCyclesPerPass;
  }
}

class TwinkleDotsBackground extends StatefulWidget {
  const TwinkleDotsBackground({super.key, required this.tint});
  final Color tint;
  @override
  State<TwinkleDotsBackground> createState() => _TwinkleDotsBackgroundState();
}

class _TwinkleDotsBackgroundState extends State<TwinkleDotsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _TwinklePainter(t: _c.value, tint: widget.tint),
        ),
      ),
    );
  }
}

class _TwinklePainter extends CustomPainter {
  _TwinklePainter({required this.t, required this.tint});
  final double t;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 48; i++) {
      final x = (i * 73 % 100) / 100 * size.width;
      final y = (i * 41 % 100) / 100 * size.height;
      final pulse = (sin((t * 2 * pi) + i * 0.31) + 1) / 2;
      paint.color = tint.withValues(alpha: 0.035 + pulse * 0.2);
      canvas.drawCircle(Offset(x, y), 1.2 + pulse * 2.8, paint);
    }
    for (var i = 0; i < 18; i++) {
      final x = (i * 59 % 100) / 100 * size.width;
      final y = (i * 83 % 100) / 100 * size.height;
      final pulse = (sin((t * 3 * pi) + i) + 1) / 2;
      paint.color = Colors.white.withValues(alpha: 0.02 + pulse * 0.07);
      canvas.drawCircle(Offset(x, y), 0.8 + pulse * 1.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TwinklePainter oldDelegate) => oldDelegate.t != t;
}

class BubbleBackground extends StatefulWidget {
  const BubbleBackground({super.key, required this.tint});
  final Color tint;
  @override
  State<BubbleBackground> createState() => _BubbleBackgroundState();
}

class _BubbleBackgroundState extends State<BubbleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _BubblePainter(t: _c.value, tint: widget.tint),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.t, required this.tint});
  final double t;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()..style = PaintingStyle.stroke;
    final fill = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 28; i++) {
      final x = (i * 47 % 100) / 100 * size.width;
      final y = (1 - ((t * 0.85 + (i / 34)) % 1.0)) * size.height;
      final r = 7 + (i % 6) * 3.5;
      stroke.color = tint.withValues(alpha: 0.07 + (i % 5) * 0.028);
      stroke.strokeWidth = 1.2 + (i % 3) * 0.15;
      canvas.drawCircle(Offset(x, y), r, stroke);
      fill.color = tint.withValues(alpha: 0.03 + (i % 4) * 0.015);
      canvas.drawCircle(Offset(x, y), r * 0.35, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => oldDelegate.t != t;
}

class WaveBandsBackground extends StatefulWidget {
  const WaveBandsBackground({super.key, required this.tint});
  final Color tint;
  @override
  State<WaveBandsBackground> createState() => _WaveBandsBackgroundState();
}

class _WaveBandsBackgroundState extends State<WaveBandsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 7))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _WavePainter(t: _c.value, tint: widget.tint),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.t, required this.tint});
  final double t;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tint.withValues(alpha: 0.11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final paintSoft = Paint()
      ..color = tint.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (var band = 0; band < 5; band++) {
      final path = Path();
      final yBase = size.height * (0.14 + band * 0.16);
      path.moveTo(0, yBase);
      for (double x = 0; x <= size.width; x += 8) {
        final y = yBase +
            sin((x / size.width) * 2 * pi + t * 2 * pi + band * 0.7) * (9 + band);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, band.isEven ? paint : paintSoft);
    }
    for (var band = 0; band < 3; band++) {
      final path = Path();
      final yBase = size.height * (0.55 + band * 0.14);
      path.moveTo(0, yBase);
      for (double x = 0; x <= size.width; x += 10) {
        final y = yBase +
            sin((x / size.width) * 3 * pi - t * 2.2 * pi + band) * (5 + band * 2);
        path.lineTo(x, y);
      }
      paintSoft.color = tint.withValues(alpha: 0.045);
      canvas.drawPath(path, paintSoft);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => oldDelegate.t != t;
}

class SpiralSparkleBackground extends StatefulWidget {
  const SpiralSparkleBackground({super.key, required this.tint});
  final Color tint;
  @override
  State<SpiralSparkleBackground> createState() => _SpiralSparkleBackgroundState();
}

class _SpiralSparkleBackgroundState extends State<SpiralSparkleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 9))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _SpiralPainter(t: _c.value, tint: widget.tint),
        ),
      ),
    );
  }
}

class _SpiralPainter extends CustomPainter {
  _SpiralPainter({required this.t, required this.tint});
  final double t;
  final Color tint;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final p = Paint()..style = PaintingStyle.fill;
    for (var arm = 0; arm < 2; arm++) {
      final armPhase = arm * pi;
      for (var i = 0; i < 44; i++) {
        final angle = (i / 44) * 7 * pi + t * 2 * pi + armPhase;
        final radius = 12 + i * 3.4;
        final pos = center +
            Offset(
              cos(angle) * radius * (arm == 0 ? 1.0 : -0.92),
              sin(angle) * radius * 0.58,
            );
        p.color = tint.withValues(alpha: 0.045 + (i % 6) * 0.018);
        canvas.drawCircle(pos, 1.4 + (i % 4) * 0.85, p);
      }
    }
    for (var i = 0; i < 11; i++) {
      final a = (i / 11) * 2 * pi + t * 3 * pi;
      final r = size.shortestSide * (0.12 + (i % 5) * 0.04);
      p.color = tint.withValues(alpha: 0.08);
      canvas.drawCircle(center + Offset(cos(a) * r, sin(a) * r * 0.5), 2.2, p);
    }
  }

  @override
  bool shouldRepaint(covariant _SpiralPainter oldDelegate) => oldDelegate.t != t;
}

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.result, required this.theme});

  final GameResult result;
  final AppTheme theme;

  String get _modeTitle {
    switch (result.mode) {
      case GameMode.objectSprint:
        return 'Object Side Sprint';
      case GameMode.arrowRush:
        return 'Arrow Rush';
    }
  }

  /// Dark home themes set [MaterialApp] to dark brightness; this screen uses light
  /// surfaces, so we use a **light** scheme from the same seed for readable type.
  static ThemeData _resultsThemeFor(AppTheme appTheme) {
    final scheme = ColorScheme.fromSeed(
      seedColor: appTheme.seedColor,
      brightness: Brightness.light,
    );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final on = scheme.onSurface;
    final onMuted = scheme.onSurface.withValues(alpha: 0.78);
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: on,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          color: on,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: on,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          color: onMuted,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          color: on,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: onMuted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _resultsThemeFor(theme),
      child: Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          final cardColor = Color.alphaBlend(
            theme.seedColor.withValues(alpha: 0.06),
            cs.surfaceContainerLow,
          );
          final border = BorderSide(
            color: theme.seedColor.withValues(alpha: 0.22),
          );

          Widget statCard({required Widget child}) {
            return Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: border,
              ),
              child: child,
            );
          }

          return Scaffold(
            backgroundColor: Color.alphaBlend(
              theme.seedColor.withValues(alpha: 0.04),
              cs.surface,
            ),
            appBar: AppBar(
              title: const Text('Round Complete'),
              backgroundColor: cs.surfaceContainerLow,
              foregroundColor: cs.onSurface,
              elevation: 0,
              surfaceTintColor: theme.seedColor.withValues(alpha: 0.35),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    statCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(_modeTitle, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(
                              'Score: ${result.totalScore}',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Accuracy: ${result.accuracy.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Stars earned: ',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                for (var i = 0; i < result.starsEarned; i++)
                                  Icon(
                                    Icons.star_rounded,
                                    color: Color.lerp(Colors.amber.shade700, theme.seedColor, 0.15),
                                    size: 22,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    statCard(
                      child: ListTile(
                        title: const Text('Correct Answers'),
                        trailing: Text(
                          '${result.correctAnswers}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    statCard(
                      child: ListTile(
                        title: const Text('Wrong Answers'),
                        trailing: Text(
                          '${result.wrongAnswers}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    statCard(
                      child: ListTile(
                        title: const Text('Best Streak'),
                        trailing: Text(
                          '${result.bestStreak}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    statCard(
                      child: ListTile(
                        title: const Text('Max Difficulty Reached'),
                        trailing: Text(
                          'Level ${result.maxDifficulty}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    statCard(
                      child: ListTile(
                        title: const Text('Average Reaction'),
                        trailing: Text(
                          '${result.averageReactionMs} ms',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        final Widget nextScreen = switch (result.mode) {
                          GameMode.objectSprint => ObjectSideSprintScreen(theme: theme),
                          GameMode.arrowRush => ArrowRushScreen(theme: theme),
                        };
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => nextScreen),
                        );
                      },
                      child: const Text('Play Again'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(result),
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ArrowRushScreen extends StatefulWidget {
  const ArrowRushScreen({super.key, required this.theme});

  final AppTheme theme;

  @override
  State<ArrowRushScreen> createState() => _ArrowRushScreenState();
}

class _ArrowRushScreenState extends State<ArrowRushScreen> {
  static const int gameLengthSeconds = 45;

  final ScoreEngine _scoreEngine = ScoreEngine();
  final DifficultyController _difficulty = const DifficultyController();
  final Random _random = Random();
  final List<int> _reactionHistory = [];

  SideChoice _target = SideChoice.left;
  DateTime _roundStart = DateTime.now();
  Timer? _timer;

  int _timeLeftSeconds = gameLengthSeconds;
  int _score = 0;
  int _correct = 0;
  int _wrong = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _difficultyLevel = 1;
  Color? _flashColor;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _nextPrompt();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timeLeftSeconds--;
        if (_timeLeftSeconds <= 0) {
          _finishGame();
        }
      });
    });
  }

  void _nextPrompt() {
    setState(() {
      _target = _random.nextBool() ? SideChoice.left : SideChoice.right;
      _roundStart = DateTime.now();
    });
  }

  void _choose(SideChoice selection) {
    final reactionMs = DateTime.now().difference(_roundStart).inMilliseconds;
    _reactionHistory.add(reactionMs);

    setState(() {
      if (selection == _target) {
        HapticFeedback.selectionClick();
        _flash(Color(0xFF2ECC71));
        _correct++;
        _streak++;
        _bestStreak = max(_bestStreak, _streak);
        _score += _scoreEngine.scoreForCorrect(reactionMs: reactionMs, streak: _streak);
      } else {
        HapticFeedback.heavyImpact();
        _flash(Color(0xFFFF3B30));
        _wrong++;
        _streak = 0;
        _score += _scoreEngine.scoreForWrong();
        final newTimeMs =
            (_timeLeftSeconds * 1000) - _difficulty.timePenaltyMs(_difficultyLevel);
        _timeLeftSeconds = max(0, (newTimeMs / 1000).ceil());
      }
      _difficultyLevel = _difficulty.levelForAnswered(_correct + _wrong);

      if (_timeLeftSeconds <= 0) {
        _finishGame();
        return;
      }
    });

    _nextPrompt();
  }

  void _flash(Color color) {
    _flashTimer?.cancel();
    _flashColor = color;
    _flashTimer = Timer(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      setState(() {
        _flashColor = null;
      });
    });
  }

  void _finishGame() {
    _timer?.cancel();
    _timer = null;
    _flashTimer?.cancel();
    final avgReaction = _reactionHistory.isEmpty
        ? 0
        : (_reactionHistory.reduce((a, b) => a + b) / _reactionHistory.length)
            .round();

    final result = GameResult(
      mode: GameMode.arrowRush,
      totalScore: _score,
      correctAnswers: _correct,
      wrongAnswers: _wrong,
      averageReactionMs: avgReaction,
      bestStreak: _bestStreak,
      maxDifficulty: _difficultyLevel,
      starsEarned: _starsEarned(),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(result: result, theme: widget.theme),
      ),
      result: result,
    );
  }

  int _starsEarned() {
    if (_score >= 1900 && _correct >= 18 && _difficultyLevel >= 6) return 3;
    if (_score >= 1200 && _correct >= 12) return 2;
    return 1;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLeft = _target == SideChoice.left;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Arrow Rush')),
      body: SafeArea(
        child: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.primary.withValues(alpha: 0.14),
                    scheme.secondary.withValues(alpha: 0.10),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _chip('Time', '${_timeLeftSeconds}s'),
                        _chip('Score', '$_score'),
                        _chip('Lvl', '$_difficultyLevel'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Match the arrow direction',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 180),
                          scale: 1 + min(0.3, _difficultyLevel * 0.03),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isLeft ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                              key: ValueKey(_target.name),
                              size: 180,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: () => _choose(SideChoice.left),
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'LEFT',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => _choose(SideChoice.right),
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.secondary,
                            foregroundColor: scheme.onSecondary,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'RIGHT',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(child: ThemeEffectLayer(theme: widget.theme)),
            IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 90),
                color: _flashColor == null
                    ? Colors.transparent
                    : _flashColor!.withValues(alpha: 0.22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: scheme.secondary.withValues(alpha: 0.14),
      side: BorderSide.none,
    );
  }
}
