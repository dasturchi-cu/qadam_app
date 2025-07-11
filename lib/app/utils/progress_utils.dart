import 'package:qadam_app/app/models/challenge_model.dart';

/// Returns progress (0.0 - 1.0) for a challenge based on current steps.
double calculateChallengeProgress(ChallengeModel challenge, int currentSteps) {
  if (challenge.targetSteps <= 0) {
    return challenge.progress;
  }
  double progress = currentSteps / challenge.targetSteps;
  progress = progress.clamp(0.0, 1.0);
  final existingProgress = challenge.progress;
  return progress > existingProgress ? progress : existingProgress;
} 