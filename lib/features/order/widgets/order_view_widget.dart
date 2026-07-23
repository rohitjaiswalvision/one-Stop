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

/// Statuses that mean an order didn't go through — split out into their own "Cancelled" tab
/// rather than sitting inside "Completed" alongside genuinely delivered/completed orders.
const Set<String> _cancelledStatuses = {'canceled', 'cancelled', 'failed', 'refunded', 'refund_requested', 'refund_request_canceled'};

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

/// True once a services order's work is actually finished, per the service_bookings the
/// vendor updates directly — read instead of orders.order_status, which can lag behind
/// (the vendor completes the booking without the parent order ever moving out of "running").
bool _isServiceOrderDone(OrderModel order) {
  final List<OrderServiceBooking>? bookings = order.serviceBookings;
  return order.orderStatus == 'delivered' || order.orderStatus == 'completed'
      || (bookings != null && bookings.isNotEmpty && bookings.every((b) => b.status == 'completed'));
}

/// Pay-after-service: the job is done but the customer has not settled yet, so the row
/// flags the outstanding payment. Same detection as the order-details Pay Now gate.
bool _isServicePaymentPending(OrderModel order) {
  return order.moduleType == AppConstants.service
      && order.paymentMethod == 'cash_on_delivery'
      && order.paymentStatus == 'unpaid'
      && _isServiceOrderDone(order);
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
  final String? moduleType;
  /// Only meaningful when [isRunning] is false: true shows just cancelled/refunded/failed
  /// orders (the "Cancelled" tab), false shows everything else (the "Completed" tab).
  final bool cancelledOnly;
  const OrderViewWidget({super.key, required this.isRunning, this.moduleType, this.cancelledOnly = false});

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

        bool isCancelled(OrderModel order) => _cancelledStatuses.contains(_orderDisplayStatus(order));
        bool isFinished(OrderModel order) => _isServiceOrderDone(order) || isCancelled(order);

        List<OrderModel> filteredOrders;
        if(moduleType == AppConstants.service) {
          // Services orders can be marked done (or cancelled) at the booking level while
          // orders.order_status still parks them under "running" — so route by that real
          // state instead of which API list the order came from, merging in anything the
          // backend already moved to history so nothing is double-counted.
          final List<OrderModel> runningServiceOrders = (orderController.runningOrderModel?.orders ?? <OrderModel>[])
              .where((order) => order.moduleType == AppConstants.service).toList();
          final List<OrderModel> historyServiceOrders = (orderController.historyOrderModel?.orders ?? <OrderModel>[])
              .where((order) => order.moduleType == AppConstants.service).toList();

          if(isRunning) {
            filteredOrders = runningServiceOrders.where((order) => !isFinished(order)).toList();
          } else {
            final Set<int?> historyIds = historyServiceOrders.map((order) => order.id).toSet();
            final List<OrderModel> finishedPool = [
              ...historyServiceOrders,
              ...runningServiceOrders.where((order) => isFinished(order) && !historyIds.contains(order.id)),
            ];
            filteredOrders = finishedPool.where((order) => isCancelled(order) == cancelledOnly).toList();
          }
        } else {
          filteredOrders = moduleType == null
              ? (paginatedOrderModel?.orders ?? <OrderModel>[])
              : (paginatedOrderModel?.orders ?? <OrderModel>[]).where((order) => order.moduleType == moduleType).toList();
          if(!isRunning) {
            filteredOrders = filteredOrders.where((order) => isCancelled(order) == cancelledOnly).toList();
          }
        }

        return paginatedOrderModel != null ? filteredOrders.isNotEmpty ? RefreshIndicator(
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
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final OrderModel order = filteredOrders[index];
                        bool isParcel = order.orderType == 'parcel';
                        bool isPrescription = order.prescriptionOrder!;

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
                                RouteHelper.getOrderDetailsRoute(order.id),
                                arguments: OrderDetailsScreen(
                                  orderId: order.id,
                                  orderModel: order,
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
                                        image: isParcel ? '${order.parcelCategory != null ? order.parcelCategory!.imageFullUrl : ''}'
                                            : '${order.store != null ? order.store!.logoFullUrl : ''}',
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
                                      Text('#${order.id}', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
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
                                          child: Text(_orderDisplayStatus(order).tr, style: robotoMedium.copyWith(
                                            fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor,
                                          )),
                                        ),
                                        if(_isServicePaymentPending(order)) ...[
                                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                          _paymentPendingChip(context),
                                        ],
                                      ]),
                                    ) : const SizedBox(),

                                    Text(
                                      DateConverter.dateTimeStringToDateTime(order.createdAt!),
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
                                    child: Text(_orderDisplayStatus(order).tr, style: robotoMedium.copyWith(
                                      fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor,
                                    )),
                                  ) : const SizedBox(),
                                  if(!ResponsiveHelper.isDesktop(context) && _isServicePaymentPending(order)) ...[
                                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                    _paymentPendingChip(context),
                                  ],
                                  const SizedBox(height: Dimensions.paddingSizeSmall),

                                  isRunning ? InkWell(
                                    onTap: () => Get.toNamed(RouteHelper.getOrderTrackingRoute(order.id, null)),
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
                                    '${order.detailsCount} ${order.detailsCount! > 1 ? 'items'.tr : 'item'.tr}',
                                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
                                  ),
                                ]),

                              ]),

                              (index == filteredOrders.length-1 || ResponsiveHelper.isDesktop(context)) ? const SizedBox() : Padding(
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
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) => _orderCard(context, filteredOrders[index]),
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
              // else if(order.store != null && !isParcel)
              //   _actionButton(context, filled: false, text: 're_order'.tr,
              //       onTap: () => Get.toNamed(RouteHelper.getStoreRoute(id: order.store!.id, page: 'store', slug: order.store!.slug ?? ''))),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                DateConverter.dateTimeStringToDateTime(order.createdAt!),
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor),
              ),
            ]),
          ),

          // A completed order gets two star-rating rows side by side: the food/items on one
          // half, the delivery man on the other (delivery only shows when one was assigned —
          // service bookings have none). Below that, a full-width Reorder pill plus an
          // "Ordered: <date> • Bill Total: <amount>" footer, mirroring the marketplace-app pattern.
          if(_isCompleted(status)) ...[
            Divider(height: 1, thickness: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
              child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if(order.store != null) Expanded(child: _starRatingRow(
                  context, label: _foodRatingLabel(order), rating: _averageFoodRating(order),
                  // Already rated (reviews/submit only accepts one rating per item per order) —
                  // show the given stars as a read-only summary instead of reopening the form.
                  onTap: _hasFoodRating(order) ? null : () => _openReview(order),
                )),

                if(order.store != null && order.deliveryMan != null) const SizedBox(width: Dimensions.paddingSizeDefault),

                if(order.deliveryMan != null) Expanded(child: _starRatingRow(
                  context, label: 'delivery_rating'.tr, rating: order.deliveryManReview?.rating ?? 0,
                  // Same one-time-rating rule as the food row, keyed off the delivery man review.
                  onTap: order.deliveryManReview != null ? null : () => _openReview(order, openDeliveryTab: true),
                )),
              ])),
            ),

            if(order.store != null && !isParcel) Padding(
              padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
              child: Column(children: [ 
                InkWell(
                  onTap: () => Get.toNamed(RouteHelper.getStoreRoute(id: order.store!.id, page: 'store', slug: order.store!.slug ?? '')),
                  borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('re_order'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 16, color: Theme.of(context).primaryColor),
                    ]),
                  ),
                ),
                // const SizedBox(height: Dimensions.paddingSizeSmall),
                // Text(
                //   '${'ordered'.tr}: ${DateConverter.dateTimeStringToDateTime(order.createdAt!)} • ${'bill_total'.tr}: ${PriceConverter.convertPrice(order.orderAmount)}',
                //   style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor),
                // ),
              ]),
            ),
          ],

        ]),
      ),
    );
  }

  /// Green when done, red when cancelled/refunded, otherwise the brand colour for in-progress.
  Color _statusColor(BuildContext context, String status) {
    const Set<String> done = {'delivered', 'completed'};
    if (done.contains(status)) return const Color(0xFF2E7D32);
    if (_cancelledStatuses.contains(status)) return const Color(0xFFD32F2F);
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

  /// "Your Food Rating" for a food order, a generic "Your Order Rating" for every other module.
  String _foodRatingLabel(OrderModel order) {
    return order.moduleType == AppConstants.food ? 'your_food_rating'.tr : 'your_order_rating'.tr;
  }

  /// The order list has no per-order "my rating" field — only per-item reviews already left
  /// on this order — so show the average of those (0 stars, i.e. unrated, when there are none).
  int _averageFoodRating(OrderModel order) {
    final List<Reviews>? reviews = order.reviews;
    if (reviews == null || reviews.isEmpty) return 0;
    final int sum = reviews.fold(0, (int total, Reviews r) => total + (r.rating ?? 0));
    return (sum / reviews.length).round();
  }

  /// reviews/submit only accepts one rating per item per order — once any review exists here,
  /// treat the item/service as already rated instead of offering to rate it again.
  bool _hasFoodRating(OrderModel order) => order.reviews?.isNotEmpty ?? false;

  /// One rating row of the completed-order strip: a label above a row of 5 stars.
  /// [rating] fills that many stars; the rest render outlined. A null [onTap] renders the
  /// row as a static read-only summary (already rated, tapping again would resubmit).
  Widget _starRatingRow(BuildContext context, {required String label, required int rating, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          label, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Row(children: List.generate(5, (int i) => Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            i < rating ? Icons.star : Icons.star_border, size: 18,
            color: i < rating ? Colors.amber : Theme.of(context).disabledColor,
          ),
        ))),
      ]),
    );
  }

  /// The order list doesn't carry the item details the review screen needs, so fetch them
  /// first (with a loader), then open the same rate-and-review flow the details screen uses.
  /// [openDeliveryTab] jumps straight to the delivery-man tab (used by the "Delivery Rating" row).
  Future<void> _openReview(OrderModel order, {bool openDeliveryTab = false}) async {
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

    // Wait for the rating screen to close, then refresh the list — the order object held
    // here is a snapshot from the last fetch, so a rating just submitted won't show on this
    // card until the list is re-fetched (otherwise it only appears after a manual pull-to-refresh).
    await Get.toNamed(RouteHelper.getReviewRoute(), arguments: RateReviewScreen(
      orderDetailsList: uniqueDetails,
      deliveryMan: order.deliveryMan,
      orderID: order.id,
      reviews: order.reviews,
      initialTabIndex: openDeliveryTab ? 1 : 0,
    ));

    if(isRunning) {
      await Get.find<OrderController>().getRunningOrders(1, isUpdate: true);
    } else {
      await Get.find<OrderController>().getHistoryOrders(1, isUpdate: true);
    }
  }
}
