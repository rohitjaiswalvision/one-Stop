import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/ongoing_order_model.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/ride_share_module/ride_order/controllers/ride_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class RunningOrderViewWidget extends StatelessWidget {
  final List<OrderData> reversOrder;
  final Function onOrderTap;
  const RunningOrderViewWidget({super.key, required this.reversOrder, required this.onOrderTap});

  /// Where the arrow lands. A service is booked for a slot rather than dispatched
  /// to an address, so there is no journey to follow — it opens the booking itself
  /// instead of the tracking map. `OrderData` carries no module, but this sheet
  /// only ever lists the current module's running orders.
  void _openRunningOrder(int? orderId) {
    Get.toNamed(ModuleHelper.isService()
        ? RouteHelper.getOrderDetailsRoute(orderId)
        : RouteHelper.getOrderTrackingRoute(orderId, null));
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderController>(builder: (orderController) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius : const BorderRadius.only(
            topLeft: Radius.circular(Dimensions.paddingSizeExtraLarge),
            topRight : Radius.circular(Dimensions.paddingSizeExtraLarge),
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
        ),
        child: Column(children: [

           Center(
            child: Container(
              margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
              height: 3, width: 40,
              decoration: BoxDecoration(
                  color: Theme.of(context).highlightColor,
                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)
              ),
            ),
           ),

           ListView.builder(
            itemCount: reversOrder.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemBuilder: (context, index){

              bool isFirstOrder =  index == 0;

              String? orderStatus = reversOrder[index].status;
              int status = 0;
              String orderType = reversOrder[index].orderType!;
              String displayType = (orderType == 'delivery' || orderType == 'order') ? 'order'.tr : orderType.tr;

              if(orderStatus == AppConstants.pending || orderStatus == AppConstants.accepted){
                status = 1;
              }else if(orderStatus == AppConstants.processing || orderStatus == AppConstants.confirmed){
                status = 2;
              }else if(orderStatus == AppConstants.handover || orderStatus == AppConstants.pickedUp){
                status = 3;
              }else if(orderStatus == AppConstants.delivered){
                status = 4;
              }

              return InkWell(
                onTap: () {
                  // Close the expandable sheet first, then navigate after the frame
                  if(orderController.showBottomSheet){
                    orderController.showRunningOrders();
                  }
                  if(orderType == 'order') {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Get.toNamed(RouteHelper.getOrderDetailsRoute(reversOrder[index].id));
                    });
                  } else if(orderType == 'ride') {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Get.find<RideController>().getCurrentRideStatus(fromRefresh: true, showCustomLoader: true);
                    });
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall, top: Dimensions.paddingSizeSmall),

                  child:  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    child: Row( crossAxisAlignment: CrossAxisAlignment.center, children: [

                      Center(
                        child: SizedBox(
                          height: (orderStatus == AppConstants.pending || orderStatus == AppConstants.accepted) ? 50 : 60,
                          width: (orderStatus == AppConstants.pending || orderStatus == AppConstants.accepted) ? 50 : 60,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset( status == 1 ? orderStatus == AppConstants.accepted ? Images.confirmedGif : Images.pendingGif
                                : status == 2 ? orderStatus == AppConstants.confirmed ? Images.confirmedGif : Images.processingGif
                                : status == 3 ? orderStatus == AppConstants.handover ? Images.handoverGif : Images.onTheWayGif : Images.pendingGif,
                        height: 60, width: 60, fit: BoxFit.fill),
                          ),
                        ),
                      ),

                      SizedBox(width: isFirstOrder ? 0 : Dimensions.paddingSizeSmall),

                      Expanded(
                        child: Column(mainAxisAlignment: isFirstOrder ? MainAxisAlignment.center : MainAxisAlignment.start,
                            crossAxisAlignment: isFirstOrder ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [
                              Row( mainAxisAlignment: isFirstOrder ? MainAxisAlignment.center : MainAxisAlignment.start, children: [

                                Text('${'your'.tr} $displayType ${'is'.tr} ', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                                Text(reversOrder[index].status!.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor)),
                              ]) ,
                              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                              Text(
                                '${'order'.tr} #${reversOrder[index].id}',
                                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall), maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),

                              isFirstOrder ? SizedBox(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault,
                                      vertical: Dimensions.paddingSizeSmall),
                                  child: Row(children: [
                                    Expanded(child: trackView(context, status: status >= 1 ? true : false)),
                                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                    Expanded(child: trackView(context, status: status >= 2 ? true : false)),
                                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                    Expanded(child: trackView(context, status: status >= 3 ? true : false)),
                                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                    Expanded(child: trackView(context, status: status >= 4 ? true : false)),
                                  ]),
                                ),
                              ) : const SizedBox()

                            ]),
                      ),

                      GestureDetector(
                        onTap: () {}, // absorbs touch so parent InkWell doesn't fire
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                          decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: isFirstOrder ? !(reversOrder.length < 2) ? InkWell(
                            onTap: () => onOrderTap(),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Text('+${reversOrder.length - 1}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor)),
                                  Text('more'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor)),
                                ]),
                              ) : InkWell(
                                onTap: () {
                                  if(orderController.showBottomSheet){
                                    orderController.showRunningOrders();
                                  }
                                  if(orderType == 'order') {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      _openRunningOrder(reversOrder[index].id);
                                    });
                                  } else if(orderType == 'ride') {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      Get.find<RideController>().getCurrentRideStatus(fromRefresh: true, showCustomLoader: true);
                                    });
                                  }
                                },
                                child: Icon(Icons.arrow_forward, size: 18, color: Theme.of(context).primaryColor),
                              )
                              : InkWell(
                                onTap: () {
                                  if(orderController.showBottomSheet){
                                    orderController.showRunningOrders();
                                  }
                                  if(orderType == 'order') {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      _openRunningOrder(reversOrder[index].id);
                                    });
                                  } else if(orderType == 'ride') {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      Get.find<RideController>().getCurrentRideStatus(fromRefresh: true, showCustomLoader: true);
                                    });
                                  }
                                },
                                child: Icon(Icons.arrow_forward, size: 18, color: Theme.of(context).primaryColor),
                              ),
                        ),
                      ),

                    ]),
                  ) ,
                ),
              );
            }),
         ]),
     );
    });
  }

  Widget trackView(BuildContext context, {required bool status}) {
    return Container(height: 5, decoration: BoxDecoration(color: status ? Theme.of(context).primaryColor
        : Theme.of(context).disabledColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)));
  }
}
