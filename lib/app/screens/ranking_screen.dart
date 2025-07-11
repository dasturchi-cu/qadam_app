import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ranking_service.dart';
import 'package:qadam_app/app/components/loading_widget.dart';
import 'package:qadam_app/app/components/error_widget.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<RankingService>(context, listen: false).fetchRankings());
    print("Init 212112");
  }

  @override
  Widget build(BuildContext context) {
    final rankingService = Provider.of<RankingService>(context);
    final rankings = rankingService.rankings;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Reyting',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: rankings.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildTopPerformersCard(rankings),
                Expanded(
                  child: _buildRankingsList(rankings),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Reytingda foydalanuvchilar yo\'q',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Birinchi bo\'ling va o\'z natijangizni ko\'rsating!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersCard(List rankings) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _buildTopPerformer(
                rankings.first,
                'Eng yuqori',
                Icons.emoji_events,
                Colors.amber,
                Colors.amber[100]!,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildTopPerformer(
                rankings.last,
                'Eng past',
                Icons.trending_down,
                Colors.red,
                Colors.red[100]!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformer(
      user, String title, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.name.isNotEmpty ? user.name : user.userId,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${user.steps} qadam',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsList(List rankings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.leaderboard, color: Colors.blue[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Barcha natijalar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: rankings.length,
              separatorBuilder: (_, __) => Divider(
                color: Colors.grey[200],
                height: 1,
                indent: 70,
              ),
              itemBuilder: (context, i) {
                final user = rankings[i];
                return _buildRankingItem(user, i);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem(user, int index) {
    Color rankColor = Colors.grey[600]!;
    IconData rankIcon = Icons.person;

    if (index == 0) {
      rankColor = Colors.amber[700]!;
      rankIcon = Icons.emoji_events;
    } else if (index == 1) {
      rankColor = Colors.grey[400]!;
      rankIcon = Icons.emoji_events;
    } else if (index == 2) {
      rankColor = Colors.brown[400]!;
      rankIcon = Icons.emoji_events;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rankColor.withOpacity(0.3)),
            ),
            child: Center(
              child: index < 3
                  ? Icon(rankIcon, color: rankColor, size: 20)
                  : Text(
                      '#${user.rank}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: rankColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isNotEmpty ? user.name : user.userId,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Foydalanuvchi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          // Steps info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_walk, color: Colors.blue[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  '${user.steps}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
