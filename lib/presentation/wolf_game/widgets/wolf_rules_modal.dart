import 'package:flutter/material.dart';

class WolfRulesModal extends StatelessWidget {
  const WolfRulesModal({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pets_rounded, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'The Rules of Golf Wolf',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: 16),
          _buildRuleSection(
            context,
            title: '1. Rotational Wolf Honor',
            body: 'The Wolf rotates sequentially across all 4 players every hole (#1 to #16). On holes 17 & 18, trailing players typically receive Wolf honors to stage comebacks.',
          ),
          const SizedBox(height: 10),
          _buildRuleSection(
            context,
            title: '2. Picking a Partner (2 vs 2)',
            body: 'The Wolf watches competitors hit their tee shots. The Wolf must choose a partner immediately after their shot, BEFORE the next competitor hits. If Wolf team wins the hole, each earns 2 points; if Hunters win, each hunter earns 3 points.',
          ),
          const SizedBox(height: 10),
          _buildRuleSection(
            context,
            title: '3. Going Lone Wolf (1 vs 3)',
            body: 'If the Wolf rejects all three tee shots, they declare Lone Wolf. If the Wolf wins the hole outright, they earn 4 points. If any hunter beats the Wolf, all 3 hunters receive 1 point each.',
          ),
          const SizedBox(height: 10),
          _buildRuleSection(
            context,
            title: '4. Blind Wolf (High Stakes 1 vs 3)',
            body: 'The Wolf declares Blind Wolf BEFORE any player tees off! If the Blind Wolf wins outright, they earn 8 points. If the Hunters win, each hunter earns 3 points.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'GOT IT',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildRuleSection(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          body,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
