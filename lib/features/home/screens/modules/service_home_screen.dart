import 'package:flutter/material.dart';
import 'package:sixam_mart/features/home/widgets/views/banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/promo_code_banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/promotional_banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/service_catalog_grid_view.dart';
import 'package:sixam_mart/features/home/widgets/views/visit_again_view.dart';
import 'package:sixam_mart/helper/auth_helper.dart';

/// Home screen for the `service` module (plumbing, electrician, AC repair, etc.).
///
/// Browsing anchors on the service catalog, not on providers: the grid of service
/// groups (GET /services/catalog/services) is the single entry point — tapping a
/// group opens its categories, a category opens its bookable services. Stores and
/// item rails are deliberately absent; the provider behind a service is assigned
/// by the backend and never part of choosing what to book.
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

      // Service groups: Women's Salon, Cleaning, AC & Appliance Repair, ...
      const ServiceCatalogGridView(),

      // Rebook what was booked before.
      isLoggedIn ? const VisitAgainView() : const SizedBox(),

      isLoggedIn ? const PromoCodeBannerView() : const SizedBox(),
      const PromotionalBannerView(),
    ]);
  }
}
