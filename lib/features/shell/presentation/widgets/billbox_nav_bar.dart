import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The four tabs the shell can show.
enum ShellTab { home, reminders, search, account }

/// BillBox's bottom bar: a floating capsule where the selected tab grows into
/// a tinted pill with its label while the rest stay icon-only, and the add
/// action sits in the bar itself rather than on a separate floating button.
class BillBoxNavBar extends StatelessWidget {
  const BillBoxNavBar({
    super.key,
    required this.current,
    required this.onSelect,
    required this.onAdd,
  });

  final ShellTab current;
  final ValueChanged<ShellTab> onSelect;
  final VoidCallback onAdd;

  static const List<_Destination> _destinations = <_Destination>[
    _Destination(
      tab: ShellTab.home,
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _Destination(
      tab: ShellTab.reminders,
      label: 'Reminders',
      icon: Icons.notifications_none_rounded,
      activeIcon: Icons.notifications_rounded,
    ),
    _Destination(
      tab: ShellTab.search,
      label: 'Search',
      icon: Icons.search_rounded,
      activeIcon: Icons.search_rounded,
    ),
    _Destination(
      tab: ShellTab.account,
      label: 'Account',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A002828),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  for (final destination in _destinations)
                    Expanded(
                      // The selected pill carries a label, so it is given
                      // twice the room of an icon-only tab.
                      flex: destination.tab == current ? 2 : 1,
                      child: _NavTab(
                        destination: destination,
                        selected: destination.tab == current,
                        onTap: () => onSelect(destination.tab),
                      ),
                    ),
                  const SizedBox(width: 6),
                  _AddButton(onTap: onAdd),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.tab,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final ShellTab tab;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Tooltip(
        message: destination.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? destination.activeIcon : destination.icon,
                  size: 22,
                  color: foreground,
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: 'Add a bill or document',
      child: Material(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.add_rounded, size: 26, color: scheme.onPrimary),
          ),
        ),
      ),
    );
  }
}
