import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/checkout/domain/models/payment_model.dart';
import 'package:sixam_mart/features/checkout/widgets/payment_method_bottom_sheet.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/widgets/service_payment_amount_sheet.dart';
import 'package:sixam_mart/features/service_booking/controllers/service_booking_controller.dart';
import 'package:sixam_mart/features/service_booking/domain/models/appointment_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<ServiceBookingController>().getMyAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'my_appointments'.tr),
      body: GetBuilder<ServiceBookingController>(builder: (controller) {
        if(controller.appointmentsLoading && controller.appointments == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final List<Appointment> appointments = controller.appointments ?? [];
        if(appointments.isEmpty) {
          return Center(child: Text('no_appointments_found'.tr, style: robotoRegular.copyWith(
            color: Theme.of(context).disabledColor,
          )));
        }
        return RefreshIndicator(
          onRefresh: () => controller.getMyAppointments(),
          child: ListView.builder(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            itemCount: appointments.length,
            itemBuilder: (context, index) => _AppointmentCard(appointment: appointments[index], controller: controller),
          ),
        );
      }),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final ServiceBookingController controller;
  const _AppointmentCard({required this.appointment, required this.controller});

  @override
  Widget build(BuildContext context) {
    final bool cancelling = appointment.id != null && controller.isCancelling(appointment.id!);
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(appointment.item?.name ?? 'service'.tr, style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeLarge,
          ))),
          _statusChip(context, appointment.status),
        ]),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        _row(context, 'date'.tr, appointment.serviceDate ?? '-'),
        _row(context, 'time'.tr, '${appointment.startTime ?? '-'}${appointment.endTime != null ? ' - ${appointment.endTime}' : ''}'),
        _row(context, 'location'.tr, (appointment.locationType ?? '-').tr),
        _row(context, 'staff'.tr, appointment.staff?.name?.isNotEmpty == true ? appointment.staff!.name! : 'not_assigned_yet'.tr),
        if(appointment.store?.name != null) _row(context, 'provider'.tr, appointment.store!.name!),

        // Job finished, payment still due — collect it online now (pay after service).
        if(appointment.isPayable) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
              ),
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: Text('pay_now'.tr, style: robotoMedium.copyWith(color: Colors.white)),
              onPressed: () => _startPayment(context),
            ),
          ),
        ],

        if(appointment.isCancellable) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: cancelling ? null : () => _confirmCancel(context),
              child: cancelling
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('cancel_appointment'.tr, style: robotoMedium.copyWith(color: Theme.of(context).colorScheme.error)),
            ),
          ),
        ],
      ]),
    );
  }

  /// Opens the same payment-method sheet the "pay again" flow uses, driven by a
  /// PaymentModel fetched for this appointment's order. The sheet routes the customer
  /// through the gateway webview (`/payment-mobile?order_id=X`); on return we refresh
  /// so the now-paid appointment updates.
  Future<void> _startPayment(BuildContext context) async {
    final int? orderId = appointment.order?.id;
    if(orderId == null) return;
    // Read layout before the await so no BuildContext crosses the async gap.
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    final PaymentModel? paymentModel = await Get.find<OrderController>().getPaymentFailedDetails(orderId.toString());
    if(Get.isDialogOpen ?? false) Get.back();

    if(paymentModel == null) {
      showCustomSnackBar('payment_details_not_found'.tr);
      return;
    }

    // The customer first confirms/adjusts the payable amount (the final bill can
    // differ from the estimate), then settles online — digital gateways only, so the
    // commission split reaches the provider; cash/offline are intentionally not shown.
    ServicePaymentAmountSheet.show(
      initialAmount: paymentModel.orderAmount ?? 0,
      onProceed: (double amount) {
        // The adjusted amount rides in the paymentModel: the method sheet displays
        // it and the gateway URL carries it (see PaymentScreen `amount` param).
        paymentModel.orderAmount = amount;
        final Widget sheet = PaymentMethodBottomSheet(
          isCashOnDeliveryActive: false,
          isDigitalPaymentActive: true,
          totalPrice: amount,
          isOfflinePaymentActive: false,
          paymentModel: paymentModel,
        );
        if(isDesktop) {
          Get.dialog(Dialog(backgroundColor: Colors.transparent, child: sheet))
              .then((_) => controller.getMyAppointments());
        } else {
          Get.bottomSheet(sheet, backgroundColor: Colors.transparent, isScrollControlled: true)
              .then((_) => controller.getMyAppointments());
        }
      },
    );
  }

  void _confirmCancel(BuildContext context) {
    Get.dialog(AlertDialog(
      title: Text('cancel_appointment'.tr),
      content: Text('are_you_sure_to_cancel_this_appointment'.tr),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('no'.tr)),
        TextButton(onPressed: () {
          Get.back();
          if(appointment.id != null) controller.cancelAppointment(appointment.id!);
        }, child: Text('yes'.tr)),
      ],
    ));
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 90, child: Text(label, style: robotoRegular.copyWith(
          fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
        ))),
        Expanded(child: Text(value, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall))),
      ]),
    );
  }

  Widget _statusChip(BuildContext context, String? status) {
    final Color color = status == 'accepted'
        ? Colors.green
        : status == 'pending'
            ? Colors.orange
            : status == 'canceled' || status == 'cancelled'
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Text((status ?? '-').tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: color)),
    );
  }
}
