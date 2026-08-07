import 'dart:async';
import 'dart:io';
import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';
import 'package:flutter/services.dart';
import 'package:sixam_mart/common/models/ongoing_order_model.dart';
import 'package:sixam_mart/common/widgets/login_suggestion_bottomsheet.dart';
import 'package:sixam_mart/features/dashboard/widgets/payment_incomplete_bottomsheet.dart';
import 'package:sixam_mart/features/dashboard/widgets/store_registration_success_bottom_sheet.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/ride_share_module/offer/screens/offer_screen.dart';
import 'package:sixam_mart/features/ride_share_module/ride_home/widgets/login_warning_dialog.dart';
import 'package:sixam_mart/features/ride_share_module/ride_order/controllers/ride_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/address/screens/address_screen.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/dashboard/widgets/storefront_bottom_nav.dart';
import 'package:sixam_mart/features/dashboard/widgets/storefront_nav_icons.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/taxi_cart_screen.dart';
import 'package:sixam_mart/features/rental_module/rental_favourite/screens/vehicle_favourite_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/taxi_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/checkout/widgets/congratulation_dialogue.dart';
import 'package:sixam_mart/features/dashboard/widgets/address_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/dashboard/widgets/parcel_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/favourite/screens/favourite_screen.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';
import 'package:sixam_mart/features/menu/screens/menu_screen.dart';
import 'package:sixam_mart/features/order/screens/order_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/running_order_view_widget.dart';

class DashboardScreen extends StatefulWidget {
  final int pageIndex;
  final int? rideOfferIndex;
  final bool fromSplash;
  const DashboardScreen({super.key, required this.pageIndex, this.fromSplash = false, this.rideOfferIndex = 0});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  PageController? _pageController;
  int _pageIndex = 0;
  late List<Widget> _screens;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey();
  bool _canExit = GetPlatform.isWeb ? true : false;

  GlobalKey<ExpandableBottomSheetState> key = GlobalKey();


  late bool _isLogin;
  bool active = false;

  @override
  void initState() {
    super.initState();

    _isLogin = AuthHelper.isLoggedIn();

    _showRegistrationSuccessBottomSheet();
    _showUserRegistrationSuccessMessage();
    if(!_isLogin && Get.find<SplashController>().showLoginSuggestion() && (GetPlatform.isAndroid || GetPlatform.isIOS)) {
      Future.delayed(const Duration(milliseconds: 3000), () {
        Get.bottomSheet(LoginSuggestionBottomSheet(), isScrollControlled: true).then((v) {
          Get.find<SplashController>().disableLoginSuggestion();
        });
      });
    }

    if(_isLogin){
      if(Get.find<SplashController>().configModel!.loyaltyPointStatus == 1 && Get.find<AuthController>().getEarningPint().isNotEmpty
          && !ResponsiveHelper.isDesktop(Get.context)){
        Future.delayed(const Duration(seconds: 1), () => showAnimatedDialog(Get.context!, const CongratulationDialogue()));
      }
      suggestAddressBottomSheet();
      // Get.find<OrderController>().getRunningOrders(1, fromDashboard: true);
      Get.find<OrderController>().getDashboardOrders();

      Get.find<SplashController>().getPaymentIncompleteSheetStatus();
      if((Get.find<SplashController>().showPaymentIncompleteBottomSheet && !GetPlatform.isWeb) || (GetPlatform.isWeb && !Get.find<SplashController>().getPaymentIncompleteSheetStatus())) {
        Get.find<OrderController>().getPaymentFailedDetails(null).then((paymentModel) {
          if (paymentModel != null) {
            if(ResponsiveHelper.isDesktop(Get.context)) {
              Get.dialog(Center(child: PaymentIncompleteBottomSheet(paymentModel: paymentModel, fromHome: true)));
            } else {
              Get.bottomSheet(PaymentIncompleteBottomSheet(paymentModel: paymentModel, fromHome: true), isScrollControlled: true);
            }
          }
        });
      }
    }

    _pageIndex = widget.pageIndex;

    _pageController = PageController(initialPage: widget.pageIndex);

    _screens = [
      const HomeScreen(),
      const FavouriteScreen(),
      const SizedBox(),
      const OrderScreen(),
      const MenuScreen()
    ];
  }

  /// Greets a freshly registered customer once they actually land inside the app.
  /// The flag is written by the sign-up flow (sign_up_widget._handleResponse) and
  /// cleared here so the message shows exactly once.
  void _showUserRegistrationSuccessMessage() {
    if(_isLogin && Get.find<HomeController>().getUserRegistrationSuccessfulSharedPref()) {
      Future.delayed(const Duration(seconds: 1), () {
        showCustomSnackBar('registration_successful'.tr, isError: false);
        Get.find<HomeController>().saveUserRegistrationSuccessfulSharedPref(false);
      });
    }
  }

  void _showRegistrationSuccessBottomSheet() {
    bool canShowBottomSheet = Get.find<HomeController>().getRegistrationSuccessfulSharedPref();
    if(canShowBottomSheet) {
      Future.delayed(const Duration(seconds: 1), () {
        ResponsiveHelper.isDesktop(Get.context) ? Get.dialog(const Dialog(child: StoreRegistrationSuccessBottomSheet())).then((value) {
          Get.find<HomeController>().saveRegistrationSuccessfulSharedPref(false);
          Get.find<HomeController>().saveIsStoreRegistrationSharedPref(false);
          setState(() {});
        }) : showModalBottomSheet(
          context: Get.context!, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (con) => const StoreRegistrationSuccessBottomSheet(),
        ).then((value) {
          Get.find<HomeController>().saveRegistrationSuccessfulSharedPref(false);
          Get.find<HomeController>().saveIsStoreRegistrationSharedPref(false);
          setState(() {});
        });
      });
    }
  }

  Future<void> suggestAddressBottomSheet() async {
    active = await Get.find<LocationController>().checkLocationActive();
    if(widget.fromSplash && Get.find<LocationController>().showLocationSuggestion && active) {
      Future.delayed(const Duration(seconds: 1), () {
        showModalBottomSheet(
          context: Get.context!, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (con) => const AddressBottomSheetWidget(),
        ).then((value) {
          Get.find<LocationController>().showSuggestedLocation(false);
          setState(() {});
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
    return GetBuilder<SplashController>(
      builder: (splashController) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (_pageIndex != 0) {
              _setPage(0);
            } else {
              if(!ResponsiveHelper.isDesktop(context) && Get.find<SplashController>().module != null && Get.find<SplashController>().configModel!.module == null && splashController.moduleList != null && splashController.moduleList!.length != 1) {
                // Get.find<SplashController>().setModule(null);
                splashController.removeModule();
                Get.find<StoreController>().resetStoreData();
              }else {
                if(_canExit) {
                  if (GetPlatform.isAndroid) {
                    SystemNavigator.pop();
                  } else if (GetPlatform.isIOS) {
                    exit(0);
                  }
                }else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('back_press_again_to_exit'.tr, style: const TextStyle(color: Colors.white)),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                    margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  ));
                  _canExit = true;
                  Timer(const Duration(seconds: 2), () {
                    _canExit = false;
                  });
                }
              }
            }
          },
          child: GetBuilder<OrderController>(
            builder: (orderController) {
              // List<OrderModel> runningOrder = orderController.runningOrderModel != null ? orderController.runningOrderModel!.orders! : [];
              List<OrderData> runningOrder = orderController.ongoingOrderModel != null ? orderController.ongoingOrderModel!.data! : [];

              // List<OrderData> reversOrder =  List.from(runningOrder.reversed);

              return SafeArea(
                top: false, bottom: GetPlatform.isAndroid,
                child: Scaffold(
                  key: _scaffoldKey,
                  body: ExpandableBottomSheet(
                    background: Stack(children: [
                      PageView.builder(
                          controller: _pageController,
                          itemCount: _screens.length,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return _screens[index];
                          },
                        ),

                        ResponsiveHelper.isDesktop(context) || keyboardVisible ? const SizedBox() : Align(
                          alignment: Alignment.bottomCenter,
                          child: GetBuilder<SplashController>(
                            builder: (splashController) {
                              bool isParcel = splashController.module != null && splashController.configModel!.moduleConfig!.module!.isParcel!;
                              bool isTaxiWithCache = ((splashController.module != null && splashController.module!.moduleType.toString() == AppConstants.taxi) || (splashController.cacheModule != null && splashController.cacheModule!.moduleType.toString() == AppConstants.taxi)) && TaxiHelper.haveTaxiModule();
                              bool isTaxi = (splashController.module != null && splashController.module!.moduleType.toString() == AppConstants.taxi);
                              bool isRide = (splashController.module != null && splashController.module!.moduleType.toString() == AppConstants.ride);
                              isParcel = isParcel && !isTaxiWithCache;

                              _screens = [
                                const HomeScreen(),
                                isParcel ? const AddressScreen(fromDashboard: true)
                                    : isTaxi ? const VehicleFavouriteScreen()
                                    : isRide ? OrderScreen(index: isTaxi ? 'trips' : 'rides')
                                    : const FavouriteScreen(),
                                const SizedBox(),
                                isRide ? OfferScreen(selectedIndex: widget.rideOfferIndex) : OrderScreen(index: isTaxi ? 'trips' : 'orders'),
                                const MenuScreen()
                              ];
                              // Storefront tab bar: flat strip, cart as a plain
                              // destination rather than a floating button. Hidden
                              // while the address suggestion or the running-order
                              // sheet owns the bottom of the screen.
                              final bool hideNav = ResponsiveHelper.isDesktop(context)
                                  || (widget.fromSplash && Get.find<LocationController>().showLocationSuggestion && active)
                                  || (orderController.showBottomSheet && orderController.runningOrderModel != null
                                      && orderController.runningOrderModel!.orders!.isNotEmpty && _isLogin);

                              if(hideNav) {
                                return SizedBox(width: size.width, height: GetPlatform.isIOS ? 80 : 65);
                              }

                              // Nested builders so the badges repaint on their own
                              // controller's update(), not only when a module or an
                              // order changes.
                              return GetBuilder<CartController>(builder: (cartController) {
                                return GetBuilder<NotificationController>(builder: (notificationController) {
                                  return StorefrontBottomNav(
                                    currentIndex: _pageIndex,
                                    height: GetPlatform.isIOS ? 80 : 65,
                                    items: [
                                      StorefrontNavItem.material(
                                        icon: Icons.home_outlined, activeIcon: Icons.home_rounded,
                                        label: 'shop'.tr, pageIndex: 0, onTap: () => _setPage(0),
                                      ),
                                      StorefrontNavItem.material(
                                        icon: isParcel ? Icons.location_on_outlined : Icons.favorite_border,
                                        activeIcon: isParcel ? Icons.location_on : Icons.favorite,
                                        label: isParcel ? 'address'.tr : isTaxi ? 'wishlist'.tr : isRide ? 'my_activity'.tr : 'my_items'.tr,
                                        pageIndex: 1, onTap: () => _setPage(1),
                                      ),

                                      /// Assistant seat. Parcel, taxi and ride have no
                                      /// support desk of their own, so there it stays
                                      /// the cart it replaced.
                                      StorefrontNavItem(
                                        iconBuilder: (color, isSelected) => (isParcel || isTaxiWithCache || isRide)
                                            ? Icon(Icons.shopping_cart_outlined, size: 25, color: color)
                                            : StorefrontNavIcons.assistant(size: 25),
                                        label: (isParcel || isTaxiWithCache || isRide) ? 'cart'.tr : 'ask_sparky'.tr,
                                        badgeCount: (isParcel || isTaxiWithCache || isRide) ? cartController.cartList.length : 0,
                                        onTap: () async {
                                          if(isParcel) {
                                            showModalBottomSheet(
                                              context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                                              builder: (con) => ParcelBottomSheetWidget(parcelCategoryList: Get.find<ParcelController>().parcelCategoryList),
                                            );
                                          } else if(isRide) {
                                            if(AuthHelper.isLoggedIn()) {
                                              await Get.find<RideController>().getCurrentRideStatus(fromRefresh: true, showCustomLoader: true);
                                            } else {
                                              Get.dialog(const LoginWarningDialog());
                                            }
                                          } else if(isTaxiWithCache) {
                                            Get.to(() => const TaxiCartScreen());
                                          } else {
                                            Get.toNamed(RouteHelper.getSupportRoute());
                                          }
                                        },
                                      ),

                                      /// Four dots = everything the zone offers. With
                                      /// more than one module that is the module grid;
                                      /// with one it is that module's departments.
                                      StorefrontNavItem(
                                        iconBuilder: (color, isSelected) => StorefrontNavIcons.grid(size: 25, color: color),
                                        label: 'services'.tr,
                                        onTap: () {
                                          if(splashController.selectableModuleIndexes.length >= 2 && splashController.configModel!.module == null) {
                                            splashController.removeModule();
                                            Get.find<StoreController>().resetStoreData();
                                            _setPage(0);
                                          } else {
                                            Get.toNamed(RouteHelper.getCategoryRoute());
                                          }
                                        },
                                      ),

                                      StorefrontNavItem.material(
                                        icon: Icons.person_outline, activeIcon: Icons.person,
                                        label: 'account'.tr, pageIndex: 4,
                                        showDot: notificationController.hasNotification,
                                        onTap: () => _setPage(4),
                                      ),
                                    ],
                                  );
                                });
                              });
                            }
                          ),
                        ),
                      ]),

                    persistentContentHeight: (widget.fromSplash && Get.find<LocationController>().showLocationSuggestion && active) ? 0 : GetPlatform.isIOS ? 110 : 100,

                    onIsContractedCallback: () {
                      if(!orderController.showOneOrder) {
                        orderController.showOrders();
                      }
                    },
                    onIsExtendedCallback: () {
                      if(orderController.showOneOrder) {
                        orderController.showOrders();
                      }
                    },

                    enableToggle: true,

                    expandableContent: (widget.fromSplash && Get.find<LocationController>().showLocationSuggestion && active && !ResponsiveHelper.isDesktop(context)) ?  const SizedBox()
                    : (ResponsiveHelper.isDesktop(context) || !_isLogin || orderController.ongoingOrderModel == null
                    || orderController.ongoingOrderModel!.data!.isEmpty || !orderController.showBottomSheet) ? const SizedBox()
                    : Dismissible(
                      key: UniqueKey(),
                      onDismissed: (direction) {
                        if(orderController.showBottomSheet){
                          orderController.showRunningOrders();
                        }
                      },
                      child: RunningOrderViewWidget(reversOrder: runningOrder, onOrderTap: () {
                        _setPage(3);
                        if(orderController.showBottomSheet){
                          orderController.showRunningOrders();
                        }
                      }),
                    ),
                  ),
                ),
              );
            }
          ),
        );
      }
    );
  }

  void _setPage(int pageIndex) {
    // The PageView keeps OrderScreen's State alive across tab switches, so its
    // initState fetch only ever ran once — re-fetch on every visit to the Orders
    // tab so a newly placed/updated order can't be shown from a stale list.
    if(pageIndex == 3 && AuthHelper.isLoggedIn()) {
      Get.find<OrderController>().getRunningOrders(1, isUpdate: true);
      Get.find<OrderController>().getHistoryOrders(1, isUpdate: true);
    }
    setState(() {
      _pageController!.jumpToPage(pageIndex);
      _pageIndex = pageIndex;
    });
  }

  Widget trackView(BuildContext context, {required bool status}) {
    return Container(height: 3, decoration: BoxDecoration(color: status ? Theme.of(context).primaryColor
        : Theme.of(context).disabledColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)));
  }


}

