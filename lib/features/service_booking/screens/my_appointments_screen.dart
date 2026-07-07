import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/features/service_booking/controllers/service_booking_controller.dart';
import 'package:sixam_mart/features/service_booking/domain/models/appointment_model.dart';
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
