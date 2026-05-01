import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const LeftRightApp());
}

class LeftRightApp extends StatelessWidget {
  const LeftRightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'LeftRight Rush',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class AppTheme {
  const AppTheme({
    required this.name,
    required this.icon,
    required this.seedColor,
    required this.background,
  });

  final String name;
  final String icon;
  final Color seedColor;
  final List<Color> background;
}

class AppThemes {
  static const List<AppTheme> all = [
    AppTheme(
      name: 'Neon Pop',
      icon: '⚡',
      seedColor: Color(0xFF3B82F6),
      background: [Color(0xFFEEF2FF), Color(0xFFFFF1F2)],
    ),
    AppTheme(
      name: 'Space',
      icon: '🚀',
      seedColor: Color(0xFF7C3AED),
      background: [Color(0xFF0B102A), Color(0xFF1B2A6B)],
    ),
    AppTheme(
      name: 'Jungle',
      icon: '🌿',
      seedColor: Color(0xFF16A34A),
      background: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
    ),
    AppTheme(
      name: 'Candy',
      icon: '🍬',
      seedColor: Color(0xFFEC4899),
      background: [Color(0xFFFFF1F2), Color(0xFFFFF7ED)],
    ),
    AppTheme(
      name: 'Ocean',
      icon: '🌊',
      seedColor: Color(0xFF06B6D4),
      background: [Color(0xFFE0F2FE), Color(0xFFECFEFF)],
    ),
    AppTheme(
      name: 'Sunset',
      icon: '🌅',
      seedColor: Color(0xFFF97316),
      background: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
    ),
    AppTheme(
      name: 'Galaxy Pink',
      icon: '🪐',
      seedColor: Color(0xFFDB2777),
      background: [Color(0xFF1F1147), Color(0xFF3A0A3A)],
    ),
    AppTheme(
      name: 'Ice',
      icon: '❄️',
      seedColor: Color(0xFF0EA5E9),
      background: [Color(0xFFEFF6FF), Color(0xFFE0F2FE)],
    ),
  ];
}

enum SideChoice { left, right }
enum GameMode { objectSprint, arrowRush }

class ObjectRound {
  ObjectRound({
    required this.leftItem,
    required this.rightItem,
    required this.answerOptions,
    required this.askSide,
  });

  final (String, String) leftItem;
  final (String, String) rightItem;
  final List<(String, String)> answerOptions;
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

  static Future<SessionStats> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SessionStats(
      bestScore: prefs.getInt(_bestScoreKey) ?? 0,
      bestAccuracy: prefs.getDouble(_bestAccuracyKey) ?? 0,
      bestStreak: prefs.getInt(_bestStreakKey) ?? 0,
      fastestAverageReactionMs: prefs.getInt(_fastestAvgKey) ?? 0,
      gamesPlayed: prefs.getInt(_gamesPlayedKey) ?? 0,
      totalStars: prefs.getInt(_totalStarsKey) ?? 0,
      unlockedThemes: prefs.getInt(_unlockedThemesKey) ?? 1,
      selectedThemeIndex: prefs.getInt(_selectedThemeKey) ?? 0,
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
    final themeUnlocks = 1 + (nextStars ~/ 30);

    return SessionStats(
      bestScore: max(bestScore, result.totalScore),
      bestAccuracy: max(bestAccuracy, result.accuracy),
      bestStreak: max(bestStreak, result.bestStreak),
      fastestAverageReactionMs:
          isFastestAverage ? result.averageReactionMs : fastestAverageReactionMs,
      gamesPlayed: gamesPlayed + 1,
      totalStars: nextStars,
      unlockedThemes: min(8, themeUnlocks),
      selectedThemeIndex: min(selectedThemeIndex, min(8, themeUnlocks) - 1),
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
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SessionStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await SessionStats.load();
    if (!mounted) return;
    setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final unlocked = (stats?.unlockedThemes ?? 1).clamp(1, AppThemes.all.length);
    final selectedTheme = stats?.selectedThemeIndex ?? 0;
    final safeThemeIndex = min(selectedTheme, unlocked - 1);
    final theme = AppThemes.all[min(safeThemeIndex, AppThemes.all.length - 1)];
    final isDarkish = theme.background.first.computeLuminance() < 0.2;

    return Scaffold(
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.background,
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Positioned.fill(
            child: FloatingEmojiBackground(
              emojiPool: const ['⚡', '⭐', '🍕', '🚀', '🧠', '🎯', '⬅️', '➡️'],
              tint: isDarkish ? Colors.white : Colors.black,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(theme: theme, isDarkish: isDarkish),
                  const SizedBox(height: 14),
                  Card(
                    elevation: 0,
                    color: Colors.white.withValues(alpha: isDarkish ? 0.08 : 0.88),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Play',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: isDarkish ? Colors.white : Colors.black87,
                                ),
                          ),
                          const SizedBox(height: 12),
                          _modeCard(
                            context: context,
                            title: 'Object Side Sprint',
                            subtitle:
                                'Two objects appear left/right. Choose which icon is on the asked side.',
                            icon: Icons.dashboard_customize,
                            accent: const Color(0xFF3B82F6),
                            isDarkish: isDarkish,
                            onPressed: _playObjectSprint,
                          ),
                          const SizedBox(height: 10),
                          _modeCard(
                            context: context,
                            title: 'Arrow Rush',
                            subtitle:
                                'Arrows flash fast. Buttons are stacked so you can’t just tap the arrow side.',
                            icon: Icons.bolt,
                            accent: const Color(0xFFFF3B30),
                            isDarkish: isDarkish,
                            onPressed: _playArrowRush,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: Colors.white.withValues(alpha: isDarkish ? 0.08 : 0.90),
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
                                      color: isDarkish ? Colors.white : Colors.black87,
                                    ),
                              ),
                              Text(
                                '$unlocked/${AppThemes.all.length} unlocked',
                                style: TextStyle(
                                  color: (isDarkish ? Colors.white : Colors.black87)
                                      .withValues(alpha: 0.7),
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
                                  final selected = index == selectedTheme;
                                  return _themePill(
                                    theme: t,
                                    locked: locked,
                                    selected: selected,
                                    isDarkish: isDarkish,
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
                                          },
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            'Themes change the app’s colors and background. Earn ⭐ to unlock more.',
                            style: TextStyle(
                              color: (isDarkish ? Colors.white : Colors.black87)
                                  .withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (stats != null) ...[
                            Builder(builder: (context) {
                              final remaining = (30 - (stats.totalStars % 30)) % 30;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: (stats.totalStars % 30) / 30,
                                    backgroundColor: Colors.white
                                        .withValues(alpha: isDarkish ? 0.10 : 0.35),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    remaining == 0
                                        ? 'Theme unlocked! Keep earning for the next one.'
                                        : '$remaining stars to next theme unlock',
                                    style: TextStyle(
                                      color: (isDarkish ? Colors.white : Colors.black87)
                                          .withValues(alpha: 0.70),
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
                            color: Colors.white.withValues(alpha: isDarkish ? 0.08 : 0.92),
                            child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                Text(
                                  'Progress',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: isDarkish ? Colors.white : Colors.black87,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                _statRow('Games Played', '${stats.gamesPlayed}',
                                    isDarkish: isDarkish),
                                _statRow('Best Score', '${stats.bestScore}',
                                    isDarkish: isDarkish),
                                _statRow('Total Stars', '${stats.totalStars}',
                                    isDarkish: isDarkish),
                                _statRow(
                                  'Best Accuracy',
                                  '${stats.bestAccuracy.toStringAsFixed(1)}%',
                                  isDarkish: isDarkish,
                                ),
                                _statRow('Best Streak', '${stats.bestStreak}',
                                    isDarkish: isDarkish),
                                _statRow(
                                  'Fastest Avg Reaction',
                                  stats.fastestAverageReactionMs == 0
                                      ? '-'
                                      : '${stats.fastestAverageReactionMs} ms',
                                  isDarkish: isDarkish,
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

  Widget _header({required AppTheme theme, required bool isDarkish}) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isDarkish ? 0.10 : 0.75),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(child: Text(theme.icon, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LeftRight Rush',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isDarkish ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                'Fast, fun left/right brain training',
                style: TextStyle(
                  color:
                      (isDarkish ? Colors.white : Colors.black87).withValues(alpha: 0.7),
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
    required bool isDarkish,
    VoidCallback? onTap,
  }) {
    final base = Colors.white.withValues(alpha: isDarkish ? 0.10 : 0.85);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.seedColor.withValues(alpha: 0.22) : base,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? theme.seedColor.withValues(alpha: 0.6) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(locked ? '🔒' : theme.icon),
            const SizedBox(width: 8),
            Text(
              theme.name,
              style: TextStyle(
                color: isDarkish ? Colors.white : Colors.black87,
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
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required bool isDarkish,
    required Future<void> Function() onPressed,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: isDarkish ? 0.10 : 0.92),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
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
                          color: isDarkish ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: (isDarkish ? Colors.white : Colors.black87)
                          .withValues(alpha: 0.75),
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

  Future<void> _playObjectSprint() async {
    final result = await Navigator.of(context).push<GameResult>(
      MaterialPageRoute(builder: (_) => const ObjectSideSprintScreen()),
    );
    await _persistResult(result);
  }

  Future<void> _playArrowRush() async {
    final result = await Navigator.of(context).push<GameResult>(
      MaterialPageRoute(builder: (_) => const ArrowRushScreen()),
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
  }

  Widget _statRow(String label, String value, {required bool isDarkish}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDarkish ? Colors.white : Colors.black87)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkish ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class ObjectSideSprintScreen extends StatefulWidget {
  const ObjectSideSprintScreen({super.key});

  @override
  State<ObjectSideSprintScreen> createState() => _ObjectSideSprintScreenState();
}

class _ObjectSideSprintScreenState extends State<ObjectSideSprintScreen> {
  static const int gameLengthSeconds = 45;
  static final List<(String, String)> _objectPool = [
    ('ball', '⚽'),
    ('apple', '🍎'),
    ('star', '⭐'),
    ('rocket', '🚀'),
    ('gift', '🎁'),
    ('book', '📘'),
    ('car', '🚗'),
    ('moon', '🌙'),
    ('pizza', '🍕'),
    ('teddy', '🧸'),
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
    final options = <(String, String)>[leftItem, rightItem]..shuffle(_random);
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

  void _select((String, String) selectedItem) {
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
      MaterialPageRoute(builder: (_) => ResultsScreen(result: result)),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Object Side Sprint')),
      body: SafeArea(
        child: Padding(
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
                        emoji: round.leftItem.$2,
                        color: const Color(0xFF4E8DFF),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _sidePanel(
                        emoji: round.rightItem.$2,
                        color: const Color(0xFFFF6C63),
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
                    _answerButton(round.answerOptions[0]),
                    const SizedBox(height: 12),
                    _answerButton(round.answerOptions[1]),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.white,
      side: BorderSide.none,
    );
  }

  Widget _sidePanel({
    required String emoji,
    required Color color,
  }) {
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
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 84),
        ),
      ),
    );
  }

  Widget _answerButton((String, String) option) {
    return Expanded(
      child: FilledButton(
        onPressed: () => _select(option),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(option.$2, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 4),
            Text(
              option.$1.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class FloatingEmojiBackground extends StatefulWidget {
  const FloatingEmojiBackground({
    super.key,
    required this.emojiPool,
    required this.tint,
  });

  final List<String> emojiPool;
  final Color tint;

  @override
  State<FloatingEmojiBackground> createState() => _FloatingEmojiBackgroundState();
}

class _FloatingEmojiBackgroundState extends State<FloatingEmojiBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _rand = Random();
  late final List<_Floaty> _floaties;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _floaties = List.generate(14, (i) {
      return _Floaty(
        emoji: widget.emojiPool[_rand.nextInt(widget.emojiPool.length)],
        x: _rand.nextDouble(),
        y: _rand.nextDouble(),
        size: 18 + _rand.nextInt(18).toDouble(),
        speed: 0.2 + _rand.nextDouble() * 0.8,
        drift: (_rand.nextDouble() - 0.5) * 0.10,
        phase: _rand.nextDouble(),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _FloatingEmojiPainter(
            floaties: _floaties,
            t: _controller.value,
            tint: widget.tint,
          ),
        );
      },
    );
  }
}

class _Floaty {
  _Floaty({
    required this.emoji,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.phase,
  });

  final String emoji;
  final double x;
  final double y;
  final double size;
  final double speed;
  final double drift;
  final double phase;
}

class _FloatingEmojiPainter extends CustomPainter {
  _FloatingEmojiPainter({
    required this.floaties,
    required this.t,
    required this.tint,
  });

  final List<_Floaty> floaties;
  final double t;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in floaties) {
      final dy = (f.y + t * f.speed) % 1.0;
      final dx = (f.x + sin((t + f.phase) * pi * 2) * f.drift) % 1.0;

      final offset = Offset(dx * size.width, dy * size.height);
      final tp = TextPainter(
        text: TextSpan(
          text: f.emoji,
          style: TextStyle(
            fontSize: f.size,
            color: tint.withValues(alpha: 0.10),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, offset - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingEmojiPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.tint != tint;
  }
}

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.result});

  final GameResult result;

  String get _modeTitle {
    switch (result.mode) {
      case GameMode.objectSprint:
        return 'Object Side Sprint';
      case GameMode.arrowRush:
        return 'Arrow Rush';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Round Complete')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(_modeTitle, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Score: ${result.totalScore}',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Accuracy: ${result.accuracy.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Stars earned: ${'⭐' * result.starsEarned}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Colors.white,
                child: ListTile(
                  title: const Text('Correct Answers'),
                  trailing: Text('${result.correctAnswers}'),
                ),
              ),
              Card(
                elevation: 0,
                color: Colors.white,
                child: ListTile(
                  title: const Text('Wrong Answers'),
                  trailing: Text('${result.wrongAnswers}'),
                ),
              ),
              Card(
                elevation: 0,
                color: Colors.white,
                child: ListTile(
                  title: const Text('Best Streak'),
                  trailing: Text('${result.bestStreak}'),
                ),
              ),
              Card(
                elevation: 0,
                color: Colors.white,
                child: ListTile(
                  title: const Text('Max Difficulty Reached'),
                  trailing: Text('Level ${result.maxDifficulty}'),
                ),
              ),
              Card(
                elevation: 0,
                color: Colors.white,
                child: ListTile(
                  title: const Text('Average Reaction'),
                  trailing: Text('${result.averageReactionMs} ms'),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  final Widget nextScreen = switch (result.mode) {
                    GameMode.objectSprint => const ObjectSideSprintScreen(),
                    GameMode.arrowRush => const ArrowRushScreen(),
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
  }
}

class ArrowRushScreen extends StatefulWidget {
  const ArrowRushScreen({super.key});

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
      MaterialPageRoute(builder: (_) => ResultsScreen(result: result)),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Arrow Rush')),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
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
                            size: 170,
                            color: Colors.black87,
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
                        style: FilledButton.styleFrom(backgroundColor: Colors.white),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('LEFT', style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => _choose(SideChoice.right),
                        style: FilledButton.styleFrom(backgroundColor: Colors.white),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('RIGHT', style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.white,
      side: BorderSide.none,
    );
  }
}
