import 'package:flutter/material.dart';

import '../game/game_state_manager.dart';
import '../main.dart';

/// A shop item that can be purchased.
class ShopItem {
  final String id;
  final String name;
  final String description;
  final String emojis;
  final int price;
  final ShopCategory category;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.emojis,
    required this.price,
    required this.category,
  });
}

enum ShopCategory { theme, powerUp, movesUpgrade }

/// All available shop items.
const List<ShopItem> shopThemes = [
  ShopItem(
    id: 'theme_fruit',
    name: 'Fruit Theme',
    description: 'Classic fruit emojis',
    emojis: '🍎🍊🍋',
    price: 0,
    category: ShopCategory.theme,
  ),
  ShopItem(
    id: 'theme_animals',
    name: 'Animal Theme',
    description: 'Cute animal emojis',
    emojis: '🐱🐶🐰🦊🐼🐨',
    price: 500,
    category: ShopCategory.theme,
  ),
  ShopItem(
    id: 'theme_space',
    name: 'Space Theme',
    description: 'Cosmic space emojis',
    emojis: '🚀🌙⭐💫🪐☄️',
    price: 1000,
    category: ShopCategory.theme,
  ),
];

const List<ShopItem> shopPowerUps = [
  ShopItem(
    id: 'powerup_extra_moves',
    name: 'Extra Moves (20)',
    description: '\uD83D\uDC8A +20 Zuege im Spiel aktivieren',
    emojis: '\uD83D\uDC8A',
    price: 200,
    category: ShopCategory.powerUp,
  ),
  ShopItem(
    id: 'powerup_mega_moves',
    name: 'Mega Moves (60)',
    description: '\uD83D\uDC8A +60 Zuege im Spiel aktivieren',
    emojis: '\uD83D\uDC8A',
    price: 350,
    category: ShopCategory.powerUp,
  ),
  ShopItem(
    id: 'powerup_shuffle',
    name: 'Shuffle',
    description: 'Shuffle the board',
    emojis: '🔀',
    price: 150,
    category: ShopCategory.powerUp,
  ),
  ShopItem(
    id: 'powerup_color_bomb',
    name: 'Color Bomb',
    description: 'Destroy all of one color',
    emojis: '💣🌈',
    price: 300,
    category: ShopCategory.powerUp,
  ),
];

/// Instant moves that are added directly to bonusMoves.
class InstantMovesItem {
  final String id;
  final String name;
  final String description;
  final String emojis;
  final int price;
  final int movesAmount;

  const InstantMovesItem({
    required this.id,
    required this.name,
    required this.description,
    required this.emojis,
    required this.price,
    required this.movesAmount,
  });
}

const List<InstantMovesItem> shopInstantMoves = [
  InstantMovesItem(
    id: 'instant_moves_20',
    name: '20 Zuege',
    description: 'Sofort +20 Zuege',
    emojis: '🚶',
    price: 100,
    movesAmount: 20,
  ),
  InstantMovesItem(
    id: 'instant_moves_60',
    name: '60 Zuege',
    description: 'Sofort +60 Zuege',
    emojis: '🏃',
    price: 300,
    movesAmount: 60,
  ),
];

/// Upgrade packages for the moves maximum.
class MovesUpgradeItem {
  final String id;
  final String name;
  final String description;
  final String emojis;
  final int price;
  final int targetMaxMoves;

  const MovesUpgradeItem({
    required this.id,
    required this.name,
    required this.description,
    required this.emojis,
    required this.price,
    required this.targetMaxMoves,
  });
}

const List<MovesUpgradeItem> shopMovesUpgrades = [
  MovesUpgradeItem(
    id: 'moves_upgrade_150',
    name: 'Zuege-Maximum 150',
    description: 'Maximum von 60 auf 150 Zuege erhoehen',
    emojis: '🦶',
    price: 1000,
    targetMaxMoves: 150,
  ),
  MovesUpgradeItem(
    id: 'moves_upgrade_400',
    name: 'Zuege-Maximum 400',
    description: 'Maximum auf 400 Zuege erhoehen',
    emojis: '🏃',
    price: 2000,
    targetMaxMoves: 400,
  ),
  MovesUpgradeItem(
    id: 'moves_upgrade_999',
    name: 'Zuege-Maximum 999',
    description: 'Maximum auf 999 Zuege erhoehen',
    emojis: '🚀',
    price: 5000,
    targetMaxMoves: 999,
  ),
];

/// Shop screen with themes and power-ups purchasable with coins.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gsm = GameStateManagerProvider.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'Shop',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: gsm,
        builder: (context, _) {
          return Column(
            children: [
              _buildCoinBalance(gsm),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSectionHeader('Emoji Themes'),
                    const SizedBox(height: 8),
                    ...shopThemes
                        .map((item) => _buildShopCard(context, gsm, item)),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Zuege-Upgrades'),
                    const SizedBox(height: 8),
                    ...shopMovesUpgrades
                        .map((item) => _buildMovesUpgradeCard(context, gsm, item)),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Zuege kaufen'),
                    const SizedBox(height: 8),
                    ...shopInstantMoves
                        .map((item) => _buildInstantMovesCard(context, gsm, item)),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Power-Ups'),
                    const SizedBox(height: 8),
                    ...shopPowerUps
                        .map((item) => _buildShopCard(context, gsm, item)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCoinBalance(GameStateManager gsm) {
    return Container(
      key: const Key('coin_balance'),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      color: const Color(0xFF16213e),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            '${gsm.coins}',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Coins',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  void _purchaseItem(BuildContext context, GameStateManager gsm, ShopItem item) {
    // Free items unlock immediately
    if (item.price == 0) {
      gsm.saveState.unlockExtra(item.id);
      gsm.persistState();
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: Text(
          'Buy ${item.name}?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Spend ${item.price} coins on ${item.name}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirm_purchase'),
            onPressed: () {
              Navigator.pop(ctx);
              _executePurchase(context, gsm, item);
            },
            child: const Text('Buy'),
          ),
        ],
      ),
    );
  }

  void _executePurchase(BuildContext context, GameStateManager gsm, ShopItem item) {
    if (gsm.spendCoins(item.price)) {
      if (item.category == ShopCategory.powerUp) {
        gsm.saveState.addPowerUp(item.id);
      } else {
        gsm.saveState.unlockExtra(item.id);
      }
      gsm.persistState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} purchased!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough coins!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _purchaseInstantMoves(BuildContext context, GameStateManager gsm, InstantMovesItem item) {
    final save = gsm.saveState;
    final currentMoves = save.bonusMoves;
    final maxMoves = save.maxBonusMoves;
    final space = maxMoves - currentMoves;
    final effective = item.movesAmount.clamp(0, space);
    final wasted = item.movesAmount - effective;

    if (wasted > 0 && effective > 0) {
      // Warn that some moves will be lost
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF16213e),
          title: const Text('Achtung', style: TextStyle(color: Colors.white)),
          content: Text(
            'Du hast nur Platz fuer $effective Zuege (aktuell $currentMoves/$maxMoves). '
            '$wasted Zuege wuerden verfallen. Trotzdem kaufen?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              key: Key('confirm_purchase_${item.id}'),
              onPressed: () {
                Navigator.pop(ctx);
                _executeInstantMovesPurchase(context, gsm, item, effective);
              },
              child: const Text('Trotzdem kaufen'),
            ),
          ],
        ),
      );
    } else {
      // Normal confirmation
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF16213e),
          title: Text(
            '${item.name} kaufen?',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            '${item.price} Muenzen fuer ${item.movesAmount} Zuege ausgeben?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              key: Key('confirm_purchase_${item.id}'),
              onPressed: () {
                Navigator.pop(ctx);
                _executeInstantMovesPurchase(context, gsm, item, effective);
              },
              child: const Text('Kaufen'),
            ),
          ],
        ),
      );
    }
  }

  void _executeInstantMovesPurchase(
      BuildContext context, GameStateManager gsm, InstantMovesItem item, int effective) {
    if (gsm.spendCoins(item.price)) {
      gsm.saveState.bonusMoves =
          (gsm.saveState.bonusMoves + effective).clamp(0, gsm.saveState.maxBonusMoves);
      gsm.persistState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+$effective Zuege!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nicht genug Muenzen!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildInstantMovesCard(BuildContext context, GameStateManager gsm, InstantMovesItem item) {
    final currentMoves = gsm.saveState.bonusMoves;
    final maxMoves = gsm.saveState.maxBonusMoves;
    final isFull = currentMoves >= maxMoves;
    final canAfford = gsm.coins >= item.price;
    final enabled = !isFull && canAfford;

    return Card(
      key: Key('shop_item_${item.id}'),
      color: const Color(0xFF16213e),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(item.emojis, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Aktuell: $currentMoves/$maxMoves',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isFull)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Voll',
                  style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold),
                ),
              )
            else
              GestureDetector(
                onTap: enabled ? () => _purchaseInstantMoves(context, gsm, item) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: canAfford
                        ? Colors.amber.withValues(alpha: 0.8)
                        : Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('\uD83E\uDE99', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '${item.price}',
                        style: TextStyle(
                          color: canAfford ? Colors.black87 : Colors.white38,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _purchaseMovesUpgrade(BuildContext context, GameStateManager gsm, MovesUpgradeItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: Text(
          '${item.name} kaufen?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          '${item.price} Muenzen ausgeben fuer ${item.name}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            key: Key('confirm_purchase_${item.id}'),
            onPressed: () {
              Navigator.pop(ctx);
              if (gsm.spendCoins(item.price)) {
                gsm.saveState.maxBonusMoves = item.targetMaxMoves;
                gsm.persistState();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} gekauft!'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nicht genug Muenzen!'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Kaufen'),
          ),
        ],
      ),
    );
  }

  Widget _buildMovesUpgradeCard(BuildContext context, GameStateManager gsm, MovesUpgradeItem item) {
    final purchased = gsm.saveState.maxBonusMoves >= item.targetMaxMoves;
    final canAfford = gsm.coins >= item.price;

    return Card(
      key: Key('shop_item_${item.id}'),
      color: const Color(0xFF16213e),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: purchased
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.white12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                item.emojis,
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (purchased)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Gekauft',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () => _purchaseMovesUpgrade(context, gsm, item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: canAfford
                        ? Colors.amber.withValues(alpha: 0.8)
                        : Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '${item.price}',
                        style: TextStyle(
                          color: canAfford ? Colors.black87 : Colors.white38,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard(BuildContext context, GameStateManager gsm, ShopItem item) {
    final isTheme = item.category == ShopCategory.theme;
    final isPowerUp = item.category == ShopCategory.powerUp;
    final owned = isTheme && (item.id == 'theme_fruit' ||
        gsm.saveState.isExtraUnlocked(item.id));
    final isActive = isTheme && gsm.selectedThemeId == item.id;
    final canAfford = gsm.coins >= item.price;
    final powerUpCount = isPowerUp ? gsm.saveState.powerUpCount(item.id) : 0;

    return Card(
      key: Key('shop_item_${item.id}'),
      color: const Color(0xFF16213e),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive
              ? Colors.green.withValues(alpha: 0.7)
              : owned
                  ? Colors.green.withValues(alpha: 0.5)
                  : Colors.white12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Emoji preview
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                item.emojis.characters.first,
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(width: 12),

            // Name and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (isPowerUp && powerUpCount > 0)
                    Text(
                      'Inventar: $powerUpCount',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    Text(
                      item.emojis,
                      style: const TextStyle(fontSize: 14),
                    ),
                ],
              ),
            ),

            // Action button
            if (isTheme && owned && isActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Active \u2713',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (isTheme && owned && !isActive)
              GestureDetector(
                onTap: () {
                  gsm.setTheme(item.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Theme activated! \u{1F3A8}'),
                      backgroundColor: Colors.deepPurple,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  key: Key('use_theme_${item.id}'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.deepPurple, Colors.blueAccent],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Use',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else if (owned)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Owned',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (item.price == 0)
              GestureDetector(
                onTap: () => _purchaseItem(context, gsm, item),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Free',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () => _purchaseItem(context, gsm, item),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: canAfford
                        ? Colors.amber.withValues(alpha: 0.8)
                        : Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '${item.price}',
                        style: TextStyle(
                          color: canAfford ? Colors.black87 : Colors.white38,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
