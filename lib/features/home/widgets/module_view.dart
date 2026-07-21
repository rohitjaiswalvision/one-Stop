import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/address_widget.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/premium/premium_motion.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_loader.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/widgets/banner_view.dart';
import 'package:sixam_mart/features/home/widgets/popular_store_view.dart';

/// Soft two-stop gradients cycled across the module tiles. Kept intentionally light so the
/// white icon chip and dark label read well on top in both light and dark themes.
const List<List<Color>> _moduleTilePalette = <List<Color>>[
  <Color>[Color(0xFFFFE9E0), Color(0xFFFFC9B3)], // peach
  <Color>[Color(0xFFE3F0FF), Color(0xFFBBD9FF)], // blue
  <Color>[Color(0xFFE6F9E9), Color(0xFFBEEFC6)], // green
  <Color>[Color(0xFFF2E9FF), Color(0xFFD8C2FF)], // purple
  <Color>[Color(0xFFFFF5DF), Color(0xFFFFE1A6)], // amber
  <Color>[Color(0xFFE0F7F7), Color(0xFFB6ECEC)], // teal
];

class ModuleView extends StatelessWidget {
  final SplashController splashController;
  const ModuleView({super.key, required this.splashController});

  @override
  Widget build(BuildContext context) {
    List<int> moduleIndices = [];
    if (splashController.moduleList != null) {
      for (int i = 0; i < splashController.moduleList!.length; i++) {
        if (splashController.moduleList![i].moduleType.toString() != AppConstants.taxi && 
            splashController.moduleList![i].moduleType.toString() != AppConstants.pharmacy) {
          moduleIndices.add(i);
        }
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      GetBuilder<BannerController>(builder: (bannerController) {
        return const BannerView(isFeatured: true);
      }),
      SizedBox(height: Dimensions.paddingSizeDefault),

      splashController.moduleList != null ? moduleIndices.isNotEmpty ? GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: Dimensions.paddingSizeDefault,
          crossAxisSpacing: Dimensions.paddingSizeDefault, childAspectRatio: (1.35),
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        itemCount: moduleIndices.length,
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          int originalIndex = moduleIndices[index];
          // Cycle a soft, deliberately light palette so the tiles stay colourful in both
          // themes; the icon sits in a white chip and the label is dark on top of the pastel.
          final List<Color> gradient = _moduleTilePalette[index % _moduleTilePalette.length];
          return FadeSlideIn(index: index, child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: gradient,
              ),
              boxShadow: [BoxShadow(
                color: gradient.last.withValues(alpha: 0.5), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 4),
              )],
            ),
            child: CustomInkWell(
              onTap: () => splashController.switchModule(originalIndex, true),
              radius: Dimensions.radiusExtraLarge,
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Row(children: [

                  Container(
                    height: 56, width: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      child: CustomImage(
                        image: '${splashController.moduleList![originalIndex].iconFullUrl}',
                        height: 44, width: 44,
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  Expanded(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        splashController.moduleList![originalIndex].moduleName!,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: const Color(0xFF2B2B2B)),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Row(children: [
                        Text(
                          'view'.tr,
                          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: const Color(0xFF2B2B2B).withValues(alpha: 0.6)),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF2B2B2B)),
                      ]),
                    ],
                  )),

                ]),
              ),
            ),
          ));
        },
      ) : Center(child: Padding(
        padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall), child: Text('no_module_found'.tr),
      )) : ModuleShimmer(isEnabled: splashController.moduleList == null),

      GetBuilder<AddressController>(builder: (locationController) {
        List<AddressModel?> addressList = [];
        if(AuthHelper.isLoggedIn() && locationController.addressList != null) {
          addressList = [];
          bool contain = false;
          if(AddressHelper.getUserAddressFromSharedPref()!.id != null) {
            for(int index=0; index<locationController.addressList!.length; index++) {
              if(locationController.addressList![index].id == AddressHelper.getUserAddressFromSharedPref()!.id) {
                contain = true;
                break;
              }
            }
          }
          if(!contain) {
            addressList.add(AddressHelper.getUserAddressFromSharedPref());
          }
          addressList.addAll(locationController.addressList!);
        }
        return (!AuthHelper.isLoggedIn() || locationController.addressList != null) ? addressList.isNotEmpty ? Column(
          children: [

            const SizedBox(height: Dimensions.paddingSizeLarge),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              child: TitleWidget(title: 'deliver_to'.tr),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            SizedBox(
              height: 80,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: addressList.length,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeExtraSmall),
                itemBuilder: (context, index) {
                  return Container(
                    width: 300,
                    padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                    child: AddressWidget(
                      address: addressList[index],
                      fromAddress: false,
                      onTap: () {
                        if(AddressHelper.getUserAddressFromSharedPref()!.id != addressList[index]!.id) {
                          Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
                          Get.find<LocationController>().saveAddressAndNavigate(
                            addressList[index], false, null, false, ResponsiveHelper.isDesktop(context),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ) : const SizedBox() : AddressShimmer(isEnabled: AuthHelper.isLoggedIn() && locationController.addressList == null);
      }),

      const PopularStoreView(isPopular: false, isFeatured: true),

      const SizedBox(height: 120),

    ]);
  }
}

class ModuleShimmer extends StatelessWidget {
  final bool isEnabled;
  const ModuleShimmer({super.key, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: Dimensions.paddingSizeSmall,
        crossAxisSpacing: Dimensions.paddingSizeSmall, childAspectRatio: (1/1),
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      itemCount: 6,
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: Theme.of(context).cardColor,
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
          ),
          child: Shimmer(
            duration: const Duration(seconds: 2),
            enabled: isEnabled,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

              Container(
                height: 50, width: 50,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusSmall), color: Colors.grey[300]),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Center(child: Container(height: 15, width: 50, color: Colors.grey[300])),

            ]),
          ),
        );
      },
    );
  }
}

class AddressShimmer extends StatelessWidget {
  final bool isEnabled;
  const AddressShimmer({super.key, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: Dimensions.paddingSizeLarge),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
          child: TitleWidget(title: 'deliver_to'.tr),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        SizedBox(
          height: 70,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: 5,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            itemBuilder: (context, index) {
              return Container(
                width: 300,
                padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                child: Container(
                  padding: EdgeInsets.all(ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeDefault
                      : Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      Icons.location_on,
                      size: ResponsiveHelper.isDesktop(context) ? 50 : 40, color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: Shimmer(
                        duration: const Duration(seconds: 2),
                        enabled: isEnabled,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(height: 15, width: 100, color: Colors.grey[300]),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                          Container(height: 10, width: 150, color: Colors.grey[300]),
                        ]),
                      ),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


