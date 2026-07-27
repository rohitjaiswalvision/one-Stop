import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/common/widgets/premium/premium_chip.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/theme/premium_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/favourite/widgets/fav_item_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  FavouriteScreenState createState() => FavouriteScreenState();
}

class FavouriteScreenState extends State<FavouriteScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, initialIndex: 0, vsync: this);

    initCall();
  }

  void initCall(){
    if(AuthHelper.isLoggedIn()) {
      Get.find<FavouriteController>().getFavouriteList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      appBar: isDesktop ? const WebMenuBar() : AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        surfaceTintColor: Theme.of(context).primaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text('favourite'.tr, style: robotoMedium.copyWith(
          fontSize: Dimensions.fontSizeLarge, fontWeight: FontWeight.w600, color: Colors.white,
        )),
      ),
      endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,
      body: AuthHelper.isLoggedIn() ? SafeArea(child: GetBuilder<FavouriteController>(builder: (favouriteController) {
        final int savedCount = (favouriteController.wishItemList?.length ?? 0)
            + (favouriteController.wishStoreList?.length ?? 0);

        return Column(children: [

          WebScreenTitleWidget(title: 'favourite'.tr),

          SizedBox(
            width: Dimensions.webMaxWidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall,
              ),
              child: Row(children: [

                Expanded(child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: PremiumTokens.tint(context, opacity: 0.06),
                    borderRadius: BorderRadius.circular(PremiumTokens.radiusPill),
                  ),
                  child: TabBar(
                    tabAlignment: isDesktop ? TabAlignment.start : null,
                    isScrollable: isDesktop,
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(PremiumTokens.radiusPill),
                      gradient: PremiumTokens.brandGradient(context),
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Theme.of(context).textTheme.bodyLarge?.color,
                    unselectedLabelStyle: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                    labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall),
                    tabs: [
                      Tab(text: 'item'.tr),
                      Tab(text: Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!
                          ? 'restaurants'.tr : 'stores'.tr),
                    ],
                  ),
                )),

                if (savedCount > 0) Padding(
                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                  child: StatusPill(label: '$savedCount', color: Theme.of(context).primaryColor),
                ),

              ]),
            ),
          ),

          Expanded(child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              FavItemViewWidget(isStore: false),
              FavItemViewWidget(isStore: true),
            ],
          )),

        ]);
      })) : NotLoggedInScreen(callBack: (value){
        initCall();
        setState(() {});
      }),
    );
  }
}
