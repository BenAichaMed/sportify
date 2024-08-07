class PoolAllocator {
  final int numberOfCourts;
  final List<Map<String, dynamic>> participants;

  PoolAllocator({required this.numberOfCourts, required this.participants});

  Map<int, List<Map<String, dynamic>>> allocatePools() {
    Map<int, List<Map<String, dynamic>>> pools = {};
    int poolSize = (participants.length / numberOfCourts).ceil();

    for (int i = 0; i < numberOfCourts; i++) {
      pools[i] = participants.skip(i * poolSize).take(poolSize).toList();
    }

    return pools;
  }
}

class MatchScheduler {
  final Map<int, List<String>> pools;

  MatchScheduler({required this.pools});

  Map<int, List<Map<String, String>>> createSchedule() {
    Map<int, List<Map<String, String>>> schedule = {};

    pools.forEach((poolId, participants) {
      schedule[poolId] = [];
      for (int i = 0; i < participants.length; i++) {
        for (int j = i + 1; j < participants.length; j++) {
          schedule[poolId]!.add({
            'player1': participants[i],
            'player2': participants[j],
          });
        }
      }
    });

    return schedule;
  }
}

class NotificationService {
  void notifyParticipants(String matchId, String player1, String player2, DateTime matchTime) {
    // Implement notification logic here
    print('Notification: Match $matchId between $player1 and $player2 at $matchTime');
  }

  void scheduleReminders(String matchId, String player1, String player2, DateTime matchTime) {
    // Implement reminder logic here
    print('Reminder: Match $matchId between $player1 and $player2 at $matchTime');
  }
}