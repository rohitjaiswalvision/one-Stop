import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/screens/order_details_screen.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// A services order's real progress lives on its first booking's status, since
/// orders.order_status can lag behind what the vendor has actually marked done/cancelled.
String _bookingStatus(OrderModel order) {
  final List<OrderServiceBooking>? bookings = order.serviceBookings;
  if (bookings != null && bookings.isNotEmpty && (bookings.first.status?.isNotEmpty ?? false)) {
    return bookings.first.status!;
  }
  return order.orderStatus ?? '';
}

const Set<String> _terminalBookingStatuses = {'completed', 'canceled', 'cancelled', 'refunded'};

/// Services module home screen section: the customer's currently in-progress bookings.
/// Pure GetBuilder render, matching this folder's convention (VisitAgainView, BannerView,
/// etc.) — the fetch itself is kicked off once from HomeScreen.loadData, not here.
class RunningServicesView extends StatelessWidget {
  const RunningServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderController>(builder: (orderController) {
      final List<OrderModel>? orders = orderController.runningOrderModel?.orders;
      if(orders == null) {
        return const SizedBox();
      }

      final List<OrderModel> runningServices = orders.where((order) {
        return order.moduleType == AppConstants.service && !_terminalBookingStatuses.contains(_bookingStatus(order));
      }).toList();

      if(runningServices.isEmpty) {
        return const SizedBox();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Text('${'running'.tr} ${'services'.tr}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: runningServices.length,
            separatorBuilder: (context, index) => const SizedBox(height: Dimensions.paddingSizeSmall),
            itemBuilder: (context, index) {
              final OrderModel order = runningServices[index];
              final OrderServiceBooking? booking = (order.serviceBookings?.isNotEmpty ?? false) ? order.serviceBookings!.first : null;
              final String status = _bookingStatus(order);
              final String staffImage = booking?.staff?.imageFullUrl ?? '';

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
                ),
                child: CustomInkWell(
                  onTap: () => Get.toNamed(
                    RouteHelper.getOrderDetailsRoute(order.id),
                    arguments: OrderDetailsScreen(orderId: order.id, orderModel: order),
                  ),
                  radius: Dimensions.radiusLarge,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Row(children: [

                    ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      child: Container(
                        height: 48, width: 48, alignment: Alignment.center,
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                        child: staffImage.isNotEmpty
                            ? CustomImage(image: staffImage, height: 48, width: 48, fit: BoxFit.cover)
                            : Icon(Icons.build_outlined, color: Theme.of(context).primaryColor),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        booking?.itemName ?? '${'order_id'.tr}: #${order.id}',
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (booking?.serviceDate?.isNotEmpty ?? false) ? '${booking!.serviceDate} ${booking.startTime ?? ''}'.trim()
                            : DateConverter.dateTimeStringToDateTime(order.createdAt ?? ''),
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ])),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      ),
                      child: Text(status.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor)),
                    ),

                  ]),
                ),
              );
            },
          ),

        ]),
      );
    });
  }
}
