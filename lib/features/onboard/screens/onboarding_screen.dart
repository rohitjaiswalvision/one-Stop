import 'package:sixam_mart/common/widgets/premium/premium_button.dart';
import 'package:sixam_mart/common/widgets/premium/premium_motion.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/onboard/controllers/onboard_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/theme/premium_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();

    Get.find<OnBoardingController>().getOnBoardingList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
      body: SafeArea(
        child: GetBuilder<OnBoardingController>(
          builder: (onBoardingController) {
            bool showIndicatorAndButton = onBoardingController.selectedIndex < onBoardingController.onBoardingList.length-1;
            return onBoardingController.onBoardingList.isNotEmpty ? SafeArea(
              child: Center(child: SizedBox(width: Dimensions.webMaxWidth, child: Column(children: [

                // Skip sits top-right, always reachable, never competing with the CTA below.
                if (showIndicatorAndButton) Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, 0,
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    onBoardingController.selectedIndex == 2 ? const SizedBox() : TextButton(
                      onPressed: _configureToRouteInitialPage,
                      child: Text('skip'.tr, style: robotoSemiBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).disabledColor,
                      )),
                    ),
                  ]),
                ),

                Expanded(child: PageView.builder(
                  itemCount: onBoardingController.onBoardingList.length,
                  controller: _pageController,
                  itemBuilder: (context, index) {
                    return FadeSlideIn(
                      key: ValueKey(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                          showIndicatorAndButton && onBoardingController.onBoardingList[index].imageUrl != '' ? Container(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraOverLarge),
                            margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraOverLarge),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                PremiumTokens.tint(context, opacity: 0.14),
                                PremiumTokens.tint(context, opacity: 0.02),
                              ]),
                            ),
                            child: Image.asset(onBoardingController.onBoardingList[index].imageUrl, height: context.height * 0.28),
                          ) : const SizedBox(),

                          Text(
                            onBoardingController.onBoardingList[index].title,
                            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge, letterSpacing: -0.3),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),

                          Text(
                            onBoardingController.onBoardingList[index].description,
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).disabledColor, height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),

                        ]),
                      ),
                    );
                  },
                  onPageChanged: (index) {
                    onBoardingController.changeSelectIndex(index);
                    if(onBoardingController.selectedIndex == 3) {
                      _configureToRouteInitialPage();
                    }
                  },
                )),

                showIndicatorAndButton ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _pageIndicators(onBoardingController, context),
                ) : const SizedBox(),
                SizedBox(height: context.height * 0.05),

                showIndicatorAndButton ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeLarge, 0, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge,
                  ),
                  child: PremiumButton(
                    key: ValueKey(onBoardingController.selectedIndex),
                    text: onBoardingController.selectedIndex != 2 ? 'next'.tr : 'get_started'.tr,
                    icon: onBoardingController.selectedIndex != 2 ? Icons.arrow_forward_rounded : null,
                    onPressed: () {
                      if(onBoardingController.selectedIndex != 2) {
                       _pageController.nextPage(duration: const Duration(seconds: 1), curve: Curves.easeInOut);
                      } else {
                        _configureToRouteInitialPage();
                      }
                    },
                  ),
                ) : const SizedBox(),

              ]))),
            ) : const SizedBox();
          },
        ),
      ),
    );
  }

  List<Widget> _pageIndicators(OnBoardingController onBoardingController, BuildContext context) {
    List<Widget> indicators = [];

    for (int i = 0; i < onBoardingController.onBoardingList.length-1; i++) {
      final bool active = i == onBoardingController.selectedIndex;
      indicators.add(
        AnimatedContainer(
          duration: PremiumTokens.medium,
          curve: PremiumTokens.easeOut,
          width: active ? 22 : 7, height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      );
    }
    return indicators;
  }

  void _configureToRouteInitialPage() async {
    Get.find<SplashController>().disableIntro();
    await Get.find<AuthController>().guestLogin();
    if (AddressHelper.getUserAddressFromSharedPref() != null) {
      Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
    } else {
      Get.find<LocationController>().navigateToLocationScreen(RouteHelper.onBoarding, offNamed: true).then((v) {
        _pageController.jumpToPage(Get.find<OnBoardingController>().onBoardingList.length-2);
      });
    }
  }
}
