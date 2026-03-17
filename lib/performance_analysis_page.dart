import 'package:flutter/material.dart';
import 'data/progress_manager.dart';
import 'home_page.dart';

class PerformanceAnalysisPage extends StatelessWidget {
  const PerformanceAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {

    final currentSets = ProgressManager.currentSets;


    return Scaffold(
      appBar: AppBar(
        title: const Text("Performance Analysis"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
            );
          },
        ),
      ),
      body: currentSets.isEmpty
          ? const Center(child: Text("No performance data"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // 🔥 OVERALL SUMMARY ON TOP
            _buildOverallSummary(currentSets),

            const SizedBox(height: 20),

            // 🔥 SHOW ALL SETS DIRECTLY (NO DROPDOWN)
            ...List.generate(
              currentSets.length,
                  (index) => Card(
                elevation: 6,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildSet(currentSets[index], index + 1),
                ),
              ),
            ),
          ],
        ),
      ),




    );
  }
  double _calculateTotalTime(Map<String, LetterPerformance>? data) {
    if (data == null) return 0;

    double total = 0;
    for (final perf in data.values) {
      for (final t in perf.times) {
        total += t;
      }
    }
    return total;
  }

  // =========================
  // EACH SET
  // =========================

  Widget _buildSet(CycleSet set, int setNumber) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Set $setNumber",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 12),

        _buildAssessmentBlock("Assessment 1", set.assessment1),

        const SizedBox(height: 16),

        _buildAssessmentBlock("Assessment 2", set.assessment2),
      ],
    );
  }


  Widget _buildOverallSummary(List<CycleSet> sets) {
    int totalCorrect = 0;
    int totalWrong = 0;
    double totalTime = 0;

    for (final set in sets) {
      final a1 = set.assessment1.secondAttempt
          ?? set.assessment1.reinforcement
          ?? set.assessment1.mainAttempt;

      final a2 = set.assessment2.secondAttempt
          ?? set.assessment2.reinforcement
          ?? set.assessment2.mainAttempt;


      void process(Map<String, LetterPerformance>? data) {
        if (data == null) return;

        for (final perf in data.values) {
          totalCorrect += perf.correct;
          totalWrong += perf.wrong;

          for (final t in perf.times) {
            totalTime += t;
          }
        }
      }

      process(a1);
      process(a2);
    }

    final total = totalCorrect + totalWrong;
    double percent = total == 0
        ? 0.0
        : (totalCorrect / total) * 100.0;


    final minutes = totalTime ~/ 60;
    final seconds = (totalTime % 60).toInt();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Overall Performance",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),

          // Percentage
          Text(
            "${percent.toStringAsFixed(1)}%",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _accuracyColor(percent),
            ),
          ),

          const SizedBox(height: 10),

          LinearProgressIndicator(
            value: percent / 100,
            minHeight: 10,
            color: _accuracyColor(percent),
            backgroundColor: Colors.grey.shade300,
          ),

          const SizedBox(height: 12),

          Text(
            "Total Time: ${minutes}m ${seconds}s",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  // =========================
  // ASSESSMENT BLOCK
  // =========================

  Widget _buildAssessmentBlock(

      String title,
      AssessmentSet set,
      ) {
    Widget buildAttempt(
        String label,
        Map<String, LetterPerformance>? data,
        ) {
      if (data == null || data.isEmpty) {
        return const Text("No Data");
      }

      final percent = _calculateAccuracy(data);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _progressBar(label, percent),
          const SizedBox(height: 10),

          // Achieved & Unsatisfactory Columns
          _buildLetterColumns(data),

          const SizedBox(height: 8),

          // Total Time for this attempt
          Text(
            "Total Time: ${_calculateTotalTime(data).toStringAsFixed(2)} sec",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            buildAttempt("Appropriate Response", set.mainAttempt),

            if (set.reinforcement != null) ...[
              const SizedBox(height: 12),
              buildAttempt("Reinforcement", set.reinforcement),
            ],

            if (set.secondAttempt != null) ...[
              const SizedBox(height: 12),
              buildAttempt("Second Attempt", set.secondAttempt),
            ],

          ],
        ),
      ),
    );
  }


  // =========================
  // PROGRESS BAR
  // =========================

  Widget _progressBar(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label - ${value.toStringAsFixed(1)}%"),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / 100,
          minHeight: 8,
          color: _accuracyColor(value),
          backgroundColor: Colors.grey.shade300,
        ),
      ],
    );
  }

  // =========================
  // ACCURACY CALCULATION
  // =========================

  double _calculateAccuracy(Map<String, LetterPerformance> data) {
    int correct = 0;
    int wrong = 0;

    for (final perf in data.values) {
      correct += perf.correct;
      wrong += perf.wrong;
    }

    final total = correct + wrong;
    if (total == 0) return 0;

    return (correct / total) * 100;
  }

  Color _accuracyColor(double percent) {
    if (percent >= 80) return Colors.green;
    if (percent >= 50) return Colors.orange;
    return Colors.red;
  }
  Widget _buildLetterColumns(Map<String, LetterPerformance> data) {
    List<String> achieved = [];
    List<String> unsatisfactory = [];

    data.forEach((letter, perf) {
      if (perf.wrong > 0) {
        unsatisfactory.add(letter.toUpperCase());
      } else if (perf.correct > 0) {
        achieved.add(letter.toUpperCase());
      }
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Achieved",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: achieved
                    .map((e) => Chip(
                  label: Text(e),
                  backgroundColor: Colors.green.shade100,
                ))
                    .toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Unsatisfactory",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: unsatisfactory
                    .map((e) => Chip(
                  label: Text(e),
                  backgroundColor: Colors.red.shade100,
                ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

}
