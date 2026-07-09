import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_card.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Appointment slot(s) of a services-module order: the booked date, the time
/// window and the assigned provider.
class ServiceBookingDetailsWidget extends StatelessWidget {
  final OrderModel order;
  const ServiceBookingDetailsWidget({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final List<OrderServiceBooking> bookings = order.serviceBookings ?? [];
    if (bookings.isEmpty) {
      return const SizedBox();
    }
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return CustomCard(
      borderRadius: isDesktop ? Dimensions.radiusDefault : 0, isBorder: false,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('service_details'.tr, style: robotoSemiBold),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookings.length,
          separatorBuilder: (context, index) => Divider(height: Dimensions.paddingSizeExtraLarge, color: Theme.of(context).disabledColor.withValues(alpha: 0.5)),
          itemBuilder: (context, index) => _bookingView(context, bookings[index]),
        ),
      ]),
    );
  }

  Widget _bookingView(BuildContext context, OrderServiceBooking booking) {
    // The booking carries its own staff; `service_staff` is the order-level
    // fallback for backends that only assign one provider per order.
    final ServiceStaff? staff = booking.staff ?? order.serviceStaff;

    final String timeRange = [
      DateConverter.serviceTimeToReadable(booking.startTime),
      DateConverter.serviceTimeToReadable(booking.endTime),
    ].where((t) => t.isNotEmpty).join(' - ');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      if (booking.itemName != null && booking.itemName!.isNotEmpty) ...[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(booking.itemName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoMedium)),

          if (booking.status != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ),
            child: Text(booking.status!.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)),
          ),
        ]),
        const SizedBox(height: Dimensions.paddingSizeSmall),
      ],

      if (booking.serviceDate != null)
        _row(context, 'service_date'.tr, DateConverter.serviceDateToReadable(booking.serviceDate)),

      if (timeRange.isNotEmpty)
        _row(context, 'time'.tr, timeRange),

      if (booking.duration != null)
        _row(context, 'duration'.tr, '${booking.duration} ${'minutes'.tr}'),

      if (staff != null && (staff.name?.isNotEmpty ?? false)) ...[
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Text('service_provider'.tr, style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6))),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        Row(children: [
          ClipOval(child: CustomImage(
            image: staff.imageFullUrl ?? '',
            height: 35, width: 35, fit: BoxFit.cover,
          )),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(staff.name!, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),

            if (staff.phone?.isNotEmpty ?? false) Text(
              staff.phone!, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
            ),
          ])),

          if (staff.phone?.isNotEmpty ?? false) InkWell(
            onTap: () async {
              if (await canLaunchUrlString('tel:${staff.phone}')) {
                launchUrlString('tel:${staff.phone}', mode: LaunchMode.externalApplication);
              } else {
                showCustomSnackBar('${'can_not_launch'.tr} ${staff.phone}');
              }
            },
            child: Image.asset(Images.phoneOrderDetails, height: 20, width: 20),
          ),
        ]),
      ],
    ]);
  }

  Widget _row(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6))),

        Text(value, style: robotoMedium),
      ]),
    );
  }
}
