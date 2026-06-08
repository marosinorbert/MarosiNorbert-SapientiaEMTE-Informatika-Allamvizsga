import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCard extends StatefulWidget {
  final String title;
  final String value;
  final String unit;
  final String subtitle;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.subtitle,
    required this.icon,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? AppTheme.primary.withOpacity(0.4) : AppTheme.border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
  child: Text(
    widget.title.toUpperCase(),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: AppTheme.primary, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
  fit: BoxFit.scaleDown,
  alignment: Alignment.centerLeft,
  child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: widget.value,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1,
                    ),
                  ),
                  TextSpan(
                    text: ' ${widget.unit}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}