import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/helper/route_helper.dart';

class MomoPollingDialog extends StatefulWidget {
  final String paymentId;
  final String orderId;
  final String guestId;
  final String contactNumber;
  final int? storeId;
  final bool createAccount;

  const MomoPollingDialog({
    super.key,
    required this.paymentId,
    required this.orderId,
    required this.guestId,
    required this.contactNumber,
    this.storeId,
    required this.createAccount,
  });

  @override
  State<MomoPollingDialog> createState() => _MomoPollingDialogState();
}

class _MomoPollingDialogState extends State<MomoPollingDialog> {
  Timer? _timer;
  bool _isDisposed = false;
  int _pollCount = 0;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _pollCount++;
      if (_pollCount > 20) { // Timeout after 60 seconds
        timer.cancel();
        if (!_isDisposed) {
          Get.back();
          showCustomSnackBar('Payment verification timed out. Please check your MoMo app or contact support.');
          Get.offNamed(RouteHelper.getDigitalPaymentFailedScreen(widget.orderId, createAccount: widget.createAccount));
        }
        return;
      }

      try {
        final response = await http.get(
          Uri.parse('https://onestop.visionvivante.in/payment/momo/check-status?payment_id=${widget.paymentId}&reference_id=${widget.paymentId}'),
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
          },
        );

        if (_isDisposed) return;

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final status = (data['status'] ?? '').toString().toUpperCase();

          if (status == 'SUCCESSFUL') {
            timer.cancel();
            Get.back(); 
            Get.offNamed(RouteHelper.getOrderSuccessRoute(widget.orderId, widget.contactNumber, createAccount: widget.createAccount, guestId: widget.guestId));
          } else if (status == 'FAILED') {
            timer.cancel();
            Get.back();
            showCustomSnackBar('MoMo payment failed or was declined.');
            Get.offNamed(RouteHelper.getDigitalPaymentFailedScreen(widget.orderId, createAccount: widget.createAccount));
          }
        }
      } catch (e) {
        // keep polling on network error
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Text(
            'Waiting for MoMo payment approval...',
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            'Please check your phone and approve the payment.',
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          TextButton(
            onPressed: () {
              _timer?.cancel();
              Get.back();
              Get.offNamed(RouteHelper.getDigitalPaymentFailedScreen(widget.orderId, createAccount: widget.createAccount));
            },
            child: Text('Cancel', style: robotoBold.copyWith(color: Theme.of(context).colorScheme.error)),
          )
        ]),
      ),
    );
  }
}
