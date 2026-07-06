import 'package:flutter/material.dart';
import 'package:sixam_mart/features/home/widgets/views/banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/best_reviewed_item_view.dart';
import 'package:sixam_mart/features/home/widgets/views/best_store_nearby_view.dart';
import 'package:sixam_mart/features/home/widgets/views/category_view.dart';
import 'package:sixam_mart/features/home/widgets/views/most_popular_item_view.dart';
import 'package:sixam_mart/features/home/widgets/views/promo_code_banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/promotional_banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/recommended_store_view.dart';
import 'package:sixam_mart/features/home/widgets/views/top_offers_near_me.dart';
import 'package:sixam_mart/features/home/widgets/views/visit_again_view.dart';
import 'package:sixam_mart/helper/auth_helper.dart';

/// Home screen for the `service` module (plumbing, electrician, AC repair, etc.).
///
/// Reuses the shared catalog widgets — a "store" is a service provider and an
/// "item" is a bookable service — so the Provider → Service → Cart → Checkout →
/// Booking flow is identical to the other catalog modules. Only the curated
/// sections shown here differ; the trade categories come straight from
/// [CategoryView] (the module's categories on the backend).
class ServiceHomeScreen extends StatelessWidget {
  const ServiceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = AuthHelper.isLoggedIn();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Container(
        width: MediaQuery.of(context).size.width,
        color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
        child: const Column(
          children: [
            BannerView(isFeatured: false),
            SizedBox(height: 12),
          ],
        ),
      ),

      // Trade categories: Plumbing, Electrician, AC Repair, Cleaning, ...
      const CategoryView(),

      isLoggedIn ? const VisitAgainView() : const SizedBox(),

      // Providers (stores) in the customer's service zone.
      const RecommendedStoreView(),
      const BestStoreNearbyView(),

      // Popular / most-reviewed services (items).
      const MostPopularItemView(isFood: false, isShop: false),
      const BestReviewItemView(),
      const TopOffersNearMe(),

      isLoggedIn ? const PromoCodeBannerView() : const SizedBox(),
      const PromotionalBannerView(),
    ]);
  }
}
