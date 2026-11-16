import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/home_sample_data.dart';

/// One cell of the category grid: icon, name, and how many items sit in it.
class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category, this.onTap});

  final ItemCategory category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(category.icon, size: 22, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${category.count}',
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
