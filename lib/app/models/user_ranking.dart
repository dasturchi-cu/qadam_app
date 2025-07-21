class UserRanking {
  final String userId;
  final String name;
  final int steps;

  UserRanking({
    required this.userId,
    required this.name,
    required this.steps,
  });

  factory UserRanking.fromMap(String id, Map<String, dynamic> data) {
    return UserRanking(
      userId: id,
      name: data['displayName'] ?? data['name'] ?? 'Unknown',
      steps: data['steps'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'steps': steps,
    };
  }
}
