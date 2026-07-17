import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// A saved address on the "My Address" screen.
///
/// Its own widget rather than the shared [AddressWidget], which is also used by the cart,
/// checkout and dashboard — this way the address list can look how it likes without
/// changing those screens. It sizes to its content, so it can't clip like the old
/// fixed-aspect-ratio grid cell did.
class SavedAddressCardWidget extends StatelessWidget {
  final AddressModel address;
  final VoidCallback onTap;
  final VoidCallback onEditPressed;
  final VoidCallback onRemovePressed;
  const SavedAddressCardWidget({
    super.key, required this.address, required this.onTap,
    required this.onEditPressed, required this.onRemovePressed,
  });

  String get _typeIcon => address.addressType == 'home'
      ? Images.homeIcon
      : address.addressType == 'office' ? Images.workIcon : Images.otherIcon;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final String contact = [
      address.contactPersonName ?? '',
      address.contactPersonNumber ?? '',
    ].where((String s) => s.isNotEmpty).join('  •  ');

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
          blurRadius: 10, offset: const Offset(0, 4),
        )],
      ),
      child: CustomInkWell(
        onTap: onTap,
        radius: Dimensions.radiusLarge,
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Type icon in a tinted chip.
            Container(
              height: 42, width: 42,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              alignment: Alignment.center,
              child: Image.asset(_typeIcon, height: 20, width: 20, color: primary),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Row(children: [
                Expanded(child: Text(
                  (address.addressType ?? '').tr,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                )),

                _iconAction(context, icon: Icons.edit_outlined, onTap: onEditPressed),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                _iconAction(context, icon: Icons.delete_outline, onTap: onRemovePressed, isDanger: true),
              ]),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              Text(
                address.address ?? '',
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
                ),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),

              if(contact.isNotEmpty) ...[
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Row(children: [
                  Icon(Icons.person_outline, size: 13, color: Theme.of(context).disabledColor),
                  const SizedBox(width: 4),
                  Expanded(child: Text(
                    contact,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  )),
                ]),
              ],

            ])),
          ]),
        ),
      ),
    );
  }

  Widget _iconAction(BuildContext context, {required IconData icon, required VoidCallback onTap, bool isDanger = false}) {
    final Color color = isDanger ? const Color(0xFFD32F2F) : Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
