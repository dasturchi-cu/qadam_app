import 'package:qadam_app/app/models/challenge_model.dart';

/// Returns progress (0.0 - 1.0) for a challenge based on current steps.
double calculateChallengeProgress(ChallengeModel challenge, int currentSteps) {
  if (challenge.targetSteps <= 0) {
    return 0.0; // ❌ challenge.progress emas
  }

  double progress = currentSteps / challenge.targetSteps;
  return progress.clamp(0.0, 1.0);
}
