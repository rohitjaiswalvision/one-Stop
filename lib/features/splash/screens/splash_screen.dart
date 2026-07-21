import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/theme/premium_tokens.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/no_internet_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  final NotificationBodyModel? body;
  final String? deeplinkUrl;
  const SplashScreen({super.key, required this.body, required this.deeplinkUrl});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _globalKey = GlobalKey();
  StreamSubscription<List<ConnectivityResult>>? _onConnectivityChanged;
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(vsync: this, duration: PremiumTokens.slow);
    _logoScale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: PremiumTokens.easeSpring),
    );
    _logoFade = CurvedAnimation(parent: _logoController, curve: PremiumTokens.easeOut);
    _logoController.forward();

    bool firstTime = true;
    _onConnectivityChanged = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      bool isConnected = result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.mobile);

      if(!firstTime) {
        isConnected ? ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar() : const SizedBox();
        ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
          backgroundColor: isConnected ? Colors.green : Colors.red,
          duration: Duration(seconds: isConnected ? 3 : 6000),
          content: Text(isConnected ? 'connected'.tr : 'no_connection'.tr, textAlign: TextAlign.center),
        ));
        if(isConnected) {
          print('=========here coming-----1-->> ${Get.find<SplashController>().deeplinkRoute}');
          if(Get.find<SplashController>().deeplinkRoute == null) {
            Get.find<SplashController>().getConfigData(notificationBody: widget.body);
          }
        }
      }

      firstTime = false;
    });

    Get.find<SplashController>().initSharedData();
    if((AuthHelper.getGuestId().isNotEmpty || AuthHelper.isLoggedIn()) && Get.find<SplashController>().cacheModule != null) {
      Get.find<CartController>().getCartDataOnline();
    }
    // _route();
    print('=========here coming-----2-->> ${Get.find<SplashController>().deeplinkRoute == null}');
    if(Get.find<SplashController>().deeplinkRoute == null) {
      Get.find<SplashController>().getConfigData(notificationBody: widget.body);
    }
  }

  @override
  void dispose() {
    super.dispose();

    _onConnectivityChanged?.cancel();
    _logoController.dispose();
  }

  // void _route() {
  //   Get.find<SplashController>().getConfigData().then((isSuccess) {
  //     if(isSuccess) {
  //       Timer(const Duration(seconds: 1), () async {
  //         double? minimumVersion = _getMinimumVersion();
  //         bool isMaintenanceMode = Get.find<SplashController>().configModel!.maintenanceMode!;
  //         bool needsUpdate = AppConstants.appVersion < minimumVersion!;
  //
  //         if(needsUpdate || isMaintenanceMode) {
  //           Get.offNamed(RouteHelper.getUpdateRoute(needsUpdate));
  //         }else {
  //           if(widget.body != null) {
  //             _forNotificationRouteProcess(widget.body);
  //           }else {
  //             _handleUserRouting();
  //           }
  //         }
  //       });
  //     }
  //   });
  // }
  //
  // double? _getMinimumVersion() {
  //   if (GetPlatform.isAndroid) {
  //     return Get.find<SplashController>().configModel!.appMinimumVersionAndroid;
  //   } else if (GetPlatform.isIOS) {
  //     return Get.find<SplashController>().configModel!.appMinimumVersionIos;
  //   }
  //   return 0;
  // }
  //
  // void _forNotificationRouteProcess(NotificationBodyModel? notificationBody) {
  //   final notificationType = notificationBody?.notificationType;
  //
  //   final Map<NotificationType, Function> notificationActions = {
  //     NotificationType.order: () => Get.toNamed(RouteHelper.getOrderDetailsRoute(widget.body!.orderId, fromNotification: true)),
  //     NotificationType.block: () => Get.offNamed(RouteHelper.getSignInRoute(RouteHelper.notification)),
  //     NotificationType.unblock: () => Get.offNamed(RouteHelper.getSignInRoute(RouteHelper.notification)),
  //     NotificationType.message: () =>  Get.toNamed(RouteHelper.getChatRoute(notificationBody: widget.body, conversationID: widget.body!.conversationId, fromNotification: true)),
  //     NotificationType.otp: () => null,
  //     NotificationType.add_fund: () => Get.toNamed(RouteHelper.getWalletRoute(fromNotification: true)),
  //     NotificationType.referral_earn: () => Get.toNamed(RouteHelper.getWalletRoute(fromNotification: true)),
  //     NotificationType.cashback: () => Get.toNamed(RouteHelper.getWalletRoute(fromNotification: true)),
  //     NotificationType.loyalty_point: () => Get.toNamed(RouteHelper.getLoyaltyRoute(fromNotification: true)),
  //     NotificationType.general: () => Get.toNamed(RouteHelper.getNotificationRoute(fromNotification: true)),
  //   };
  //
  //   notificationActions[notificationType]?.call();
  // }
  //
  // Future<void> _forLoggedInUserRouteProcess() async {
  //   Get.find<AuthController>().updateToken();
  //   if (AddressHelper.getUserAddressFromSharedPref() != null) {
  //     if(Get.find<SplashController>().module != null) {
  //       await Get.find<FavouriteController>().getFavouriteList();
  //     }
  //     Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
  //   } else {
  //     Get.find<LocationController>().navigateToLocationScreen('splash', offNamed: true);
  //   }
  // }
  //
  // void _newlyRegisteredRouteProcess() {
  //   if(AppConstants.languages.length > 1) {
  //     Get.offNamed(RouteHelper.getLanguageRoute('splash'));
  //   }else {
  //     Get.offNamed(RouteHelper.getOnBoardingRoute());
  //   }
  // }
  //
  // void _forGuestUserRouteProcess() {
  //   if (AddressHelper.getUserAddressFromSharedPref() != null) {
  //     Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
  //   } else {
  //     Get.find<LocationController>().navigateToLocationScreen('splash', offNamed: true);
  //   }
  // }
  //
  // Future<void> _handleUserRouting() async {
  //   if (AuthHelper.isLoggedIn()) {
  //     _forLoggedInUserRouteProcess();
  //   } else if (Get.find<SplashController>().showIntro() == true) {
  //     _newlyRegisteredRouteProcess();
  //   } else if (AuthHelper.isGuestLoggedIn()) {
  //     _forGuestUserRouteProcess();
  //   } else {
  //     await Get.find<AuthController>().guestLogin();
  //     _forGuestUserRouteProcess();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    Get.find<SplashController>().initSharedData();
    if(AddressHelper.getUserAddressFromSharedPref() != null && AddressHelper.getUserAddressFromSharedPref()!.zoneIds == null) {
      Get.find<AuthController>().clearSharedAddress();
    }

    return Scaffold(
      key: _globalKey,
      body: GetBuilder<SplashController>(builder: (splashController) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.4,
              colors: [
                PremiumTokens.tint(context, opacity: 0.14),
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
          child: Center(
            child: splashController.hasConnection ? FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).cardColor,
                        boxShadow: PremiumTokens.softShadow(context, strength: 1.4),
                      ),
                      child: Image.asset(Images.logo, width: 132),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraOverLarge),

                    Text(
                      AppConstants.appName,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeOverLarge,
                        letterSpacing: 0.5,
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                    const _PulsingDot(),
                  ],
                ),
              ),
            ) : NoInternetScreen(child: SplashScreen(body: widget.body, deeplinkUrl: widget.deeplinkUrl)),
          ),
        );
      }),
    );
  }
}

/// Understated loading indicator — three softly pulsing dots instead of a
/// spinner, so the splash reads as calm rather than "working hard".
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (index) {
          final double phase = (_controller.value - (index * 0.18)) % 1.0;
          final double opacity = 0.25 + (0.75 * (0.5 + 0.5 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2)));
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withValues(alpha: opacity.clamp(0.25, 1.0)),
              ),
            ),
          );
        }));
      },
    );
  }
}
