import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// The optional "what work do you want done?" note for a service. Shown as a sheet when a
/// service is added to the cart; the note is saved on the [CartController] (keyed by item id)
/// and rendered on the cart line. Entering a note is optional — "Skip" proceeds without one.
class ServiceNoteHelper {
  ServiceNoteHelper._();

  /// Opens the note sheet for [item], then runs [onProceed] once the user taps Add or Skip.
  /// [onProceed] is where the actual add-to-cart happens (so the note is captured first);
  /// omit it when editing an existing cart line's note.
static void openNoteSheet(Item item, {VoidCallback? onProceed}) {
  final TextEditingController controller = TextEditingController();

  Get.bottomSheet(
    _ServiceNoteSheet(
      item: item,
      controller: controller,
      onProceed: onProceed,
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

}

class _ServiceNoteSheet extends StatelessWidget {
  final Item item;
  final TextEditingController controller;
  final VoidCallback? onProceed;
  const _ServiceNoteSheet({required this.item, required this.controller, this.onProceed});

  void _finish(String note) {
    Get.find<CartController>().setServiceNote(item.id, note);
    Get.back();        // close the sheet
    onProceed?.call(); // then perform the add (no-op when editing from the cart)
  }

  @override
  Widget build(BuildContext context) {
    // Mirrors the working square-feet sheet: Get.bottomSheet(isScrollControlled) already
    // insets for the keyboard, so we DON'T add viewInsets padding ourselves (doing so lifted
    // the sheet twice and floated it near the top). SingleChildScrollView + Column(min) keeps
    // it compact and lets it scroll if the keyboard leaves too little room.
    return Container(
      width: 550,
      margin: EdgeInsets.only(top: ResponsiveHelper.isMobile(context) ? 30 : 0),
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

          Center(child: Container(
            height: 4, width: 40,
            margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
            decoration: BoxDecoration(color: Theme.of(context).disabledColor, borderRadius: BorderRadius.circular(10)),
          )),

          Text('add_additional_instruction'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
            '${'optional'.tr} — ${item.name ?? ''}',
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          // A comfortable multi-line field (3 lines, grows to 5) — it grows with content and
          // the scroll view above handles any tight-keyboard case.
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'enter_additional_instruction'.tr,
              hintStyle: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              contentPadding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Row(children: [
            Expanded(child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                side: BorderSide(color: Theme.of(context).primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
              ),
              onPressed: () => _finish(''),   // Skip — proceed without a note
              child: Text('skip'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
            )),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: CustomButton(
              buttonText: 'add'.tr,
              onPressed: () => _finish(controller.text),
            )),
          ]),

        ]),
      ),
    );
  }
}
