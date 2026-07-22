import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_card.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Services module: what the staff added/left on the booking while on the job —
/// the extra services (name + price each) and the completion note ("Work done").
/// Feed it order-detail rows (Order Details screen) and/or track-model bookings
/// (Order Tracking screen); renders nothing when the bookings carry none of
/// these, so non-service orders and untouched bookings are unaffected.
class ServiceExtrasWidget extends StatelessWidget {
  final List<OrderDetailsModel>? orderDetails;
  final List<OrderServiceBooking>? serviceBookings;
  const ServiceExtrasWidget({super.key, this.orderDetails, this.serviceBookings});

  @override
  Widget build(BuildContext context) {
    // The two payloads can BOTH carry the same booking, and either one may be the
    // only one holding the staff-added data (backends differ on where they attach
    // it). So entries are merged per booking id — services/note come from whichever
    // source actually has them — instead of first-source-wins, which would drop
    // the filled copy whenever an empty copy of the same booking was seen first.
    final Map<Object, List<BookingAdditionalService>> servicesByBooking = {};
    final Map<Object, String> noteByBooking = {};
    int syntheticKey = -1;

    void absorb(int? id, List<BookingAdditionalService>? bookingServices, String? note) {
      final Object key = id ?? syntheticKey--;
      if (bookingServices != null && bookingServices.isNotEmpty && (servicesByBooking[key]?.isEmpty ?? true)) {
        servicesByBooking[key] = bookingServices;
      }
      if (note != null && note.trim().isNotEmpty && (noteByBooking[key]?.isEmpty ?? true)) {
        noteByBooking[key] = note.trim();
      }
    }

    for (final OrderServiceBooking booking in serviceBookings ?? const []) {
      absorb(booking.id, booking.additionalServices, booking.completionNote);
    }
    for (final OrderDetailsModel detail in orderDetails ?? const []) {
      final DetailServiceBooking? booking = detail.serviceBooking;
      if (booking == null) continue;
      absorb(booking.id, booking.additionalServices, booking.completionNote);
    }

    final List<BookingAdditionalService> services = servicesByBooking.values.expand((v) => v).toList();
    final List<String> notes = noteByBooking.values.toList();

    if (services.isEmpty && notes.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      child: CustomCard(
        borderRadius: 0, isBorder: false,
        padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          if (services.isNotEmpty) ...[
            Text('additional_services'.tr, style: robotoSemiBold),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            ...services.map((BookingAdditionalService service) => Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(
                  service.name ?? '',
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                )),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Text(
                  PriceConverter.convertPrice(service.price ?? 0),
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                  textDirection: TextDirection.ltr,
                ),
              ]),
            )),
          ],

          if (services.isNotEmpty && notes.isNotEmpty)
            const SizedBox(height: Dimensions.paddingSizeSmall),

          if (notes.isNotEmpty) ...[
            Text('work_done'.tr, style: robotoSemiBold),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: Text(
                notes.join('\n'),
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
