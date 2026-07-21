import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Service module only: before settling a pay-after-service order, the customer
/// confirms the amount to pay. The final bill can differ from the estimate (extra
/// work, parts, a negotiated price), so the amount is editable — typed directly or
/// stepped with the +/- buttons. Proceed hands the chosen amount to the caller,
/// which opens the payment-method sheet with it.
class ServicePaymentAmountSheet extends StatefulWidget {
  final double initialAmount;
  final void Function(double amount) onProceed;
  const ServicePaymentAmountSheet({super.key, required this.initialAmount, required this.onProceed});

  static void show({required double initialAmount, required void Function(double amount) onProceed}) {
    final Widget sheet = ServicePaymentAmountSheet(initialAmount: initialAmount, onProceed: onProceed);
    if (ResponsiveHelper.isDesktop(Get.context)) {
      Get.dialog(Dialog(backgroundColor: Colors.transparent, child: sheet));
    } else {
      Get.bottomSheet(sheet, backgroundColor: Colors.transparent, isScrollControlled: true);
    }
  }

  @override
  State<ServicePaymentAmountSheet> createState() => _ServicePaymentAmountSheetState();
}

class _ServicePaymentAmountSheetState extends State<ServicePaymentAmountSheet> {
  static const double _step = 10;

  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: _format(widget.initialAmount));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _format(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  void _bump(double delta) {
    final double next = _amount + delta;
    // Never allow the payable amount to drop below the original order total.
    if (next < widget.initialAmount) return;
    setState(() => _amountController.text = _format(next));
  }

  /// If the customer types a value lower than the order total, snap it back.
  void _clampToMinimum() {
    if (_amount < widget.initialAmount) {
      setState(() => _amountController.text = _format(widget.initialAmount));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 550,
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: ResponsiveHelper.isMobile(context)
            ? const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge))
            : BorderRadius.circular(Dimensions.radiusExtraLarge),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

        Center(child: Container(
          height: 4, width: 40,
          margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
        )),

        Text('payable_amount'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        Row(children: [
          Text('${'estimate_amount'.tr}: ', style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
          )),
          Text(PriceConverter.convertPrice(widget.initialAmount), style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeSmall,
          )),
        ]),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Row(children: [
          _stepButton(context, Icons.remove, () => _bump(-_step)),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Expanded(child: TextField(
            controller: _amountController,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
            onChanged: (_) => setState(() {}),
            onEditingComplete: _clampToMinimum,
            decoration: InputDecoration(
              hintText: 'enter_amount'.tr,
              contentPadding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(color: Theme.of(context).disabledColor, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(color: Theme.of(context).disabledColor, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
          )),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          _stepButton(context, Icons.add, () => _bump(_step)),
        ]),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        SafeArea(child: CustomButton(
          buttonText: '${'proceed'.tr}${_amount > 0 ? ' • ${PriceConverter.convertPrice(_amount)}' : ''}',
          onPressed: () {
            if (_amount <= 0) {
              showCustomSnackBar('enter_amount'.tr);
              return;
            }
            Get.back();
            widget.onProceed(_amount);
          },
        )),
      ]),
    );
  }

  Widget _stepButton(BuildContext context, IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      onTap: onTap,
      child: Container(
        height: 48, width: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
    );
  }
}
