import 'dart:async';
import 'dart:io';
import 'package:sixam_mart/common/widgets/premium/premium_button.dart';
import 'package:sixam_mart/common/widgets/premium/premium_motion.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/widgets/sign_in/sign_in_view.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/theme/premium_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/language/widgets/language_bottom_sheet_widget.dart';

class SignInScreen extends StatefulWidget {
  final bool exitFromApp;
  final bool backFromThis;
  final bool fromNotification;
  final bool fromResetPassword;
  final bool? fromRideDialog;
  const SignInScreen({super.key, required this.exitFromApp, required this.backFromThis, this.fromNotification = false, this.fromResetPassword = false, this.fromRideDialog});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  bool _canExit = GetPlatform.isWeb ? true : false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) async {
        if(widget.fromNotification || widget.fromResetPassword) {
          Navigator.pushNamed(context, RouteHelper.getInitialRoute());
        } else if(widget.exitFromApp) {
          if (_canExit) {
            if (GetPlatform.isAndroid) {
              SystemNavigator.pop();
            } else if (GetPlatform.isIOS) {
              exit(0);
            } else {
              Navigator.pushNamed(context, RouteHelper.getInitialRoute());
            }
          } else {
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
        } else {
          if(Get.find<AuthController>().isOtpViewEnable){
            Get.find<AuthController>().enableOtpView(enable: false);
          }else{
            // Get.back();
          }
        }
      },
      child: Scaffold(
        backgroundColor: ResponsiveHelper.isDesktop(context) ? Colors.transparent : Theme.of(context).scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        appBar: (ResponsiveHelper.isDesktop(context) ? null : AppBar(
          leading: !widget.exitFromApp ? PremiumIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {
              if(widget.fromNotification || widget.fromResetPassword) {
                Navigator.pushNamed(context, RouteHelper.getInitialRoute());
              }else if(Get.find<AuthController>().isOtpViewEnable){
                Get.find<AuthController>().enableOtpView(enable: false);
              }else{
                Get.back(result: false);
              }
            },
          ) : const SizedBox(),
          leadingWidth: 64,
          elevation: 0, backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent,
          actions: [
            PremiumIconButton(
              icon: Icons.language_rounded,
              onTap: () => Get.bottomSheet(const LanguageBottomSheetWidget(), isScrollControlled: true),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
          ],
        )),
        endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,

        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [PremiumTokens.tint(context, opacity: 0.10), Theme.of(context).scaffoldBackgroundColor],
              stops: const [0, 0.35],
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: context.width > 700 ? 500 : context.width,
                padding: context.width > 700 ? const EdgeInsets.all(50) : const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
                margin: context.width > 700 ? const EdgeInsets.all(50) : EdgeInsets.zero,
                decoration: context.width > 700 ? BoxDecoration(
                  color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  boxShadow: ResponsiveHelper.isDesktop(context) ? null : PremiumTokens.softShadow(context),
                ) : null,
                child: SingleChildScrollView(
                  child: FadeSlideIn(
                    child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [

                      ResponsiveHelper.isDesktop(context) ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () => Get.bottomSheet(const LanguageBottomSheetWidget(), isScrollControlled: true),
                            icon: const Icon(Icons.language),
                          ),
                          IconButton(
                            onPressed: () => Get.back(),
                            icon: const Icon(Icons.clear),
                          ),
                        ],
                      ) : const SizedBox(),

                      Container(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).cardColor,
                          boxShadow: PremiumTokens.softShadow(context, strength: 0.7),
                        ),
                        child: Image.asset(Images.logo, width: 84),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                      Text('welcome_back'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge)),
                      const SizedBox(height: 4),
                      Text('sign_in_to_continue'.tr, style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).disabledColor,
                      )),
                      const SizedBox(height: Dimensions.paddingSizeExtremeLarge),

                      SignInView(exitFromApp: widget.exitFromApp, backFromThis: widget.backFromThis, fromResetPassword: widget.fromResetPassword, isOtpViewEnable: (v){},),

                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
