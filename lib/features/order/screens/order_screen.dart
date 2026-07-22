import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/premium/premium_chip.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_order/controllers/taxi_order_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_order/widgets/trip_order_view_widget.dart';
import 'package:sixam_mart/features/ride_share_module/ride_order/controllers/ride_controller.dart';
import 'package:sixam_mart/features/ride_share_module/ride_order/widgets/ride_order_view_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/taxi_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/features/order/widgets/guest_track_order_input_view_widget.dart';
import 'package:sixam_mart/features/order/widgets/order_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderScreen extends StatefulWidget {
  final String? index;
  const OrderScreen({super.key, this.index = 'orders'});

  @override
  OrderScreenState createState() => OrderScreenState();
}

class OrderScreenState extends State<OrderScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  bool _isLoggedIn = AuthHelper.isLoggedIn();
  List<String> type = [];
  Map<String, String> moduleLabels = {};
  String selectType = 'orders';
  bool haveTaxiModule = false;
  ScrollController? scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    initSetup();
  }

  void initSetup() {
    _isLoggedIn = AuthHelper.isLoggedIn();
    moduleLabels = {};

    if(_isLoggedIn) {
      final List<ModuleModel>? moduleList = Get.find<SplashController>().moduleList;
      type = [];
      if(moduleList != null) {
        for (final ModuleModel module in moduleList) {
          if(module.moduleType != null
              && module.moduleType != AppConstants.taxi
              && module.moduleType != AppConstants.ride
              && !type.contains(module.moduleType)) {
            type.add(module.moduleType!);
            moduleLabels[module.moduleType!] = module.moduleName ?? module.moduleType!;
          }
        }
      }
      if(type.isEmpty) {
        type = ['orders'];
      }
      if(TaxiHelper.haveTaxiModule()) {
        type.add('trips');
      }
      if(TaxiHelper.haveRideModule()) {
        type.add('rides');
      }
    }else {
      type = ['orders', 'trips'];
    }

    if(!TaxiHelper.haveTaxiServiceRideModules() && !AuthHelper.isLoggedIn()) {
      type = ['orders'];
    }

    selectType = type.contains(widget.index) ? widget.index! : type.first;
    _ensureTabController();
    haveTaxiModule = TaxiHelper.haveTaxiServiceRideModules();

    initCall();
  }

  /// Trips/Rides keep their existing Running/Completed 2-tab layout; every other module
  /// tab gets a 3rd "Cancelled" tab so cancelled/refunded/failed orders split out of Completed.
  int get _runningCompletedTabCount => (selectType == 'trips' || selectType == 'rides') ? 2 : 3;

  void _ensureTabController() {
    final int desiredLength = _runningCompletedTabCount;
    if(_tabController == null || _tabController!.length != desiredLength) {
      final int previousIndex = _tabController != null && _tabController!.index < desiredLength ? _tabController!.index : 0;
      _tabController?.dispose();
      _tabController = TabController(length: desiredLength, initialIndex: previousIndex, vsync: this);
    }
  }

  void initCall(){
    _ensureCachedModule();
    if(AuthHelper.isLoggedIn()) {
      if(selectType != 'trips' && selectType != 'rides') {
        Get.find<OrderController>().getRunningOrders(1);
        Get.find<OrderController>().getHistoryOrders(1);
      } else if(selectType == 'trips') {
        Get.find<TaxiOrderController>().getTripList(1, isRunning: true);
        Get.find<TaxiOrderController>().getTripList(1, isRunning: false);
      }
      else if(selectType == 'rides') {
        Get.find<RideController>().getRideList(1, isRunning: true);
        Get.find<RideController>().getRideList(1, isRunning: false);
      }
    }
  }

  void _ensureCachedModule() {
    final splash = Get.find<SplashController>();
    if(splash.getCacheModule() != null) return;

    final List<ModuleModel>? list = splash.moduleList;
    if(list == null || list.isEmpty) return;

    final ModuleModel fallback = list.firstWhere(
      (m) => m.moduleType != AppConstants.taxi && m.moduleType != AppConstants.ride,
      orElse: () => list.first,
    );
    splash.setModule(fallback, notify: false);
  }

  @override
  Widget build(BuildContext context) {
    _isLoggedIn = AuthHelper.isLoggedIn();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: haveTaxiModule && !ResponsiveHelper.isDesktop(context) ? null : CustomAppBar(title: 'my_orders'.tr, backButton: ResponsiveHelper.isDesktop(context)),
      endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
      body: SafeArea(
        child: GetBuilder<OrderController>(
          builder: (orderController) {
            return Column(
              children: [

                haveTaxiModule && !ResponsiveHelper.isDesktop(context) ? Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [BoxShadow(color: Theme.of(context).disabledColor.withValues(alpha: 0.1), blurRadius: 5, offset: const Offset(0, 10))],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Text('my_orders'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    SizedBox(
                      height: 34,
                      child: ListView.builder(
                          itemCount: type.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            bool selected = type[index] == selectType;
                            return Padding(
                              padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                              child: PremiumChip(
                                label: moduleLabels[type[index]] ?? type[index].tr,
                                selected: selected,
                                onTap: () {
                                  setState(() {
                                    selectType = type[index];
                                    _ensureTabController();
                                  });
                                  initCall();
                                },
                              ),
                            );
                          }),
                    ),

                  ]),
                ) : const SizedBox(),

                _isLoggedIn ? Expanded(
                  child: Column(children: [

                    ResponsiveHelper.isDesktop(context) ? Container(
                      color: ResponsiveHelper.isDesktop(context) ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                      child: Column(children: [
                        ResponsiveHelper.isDesktop(context) ? Center(child: Padding(
                          padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                          child: Text('my_orders'.tr, style: robotoMedium),
                        )) : const SizedBox(),

                        Center(
                          child: SizedBox(
                            width: Dimensions.webMaxWidth,
                            child: Align(
                              alignment: ResponsiveHelper.isDesktop(context) ? Alignment.centerLeft : Alignment.center,
                              child: Container(
                                width: ResponsiveHelper.isDesktop(context) ? 300 : Dimensions.webMaxWidth,
                                color: ResponsiveHelper.isDesktop(context) ? Colors.transparent : Theme.of(context).cardColor,
                                child: TabBar(
                                  controller: _tabController,
                                  indicatorColor: Theme.of(context).primaryColor,
                                  indicatorWeight: 3,
                                  labelColor: Theme.of(context).primaryColor,
                                  unselectedLabelColor: Theme.of(context).disabledColor,
                                  unselectedLabelStyle: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
                                  labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                                  tabs: [
                                    Tab(text: 'running'.tr),
                                    Tab(text: 'completed'.tr),
                                    if(_runningCompletedTabCount == 3) Tab(text: 'cancelled'.tr),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ) : Column(children: [

                      Align(
                        alignment: Alignment.centerLeft,
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: haveTaxiModule ? true : false,
                          padding: EdgeInsets.zero,
                          tabAlignment: haveTaxiModule ? TabAlignment.start : null,
                          indicatorColor: Theme.of(context).primaryColor,
                          indicatorWeight: 3,
                          labelColor: Theme.of(context).primaryColor,
                          unselectedLabelColor: Theme.of(context).disabledColor,
                          unselectedLabelStyle: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
                          labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                          tabs: [
                            Tab(text: 'running'.tr),
                            Tab(text: 'completed'.tr),
                            if(_runningCompletedTabCount == 3) Tab(text: 'cancelled'.tr),
                          ],
                        ),
                      ),
                    ]),

                    selectType == 'trips' ? Expanded(child: TabBarView(
                     controller: _tabController,
                     children: const [
                       TripOrderViewWidget(isRunning: true),
                       TripOrderViewWidget(isRunning: false),
                     ],
                   )) : selectType == 'rides' ? Expanded(child: TabBarView(
                      controller: _tabController,
                      children: const [
                        RideOrderViewWidget(isRunning: true),
                        RideOrderViewWidget(isRunning: false),
                      ],
                    )) : Expanded(child: TabBarView(
                      controller: _tabController,
                      children: [
                        OrderViewWidget(isRunning: true, moduleType: selectType == 'orders' ? null : selectType),
                        OrderViewWidget(isRunning: false, moduleType: selectType == 'orders' ? null : selectType),
                        OrderViewWidget(isRunning: false, moduleType: selectType == 'orders' ? null : selectType, cancelledOnly: true),
                      ],
                    )),

                  ]),
                ) : GuestTrackOrderInputViewWidget(selectType: selectType,  callBack: (success) {
                  if(success) {
                    initSetup();
                    setState(() {});
                  }
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
