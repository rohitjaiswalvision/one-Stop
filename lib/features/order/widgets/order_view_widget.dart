import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/custom_loader.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/review/screens/rate_review_screen.dart';
import 'package:sixam_mart/features/order/widgets/order_shimmer_widget.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/features/order/screens/order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Status to show for an order row. For a services order the booking carries the real
/// status (e.g. "accepted" while the order row is still "pending"), so prefer the first
/// service_booking's status; every other module keeps the order-level status.
String _orderDisplayStatus(OrderModel order) {
  final List<OrderServiceBooking>? bookings = order.serviceBookings;
  if (bookings != null && bookings.isNotEmpty && (bookings.first.status?.isNotEmpty ?? false)) {
    return bookings.first.status!;
  }
  return order.orderStatus ?? '';
}

/// Pay-after-service: the job is done but the customer has not settled yet, so the row
/// flags the outstanding payment. Same detection as the order-details Pay Now gate —
/// "done" is read from the bookings themselves because orders.order_status can lag.
bool _isServicePaymentPending(OrderModel order) {
  final List<OrderServiceBooking>? bookings = order.serviceBookings;
  final bool workDone = order.orderStatus == 'delivered' || order.orderStatus == 'completed'
      || (bookings != null && bookings.isNotEmpty && bookings.every((b) => b.status == 'completed'));
  return order.moduleType == AppConstants.service
      && order.paymentMethod == 'cash_on_delivery'
      && order.paymentStatus == 'unpaid'
      && workDone;
}

/// The orange chip shown beside/under the status chip while a completed service is unpaid.
Widget _paymentPendingChip(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      color: Colors.orange.withValues(alpha: 0.12),
    ),
    child: Text('payment_pending'.tr, style: robotoMedium.copyWith(
      fontSize: Dimensions.fontSizeExtraSmall, color: Colors.orange,
    )),
  );
}

class OrderViewWidget extends StatelessWidget {
  final bool isRunning;
  const OrderViewWidget({super.key, required this.isRunning});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: GetBuilder<OrderController>(builder: (orderController) {
        PaginatedOrderModel? paginatedOrderModel;
        if(isRunning) {
          paginatedOrderModel = orderController.runningOrderModel;
        }else {
          paginatedOrderModel = orderController.historyOrderModel;
        }

        return paginatedOrderModel != null ? paginatedOrderModel.orders!.isNotEmpty ? RefreshIndicator(
          onRefresh: () async {
            if(isRunning) {
              await orderController.getRunningOrders(1, isUpdate: true);
            }else {
              await orderController.getHistoryOrders(1, isUpdate: true);
            }
          },
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: FooterView(
              child: SizedBox(
                width: Dimensions.webMaxWidth,
                child: Padding(
                  padding: EdgeInsets.only(bottom: ResponsiveHelper.isDesktop(context) ? 0 : 100),
                  child: PaginatedListView(
                    scrollController: scrollController,
                    onPaginate: (int? offset) async {
                      if(isRunning) {
                        await orderController.getRunningOrders(offset!, isUpdate: true);
                      }else {
                        await orderController.getHistoryOrders(offset!, isUpdate: true);
                      }
                    },
                    totalSize: isRunning ? orderController.runningOrderModel?.totalSize : orderController.historyOrderModel?.totalSize,
                    offset: isRunning ? orderController.runningOrderModel?.offset : orderController.historyOrderModel?.offset,
                    itemView: ResponsiveHelper.isDesktop(context) ? GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisSpacing: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeExtremeLarge : Dimensions.paddingSizeLarge,
                        mainAxisSpacing: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeExtremeLarge : 0,
                        mainAxisExtent: ResponsiveHelper.isDesktop(context) ? 130 : 100,
                        crossAxisCount: ResponsiveHelper.isMobile(context) ? 1 : 2,
                      ),
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: ResponsiveHelper.isDesktop(context) ? const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge) : const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                      itemCount: paginatedOrderModel.orders!.length,
                      itemBuilder: (context, index) {
                        bool isParcel = paginatedOrderModel!.orders![index].orderType == 'parcel';
                        bool isPrescription = paginatedOrderModel.orders![index].prescriptionOrder!;

                        return Container(
                          padding: ResponsiveHelper.isDesktop(context) ? const EdgeInsets.all(Dimensions.paddingSizeSmall) : null,
                          margin: ResponsiveHelper.isDesktop(context) ? const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall) : null,
                          decoration: ResponsiveHelper.isDesktop(context) ? BoxDecoration(
                            color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                            boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
                          ) : null,
                          child: CustomInkWell(
                            onTap: () {
                              Get.toNamed(
                                RouteHelper.getOrderDetailsRoute(paginatedOrderModel!.orders![index].id),
                                arguments: OrderDetailsScreen(
                                  orderId: paginatedOrderModel.orders![index].id,
                                  orderModel: paginatedOrderModel.orders![index],
                                ),
                              );
                            },
                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                              Row(children: [

                                Stack(children: [
                                  Container(
                                    height: ResponsiveHelper.isDesktop(context) ? 80 : 60, width: ResponsiveHelper.isDesktop(context) ? 80 : 60, alignment: Alignment.center,
                                    decoration: isParcel ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                    ) : null,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                      child: CustomImage(
                                        image: isParcel ? '${paginatedOrderModel.orders![index].parcelCategory != null ? paginatedOrderModel.orders![index].parcelCategory!.imageFullUrl : ''}'
                                            : '${paginatedOrderModel.orders![index].store != null ? paginatedOrderModel.orders![index].store!.logoFullUrl : ''}',
                                        height: isParcel ? 35 : ResponsiveHelper.isDesktop(context) ? 80 : 60,
                                        width: isParcel ? 35 : ResponsiveHelper.isDesktop(context) ? 80 : 60, fit: isParcel ? null : BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  isParcel ? Positioned(left: 0, top: 10, child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(Dimensions.radiusSmall)),
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    child: Text('parcel'.tr, style: robotoMedium.copyWith(
                                      fontSize: Dimensions.fontSizeExtraSmall, color: Colors.white,
                                    )),
                                  )) : const SizedBox(),

                                  isPrescription ? Positioned(left: 0, top: 10, child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(Dimensions.radiusSmall)),
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    child: Text('prescription'.tr, style: robotoMedium.copyWith(
                                      fontSize: 10, color: Colors.white,
                                    )),
                                  )) : const SizedBox(),
                                ]),
                                const SizedBox(width: Dimensions.paddingSizeSmall),

                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Text(
                                        '${isParcel ? 'delivery_id'.tr : 'order_id'.tr}:',
                                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                                      ),
                                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                      Text('#${paginatedOrderModel.orders![index].id}', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
                                    ]),
                                    const SizedBox(height: Dimensions.paddingSizeSmall),

                                    ResponsiveHelper.isDesktop(context) ? Padding(
                                      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                          ),
                                          child: Text(_orderDisplayStatus(paginatedOrderModel.orders![index]).tr, style: robotoMedium.copyWith(
                                            fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor,
                                          )),
                                        ),
                                        if(_isServicePaymentPending(paginatedOrderModel.orders![index])) ...[
                                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                          _paymentPendingChip(context),
                                        ],
                                      ]),
                                    ) : const SizedBox(),

                                    Text(
                                      DateConverter.dateTimeStringToDateTime(paginatedOrderModel.orders![index].createdAt!),
                                      style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
                                    ),
                                  ]),
                                ),
                                const SizedBox(width: Dimensions.paddingSizeSmall),

                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  !ResponsiveHelper.isDesktop(context) ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                    ),
                                    child: Text(_orderDisplayStatus(paginatedOrderModel.orders![index]).tr, style: robotoMedium.copyWith(
                                      fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor,
                                    )),
                                  ) : const SizedBox(),
                                  if(!ResponsiveHelper.isDesktop(context) && _isServicePaymentPending(paginatedOrderModel.orders![index])) ...[
                                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                    _paymentPendingChip(context),
                                  ],
                                  const SizedBox(height: Dimensions.paddingSizeSmall),

                                  isRunning ? InkWell(
                                    onTap: () => Get.toNamed(RouteHelper.getOrderTrackingRoute(paginatedOrderModel!.orders![index].id, null)),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: ResponsiveHelper.isDesktop(context) ? Dimensions.fontSizeSmall : Dimensions.paddingSizeExtraSmall),
                                      decoration: ResponsiveHelper.isDesktop(context) ? BoxDecoration(
                                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                        color: Theme.of(context).primaryColor,
                                      ) : BoxDecoration(
                                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                        border: Border.all(width: 1, color: Theme.of(context).primaryColor),
                                      ),
                                      child: Row(children: [
                                        Image.asset(Images.tracking, height: 15, width: 15, color: ResponsiveHelper.isDesktop(context) ? Colors.white : Theme.of(context).primaryColor),
                                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                        Text(isParcel ? 'track_delivery'.tr : 'track_order'.tr, style: robotoMedium.copyWith(
                                          fontSize: Dimensions.fontSizeExtraSmall, color: ResponsiveHelper.isDesktop(context) ? Colors.white : Theme.of(context).primaryColor,
                                        )),
                                      ]),
                                    ),
                                  ) : isParcel ? const SizedBox() : Text(
                                    '${paginatedOrderModel.orders![index].detailsCount} ${paginatedOrderModel.orders![index].detailsCount! > 1 ? 'items'.tr : 'item'.tr}',
                                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
                                  ),
                                ]),

                              ]),

                              (index == paginatedOrderModel.orders!.length-1 || ResponsiveHelper.isDesktop(context)) ? const SizedBox() : Padding(
                                padding: const EdgeInsets.only(left: 70),
                                child: Divider(
                                  color: Theme.of(context).disabledColor, height: Dimensions.paddingSizeLarge,
                                ),
                              ),

                            ]),
                          ),
                        );
                      },)
                    : ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeSmall),
                        itemCount: paginatedOrderModel.orders!.length,
                        itemBuilder: (context, index) => _orderCard(context, paginatedOrderModel!.orders![index]),
                      ),
                  ),
                ),
              ),
            ),
          ),
        ) : NoDataScreen(text: 'no_order_found'.tr, showFooter: true) : OrderShimmerWidget(orderController: orderController);
      }),
    );
  }

  /// Swiggy-style order card (mobile): store logo + name/address header, a status/date row,
  /// then item count + total with a primary action (Track for running, Re-order for history).
  Widget _orderCard(BuildContext context, OrderModel order) {
    final bool isParcel = order.orderType == 'parcel';
    final String status = _orderDisplayStatus(order);
    final Color statusColor = _statusColor(context, status);

    final String title = isParcel
        ? (order.parcelCategory?.name ?? 'parcel'.tr)
        : (order.store?.name ?? '#${order.id}');
    final String subtitle = isParcel
        ? '${'delivery_id'.tr}: #${order.id}'
        : ((order.store?.address?.isNotEmpty ?? false) ? order.store!.address! : '${'order_id'.tr}: #${order.id}');
    final String image = isParcel
        ? (order.parcelCategory?.imageFullUrl ?? '')
        : (order.store?.logoFullUrl ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Theme.of(context).disabledColor.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: CustomInkWell(
        onTap: () => Get.toNamed(
          RouteHelper.getOrderDetailsRoute(order.id),
          arguments: OrderDetailsScreen(orderId: order.id, orderModel: order),
        ),
        radius: Dimensions.radiusLarge,
        child: Column(children: [

          // Header: logo + store name / address + chevron
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: Container(
                  height: 52, width: 52, alignment: Alignment.center,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  child: (image.isEmpty && isParcel)
                      ? Icon(Icons.local_shipping_outlined, color: Theme.of(context).primaryColor)
                      : CustomImage(image: image, height: 52, width: 52, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),

              Icon(Icons.chevron_right, color: Theme.of(context).disabledColor),
            ]),
          ),

          Divider(height: 1, thickness: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.12)),

          // Status + date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
            child: Row(children: [
              Container(height: 8, width: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Text(status.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: statusColor)),
              const Spacer(),
              Text(
                DateConverter.dateTimeStringToDateTime(order.createdAt!),
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor),
              ),
            ]),
          ),

          // Item count + total + action
          Padding(
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeSmall, Dimensions.paddingSizeSmall),
            child: Row(children: [
              if(!isParcel) ...[
                Text(
                  '${order.detailsCount ?? 0} ${(order.detailsCount ?? 0) > 1 ? 'items'.tr : 'item'.tr}',
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                  child: Text('•', style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
                ),
              ],
              Text(
                PriceConverter.convertPrice(order.orderAmount), textDirection: TextDirection.ltr,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
              const Spacer(),

              if(isRunning)
                _actionButton(context, filled: true, icon: Images.tracking, text: isParcel ? 'track_delivery'.tr : 'track_order'.tr,
                    onTap: () => Get.toNamed(RouteHelper.getOrderTrackingRoute(order.id, null)))
              else if(order.store != null && !isParcel)
                _actionButton(context, filled: false, text: 're_order'.tr,
                    onTap: () => Get.toNamed(RouteHelper.getStoreRoute(id: order.store!.id, page: 'store', slug: order.store!.slug ?? ''))),
            ]),
          ),

          // A completed order gets two rating entries side by side: the store on one half,
          // the delivery on the other. Delivery only shows when a delivery man was assigned
          // (service bookings have none), otherwise the store rating spans the row.
          if(_isCompleted(status)) ...[
            Divider(height: 1, thickness: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.12)),
            IntrinsicHeight(child: Row(children: [
              if(order.store != null) Expanded(child: _rateHalf(
                context, icon: Icons.storefront_outlined, label: 'rate_store'.tr,
                onTap: () => _openStoreReview(order),
              )),

              if(order.store != null && order.deliveryMan != null) VerticalDivider(
                width: 1, thickness: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
              ),

              if(order.deliveryMan != null) Expanded(child: _rateHalf(
                context, icon: Icons.delivery_dining_outlined, label: 'rate_delivery'.tr,
                onTap: () => _openReview(order),
              )),
            ])),
          ],

        ]),
      ),
    );
  }

  /// Green when done, red when cancelled/refunded, otherwise the brand colour for in-progress.
  Color _statusColor(BuildContext context, String status) {
    const Set<String> done = {'delivered', 'completed'};
    const Set<String> bad = {'canceled', 'cancelled', 'failed', 'refunded', 'refund_requested', 'refund_request_canceled'};
    if (done.contains(status)) return const Color(0xFF2E7D32);
    if (bad.contains(status)) return const Color(0xFFD32F2F);
    return Theme.of(context).primaryColor;
  }

  Widget _actionButton(BuildContext context, {required bool filled, String? icon, required String text, required VoidCallback onTap}) {
    final Color primary = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall + 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          color: filled ? primary : Colors.transparent,
          border: Border.all(color: primary, width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Image.asset(icon, height: 14, width: 14, color: filled ? Colors.white : primary),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          ],
          Text(text, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: filled ? Colors.white : primary)),
        ]),
      ),
    );
  }

  /// A finished order the customer can rate — delivered goods or a completed service booking.
  bool _isCompleted(String status) => status == 'delivered' || status == 'completed';

  /// One half of the completed-order rating strip: an icon, a label and a star.
  Widget _rateHalf(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeExtraSmall),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Flexible(child: Text(
            label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
          )),
          const SizedBox(width: 2),
          Icon(Icons.star_border, size: 16, color: Theme.of(context).primaryColor),
        ]),
      ),
    );
  }

  /// Opens the store's own review screen (separate from the item/delivery-man review).
  void _openStoreReview(OrderModel order) {
    if (order.store == null) return;
    Get.toNamed(RouteHelper.getStoreReviewRoute(
      order.store!.id, order.store!.name, order.store!, slug: order.store!.slug ?? '',
    ));
  }

  /// The order list doesn't carry the item details the review screen needs, so fetch them
  /// first (with a loader), then open the same rate-and-review flow the details screen uses.
  Future<void> _openReview(OrderModel order) async {
    Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
    await Get.find<OrderController>().getOrderDetails(order.id.toString());
    final List<OrderDetailsModel> details = Get.find<OrderController>().orderDetails ?? <OrderDetailsModel>[];

    // De-duplicate by item so each service/product is rated once.
    final List<OrderDetailsModel> uniqueDetails = <OrderDetailsModel>[];
    final List<int?> seenIds = <int?>[];
    for (final OrderDetailsModel detail in details) {
      if (!seenIds.contains(detail.itemDetails?.id)) {
        uniqueDetails.add(detail);
        seenIds.add(detail.itemDetails?.id);
      }
    }

    if (Get.isDialogOpen ?? false) Get.back(); // close loader

    Get.toNamed(RouteHelper.getReviewRoute(), arguments: RateReviewScreen(
      orderDetailsList: uniqueDetails,
      deliveryMan: order.deliveryMan,
      orderID: order.id,
      reviews: order.reviews,
    ));
  }
}
