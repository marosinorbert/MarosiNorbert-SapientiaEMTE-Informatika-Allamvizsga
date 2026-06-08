import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const List<_NavItem> _items = [
    _NavItem(Icons.dashboard_rounded, 'Irányítópult'),
    _NavItem(Icons.sensors_rounded, 'Szenzorok'),
    _NavItem(Icons.devices_rounded, 'Eszközök'),
    _NavItem(Icons.notifications_rounded, 'Riasztások'),
    _NavItem(Icons.receipt_long_rounded, 'Napló'),
    _NavItem(Icons.eco_rounded, 'Növények'),
    _NavItem(Icons.bar_chart_rounded, 'Statisztikák'),
    _NavItem(Icons.settings_rounded, 'Beállítások'),
    _NavItem(Icons.developer_board_rounded, 'ESP32 Integráció'),
  ];

@override
Widget build(BuildContext context) {
  final isMobile = MediaQuery.of(context).size.width < 600;
  final sidebarWidth = isMobile ? 200.0 : 220.0;
  
  return SizedBox(
    width: sidebarWidth,
    child: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        // ... rest of the code
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.eco_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
  child: RichText(
    overflow: TextOverflow.ellipsis,
    text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'GreenHouse ',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      TextSpan(
                        text: 'Pro',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 8),
          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final isSelected = selectedIndex == index;
                return _NavTile(
                  icon: item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () => onItemSelected(index),
                );
              },
            ),
          ),
          // Status
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
                    Text(
  'ESP32 Connected',
  overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
  'System running smoothly',
  overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                      ],
  ),
),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

@override
Widget build(BuildContext context) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 2),
    decoration: BoxDecoration(
      color: isSelected ? AppTheme.primaryLight : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Material(  // ← ADD THIS
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          size: 20,
        ),
        title: Text(
  label,
  overflow: TextOverflow.ellipsis,
  maxLines: 1,
          style: TextStyle(
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
}