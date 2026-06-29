import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class VerifyMomoDialog extends StatelessWidget {
  const VerifyMomoDialog({Key? key}) : super(key: key);

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = secs.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckoutController>(
      builder: (checkoutController) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
          title: Text(
            "Verify Payment",
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Please check your MoMo wallet and approve the payment. After approval, tap Verify Now.",
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Time left: ${_formatTime(checkoutController.remainingSeconds)}",
                    style: robotoMedium.copyWith(color: Theme.of(context).disabledColor),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  TextButton(
                    onPressed: checkoutController.isLoading ? null : () => checkoutController.extendPendingTimer(),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text("+30 sec"),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: checkoutController.isLoading
                  ? null
                  : () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Get.back(); // Just close the dialog, state remains pending
                    },
              child: const Text("Later"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: checkoutController.isLoading
                  ? null
                  : () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      await checkoutController.verifyMomoPayment();
                      if (!checkoutController.hasPendingVerify) {
                        if(Get.isDialogOpen ?? false) Get.back();
                      }
                    },
              child: checkoutController.isLoading 
                  ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,)) 
                  : const Text("Verify Now"),
            ),
          ],
        );
      },
    );
  }
}
