class AchievementModel {
  final String challengeTitle;
  final int reward;
  final DateTime date;

  AchievementModel({
    required this.challengeTitle,
    required this.reward,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'challengeTitle': challengeTitle,
      'reward': reward,
      'date': date.toIso8601String(),
    };
  }

  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      challengeTitle: map['challengeTitle'] ?? '',
      reward: map['reward'] ?? 0,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    );
  }
} 