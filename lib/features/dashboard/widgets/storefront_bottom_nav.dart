import 'package:flutter/material.dart';
import 'package:sixam_mart/features/home/widgets/storefront/storefront_tokens.dart';
import 'package:sixam_mart/util/styles.dart';

/// One destination in [StorefrontBottomNav].
///
/// [pageIndex] is null for a destination that pushes a route instead of swapping
/// the dashboard page, which is why selection can't be inferred from position.
///
/// [iconBuilder] receives the resolved tint and the selected state, so a tab can
/// answer with a Material glyph, a painted one, or something that ignores the
/// tint entirely (the assistant face keeps its yellow either way).
class StorefrontNavItem {
  final Widget Function(Color color, bool isSelected) iconBuilder;
  final String label;
  final int? pageIndex;
  final VoidCallback onTap;

  /// Count bubble on the glyph — drawn only when greater than zero.
  final int badgeCount;

  /// Small unread marker, for destinations that have news but nothing to count.
  final bool showDot;

  const StorefrontNavItem({
    required this.iconBuilder, required this.label, required this.onTap,
    this.pageIndex, this.badgeCount = 0, this.showDot = false,
  });

  /// Convenience for the ordinary case: a Material glyph that fills when active.
  factory StorefrontNavItem.material({
    required IconData icon, required IconData activeIcon, required String label,
    required VoidCallback onTap, int? pageIndex, int badgeCount = 0, bool showDot = false,
  }) {
    return StorefrontNavItem(
      label: label, onTap: onTap, pageIndex: pageIndex, badgeCount: badgeCount, showDot: showDot,
      iconBuilder: (Color color, bool isSelected) => Icon(isSelected ? activeIcon : icon, size: 25, color: color),
    );
  }
}

/// Flat storefront tab bar: a hairline over a white strip, five evenly spaced
/// destinations, brand blue for the active one and near-black for the rest.
///
/// No notch and no floating button — every destination is a plain tab, so the
/// bar stays one uninterrupted surface.
class StorefrontBottomNav extends StatelessWidget {
  final List<StorefrontNavItem> items;
  final int currentIndex;
  final double height;

  const StorefrontBottomNav({super.key, required this.items, required this.currentIndex, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: StorefrontTokens.hairline(context))),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for(final StorefrontNavItem item in items) Expanded(child: _tab(context, item)),
      ]),
    );
  }

  Widget _tab(BuildContext context, StorefrontNavItem item) {
    final bool isSelected = item.pageIndex != null && item.pageIndex == currentIndex;
    final Color color = isSelected ? StorefrontTokens.blue : StorefrontTokens.navInk(context);

    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          SizedBox(
            height: 25,
            child: Stack(clipBehavior: Clip.none, children: [
              item.iconBuilder(color, isSelected),

              if(item.badgeCount > 0) Positioned(
                top: -5, right: -9,
                child: Container(
                  height: 16, width: 16, alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error, shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).cardColor, width: 1.5),
                  ),
                  child: Text(
                    item.badgeCount > 9 ? '9+' : '${item.badgeCount}',
                    style: robotoBold.copyWith(fontSize: 8, color: Colors.white),
                  ),
                ),
              ),

              if(item.showDot && item.badgeCount == 0) Positioned(
                top: -1, right: -2,
                child: Container(
                  height: 9, width: 9,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error, shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).cardColor, width: 1.5),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 4),

          Text(
            item.label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            style: (isSelected ? robotoMedium : robotoRegular).copyWith(fontSize: 11, color: color),
          ),
        ]),
      ),
    );
  }
}
