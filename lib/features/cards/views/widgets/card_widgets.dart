import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../../models/card_rarity.dart';

class CardWidget extends StatelessWidget {
  final CardModel card;

  const CardWidget({super.key, required this.card});

  Color _getRarityColor() {
    switch (card.rarity) {
      case CardRarity.common:
        return Colors.grey.shade400;
      case CardRarity.rare:
        return Colors.blue.shade400;
      case CardRarity.epic:
        return Colors.purple.shade500;
      case CardRarity.legendary:
        return Colors.orange.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.71,
      child: Container(
        decoration: BoxDecoration(
          color: _getRarityColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    card.position,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: card.imageUrl != null
                      ? Image.network(card.imageUrl!)
                      : const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.white54,
                        ),
                ),
              ),
              Center(
                child: Text(
                  card.playerName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    card.teamName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const Divider(color: Colors.white54, thickness: 1),
              _buildStatsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Goals', card.stats.goals),
            _buildStatRow('Games', card.stats.games),
          ],
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
