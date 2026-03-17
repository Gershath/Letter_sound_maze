class ProgressManager {
  /* ============================================================
   *                         CYCLES
   * ============================================================ */

  static final List<List<String>> cycles = [
    ["a", "b", "c", "d", "e"],
    ["f", "g", "h", "i", "j"],
    ["k", "l", "m", "n", "o"],
    ["p", "q", "r", "s", "t"],
    ["u", "v", "w", "x", "y", "z"],
  ];

  static int currentCycle = 0;

  static int trainingIndex = 0;
  static int assessment1Index = 0;
  static int assessment2Index = 0;

  // ==================
// Unlock System
// ==================

  static int unlockedCycle = 0; // only 0 at start
  static bool gameCompleted = false;
  // ===============================
// SESSION STORAGE
// ===============================

  static List<PerformanceSession> allSessions = [];



  /* ============================================================
   *               LETTER STORAGE (GLOBAL – NOT RESET)
   * ============================================================ */

  static final Set<String> trainingDone = {};
  static final Set<String> assessment1Done = {};
  static final Set<String> assessment2Done = {};

  /* ============================================================
   *                  DISPLAY-FRIENDLY GETTERS
   * ============================================================ */

  /// Training letters completed (A B C)
  static List<String> get trainingLetters =>
      trainingDone.map((e) => e.toUpperCase()).toList()..sort();

  /// Assessment 1 letters completed
  static List<String> get assessment1Letters =>
      assessment1Done.map((e) => e.toUpperCase()).toList()..sort();

  /// Assessment 2 letters completed
  static List<String> get assessment2Letters =>
      assessment2Done.map((e) => e.toUpperCase()).toList()..sort();

  /// TOTAL finished letters (ALL phases + ALL cycles)
  static List<String> get totalFinishedLetters =>
      {...trainingDone, ...assessment1Done, ...assessment2Done}
          .map((e) => e.toUpperCase())
          .toList()
        ..sort();

  /// Cycle display (Cycle 1 / 5)
  static String get cycleDisplay {
    final total = cycles.length;

    // Clamp display value so it never exceeds total cycles
    final displayCycle =
    currentCycle >= total ? total : currentCycle + 1;

    return "$displayCycle / $total";
  }


  /* ============================================================
   *                    CURRENT LETTER
   * ============================================================ */

  static String get currentLetter {
    if (isTrainingPending()) return currentTrainingLetter.toUpperCase();
    if (isAssessment1Pending()) return currentAssessment1Letter.toUpperCase();
    if (isAssessment2Pending()) return currentAssessment2Letter.toUpperCase();
    return "-";
  }

  static String get currentTrainingLetter =>
      cycles[currentCycle][trainingIndex];

  static String get currentAssessment1Letter =>
      cycles[currentCycle][assessment1Index];

  static String get currentAssessment2Letter =>
      cycles[currentCycle][assessment2Index];

  /* ============================================================
   *                       TRAINING
   * ============================================================ */

  static bool nextTrainingLetter() {
    trainingDone.add(currentTrainingLetter);
    trainingIndex++;

    if (trainingIndex >= cycles[currentCycle].length) {
      trainingIndex = 0;
      return true;
    }
    return false;
  }

  /* ============================================================
   *                     ASSESSMENT 1
   * ============================================================ */
  static bool assessment1RetakeUsed = false;

  static bool nextAssessment1Letter() {
    assessment1Done.add(currentAssessment1Letter);
    assessment1Index++;

    if (assessment1Index >= cycles[currentCycle].length) {
      assessment1Index = 0;
      return true;
    }
    return false;
  }

  /* ============================================================
   *                     ASSESSMENT 2
   * ============================================================ */
  static bool assessment2RetakeUsed = false;

  static bool nextAssessment2Letter() {
    assessment2Done.add(currentAssessment2Letter);
    assessment2Index++;

    if (assessment2Index >= cycles[currentCycle].length) {
      assessment2Index = 0;
      return true;
    }
    return false;
  }



  /* ============================================================
   *                      STATE CHECKS
   * ============================================================ */

  static bool isTrainingPending() =>
      trainingIndex < cycles[currentCycle].length;

  static bool isAssessment1Pending() =>
      trainingIndex == cycles[currentCycle].length &&
          assessment1Index < cycles[currentCycle].length;

  static bool isAssessment2Pending() =>
      assessment1Index == cycles[currentCycle].length &&
          assessment2Index < cycles[currentCycle].length;

  static bool isAllCyclesCompleted() =>
      currentCycle == cycles.length;



  /* ============================================================
   *                          RESET
   * ============================================================ */

  static void reset() {
    currentCycle = 0;
    unlockedCycle = 0;
    gameCompleted = false;

    trainingIndex = 0;
    assessment1Index = 0;
    assessment2Index = 0;

    trainingDone.clear();
    assessment1Done.clear();
    assessment2Done.clear();
    _performanceData.clear();
  }


  /* ============================================================
 *                PERFORMANCE STORAGE
 * ============================================================ */
  static List<CycleSet> _currentSets = [];

  static Map<String, LetterPerformance> _tempA1 = {};
  static Map<String, LetterPerformance> _tempA2 = {};

  static Map<String, LetterPerformance>? _tempA1Retry;
  static Map<String, LetterPerformance>? _tempA2Retry;

  static final Map<String, Map<String, LetterPerformance>>
  _performanceData = {};

  /* ============================================================
 *           BACKWARD COMPATIBILITY (DO NOT REMOVE)
 * ============================================================ */

// ---- Old letter getters ----
  static Set<String> get completedLetters =>
      totalFinishedLetters.toSet();

  static Set<String> get completedTrainingLetters =>
      trainingLetters.toSet();

// ---- Old count-based getters (derived, not stored) ----
  static int get trainingCompletedCount => trainingLetters.length;

  static int get assessment1CompletedCount => assessment1Letters.length;

  static int get assessment2CompletedCount => assessment2Letters.length;

  static int get totalCompletedLetters => totalFinishedLetters.length;

// ---- Old total letters getter ----
  static int get totalLetters =>
      cycles.fold<int>(0, (sum, cycle) => sum + cycle.length);

  /* ============================================================
 *              PERFORMANCE READ HELPERS
 * ============================================================ */

  static Map<String, LetterPerformance> getLetterPerformance(String mode) {
    return _performanceData[mode] ?? {};
  }

  static Set<String> get allTrackedLetters {
    final letters = <String>{};
    for (final modeMap in _performanceData.values) {
      letters.addAll(modeMap.keys);
    }
    return letters;
  }

  static bool hasPerformanceData() => _performanceData.isNotEmpty;

  /* ============================================================
 *                PERFORMANCE ANALYTICS STORAGE
 * ============================================================ */

  static final Map<String, LetterPerformance> assessment1Performance = {};
  static final Map<String, LetterPerformance> assessment2Performance = {};
  static final Map<String, LetterPerformance> gamePerformance = {};

  static void recordAttempt({
    required String letter,
    required bool isCorrect,
    required double timeTaken,
    required String mode,
  }) {
    final key = letter.toLowerCase();

    Map<String, LetterPerformance>? targetMap;

    if (mode == 'assessment1') {
      if (assessment1RetakeUsed) {
        _tempA1Retry ??= {};
        targetMap = _tempA1Retry;
      } else {
        targetMap = _tempA1;
      }
    }
    else if (mode == 'assessment2') {
      if (assessment2RetakeUsed) {
        _tempA2Retry ??= {};
        targetMap = _tempA2Retry;
      } else {
        targetMap = _tempA2;
      }
    }
    else if (mode == 'game') {
      targetMap = gamePerformance;
    }

    if (targetMap == null) return;

    targetMap.putIfAbsent(key, () => LetterPerformance());
    targetMap[key]!.addAttempt(isCorrect, timeTaken);
  }


  // ==================
// Cycle performance
// ==================
  static int assessmentCorrect = 0;
  static int assessmentTotal = 0;

  static void startAssessmentCycle(int totalQuestions) {
    assessmentCorrect = 0;
    assessmentTotal = totalQuestions;
  }

  static void recordAssessmentAnswer(bool isCorrect) {
    if (isCorrect) assessmentCorrect++;
  }

  static double getAssessmentPercentage() {
    if (assessmentTotal == 0) return 0;
    return (assessmentCorrect / assessmentTotal) * 100;
  }

  static bool failedAssessment() {
    return getAssessmentPercentage() < 70;
  }

  static void moveToNextCycle() {
    if (currentCycle > cycles.length) return;

    final newSet = CycleSet(
      assessment1: AssessmentSet(
        mainAttempt: Map.from(_tempA1),
        reinforcement: _tempA1Retry != null
            ? Map.from(_tempA1Retry!)
            : null,
      ),
      assessment2: AssessmentSet(
        mainAttempt: Map.from(_tempA2),
        reinforcement: _tempA2Retry != null
            ? Map.from(_tempA2Retry!)
            : null,
      ),
    );


    // ✅ FIRST TIME (less than 5 sets)
    if (_currentSets.length < cycles.length) {
      _currentSets.add(newSet);
    }
    // ✅ REPLAY → store inside same set as retry
    else {
      final index = currentCycle.clamp(0, _currentSets.length - 1);

      final oldSet = _currentSets[index];

      _currentSets[index] = CycleSet(
        assessment1: AssessmentSet(
          mainAttempt: oldSet.assessment1.mainAttempt,
          reinforcement: oldSet.assessment1.reinforcement,
          secondAttempt: _tempA1Retry != null
              ? Map.from(_tempA1Retry!)
              : Map.from(_tempA1),
        ),
        assessment2: AssessmentSet(
          mainAttempt: oldSet.assessment2.mainAttempt,
          reinforcement: oldSet.assessment2.reinforcement,
          secondAttempt: _tempA2Retry != null
              ? Map.from(_tempA2Retry!)
              : Map.from(_tempA2),
        ),
      );
    }



    // Clear temp
    _tempA1.clear();
    _tempA2.clear();
    _tempA1Retry = null;
    _tempA2Retry = null;

    currentCycle++;

    if (currentCycle > unlockedCycle) {
      unlockedCycle = currentCycle;
    }

    if (currentCycle >= cycles.length) {
      unlockedCycle = cycles.length - 1;
      gameCompleted = false;
    }

    trainingIndex = 0;
    assessment1Index = 0;
    assessment2Index = 0;

    // ✅ RESET RETAKE FLAGS
    assessment1RetakeUsed = false;
    assessment2RetakeUsed = false;
  }






  // ==================
// Cycle Unlock Checks
// ==================

  static bool isCycleUnlocked(int index) {
    return index <= unlockedCycle;
  }

  static bool isLastCycle(int index) {
    return index == cycles.length - 1;
  }

  static bool isAllCyclesUnlocked() {
    return unlockedCycle >= cycles.length - 1;
  }

  static void unlockNextCycle() {
    if (unlockedCycle < cycles.length - 1) {
      unlockedCycle++;
    }
  }

  static bool get isGameUnlocked {
    return _currentSets.length >= cycles.length;
  }




  static List<CycleSet> get currentSets => _currentSets;


  static List<CycleSet> finalGameSets = [];


  static void finishGame() {
    gameCompleted = true;
  }




  static void startNewGame() {
    _currentSets.clear();
    gamePerformance.clear();
    gameCompleted = false;
  }




  static void resetGameLock() {
    gameCompleted = false;
  }
  // ==================
// Game Status Getter
// ==================

  static bool get gameFinished => gameCompleted;







}

/* ============================================================
 *                PERFORMANCE DATA MODELS
 * ============================================================ */

class LetterPerformance {
  int correct = 0;
  int wrong = 0;
  final List<double> times = [];

  void addAttempt(bool isCorrect, double timeTaken) {
    if (isCorrect) {
      correct++;
    } else {
      wrong++;
    }
    times.add(timeTaken);
  }

  double get averageTime =>
      times.isEmpty ? 0 : times.reduce((a, b) => a + b) / times.length;
}

class AssessmentSet {
  Map<String, LetterPerformance> mainAttempt;
  Map<String, LetterPerformance>? reinforcement;
  Map<String, LetterPerformance>? secondAttempt;

  AssessmentSet({
    required this.mainAttempt,
    this.reinforcement,
    this.secondAttempt,
  });
}


class CycleSet {
  AssessmentSet assessment1;
  AssessmentSet assessment2;

  CycleSet({
    required this.assessment1,
    required this.assessment2,
  });
}

class PerformanceSession {
  final DateTime dateTime;
  final List<CycleSet> sets; // 5 sets
  final Map<String, LetterPerformance> gamePerformance;

  PerformanceSession({
    required this.dateTime,
    required this.sets,
    required this.gamePerformance,
  });
}





