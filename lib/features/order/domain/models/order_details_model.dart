import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';

class OrderDetailsModel {
  int? id;
  int? itemId;
  int? orderId;
  double? price;
  Item? itemDetails;
  List<Variation>? variation;
  List<FoodVariation>? foodVariation;
  List<AddOn>? addOns;
  double? discountOnItem;
  String? discountType;
  int? quantity;
  double? taxAmount;
  String? variant;
  String? createdAt;
  String? updatedAt;
  int? itemCampaignId;
  double? totalAddOnPrice;
  String? imageFullUrl;
  int? isGuest;
  ParcelCancellation? parcelCancellation;

  /// Services module: the booking attached to this order line, carrying what the
  /// staff added on-site (extra services, extra amount) and the completion note.
  DetailServiceBooking? serviceBooking;

  OrderDetailsModel({
    this.id,
    this.itemId,
    this.orderId,
    this.price,
    this.itemDetails,
    this.variation,
    this.foodVariation,
    this.addOns,
    this.discountOnItem,
    this.discountType,
    this.quantity,
    this.taxAmount,
    this.variant,
    this.createdAt,
    this.updatedAt,
    this.itemCampaignId,
    this.totalAddOnPrice,
    this.imageFullUrl,
    this.isGuest,
    this.parcelCancellation,
    this.serviceBooking,
  });

  OrderDetailsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    itemId = json['item_id'];
    orderId = json['order_id'];
    price = json['price'].toDouble();
    itemDetails = json['item_details'] != null ? Item.fromJson(json['item_details']) : null;
    variation = [];
    foodVariation = [];
    if (json['variation'] != null && json['variation'].isNotEmpty) {
      if (json['variation'][0]['values'] != null) {
        json['variation'].forEach((v) {
          foodVariation!.add(FoodVariation.fromJson(v));
        });
      } else {
        json['variation'].forEach((v) {
          variation!.add(Variation.fromJson(v));
        });
      }
    }
    if (json['add_ons'] != null) {
      addOns = [];
      json['add_ons'].forEach((v) {
        addOns!.add(AddOn.fromJson(v));
      });
    }
    discountOnItem = json['discount_on_item']?.toDouble();
    discountType = json['discount_type'];
    quantity = json['quantity'];
    taxAmount = json['tax_amount']?.toDouble();
    variant = json['variant'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    itemCampaignId = json['item_campaign_id'];
    totalAddOnPrice = json['total_add_on_price']?.toDouble();
    imageFullUrl = json['image_full_url'];
    isGuest = json['is_guest'];
    parcelCancellation = json['parcel_cancellation'] != null ? ParcelCancellation.fromJson(json['parcel_cancellation']) : null;
    serviceBooking = json['service_booking'] is Map<String, dynamic> ? DetailServiceBooking.fromJson(json['service_booking']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['item_id'] = itemId;
    data['order_id'] = orderId;
    data['price'] = price;
    if (itemDetails != null) {
      data['item_details'] = itemDetails!.toJson();
    }
    if (variation != null) {
      data['variation'] = variation!.map((v) => v.toJson()).toList();
    } else if (foodVariation != null) {
      data['variation'] = foodVariation!.map((v) => v.toJson()).toList();
    }
    if (addOns != null) {
      data['add_ons'] = addOns!.map((v) => v.toJson()).toList();
    }
    data['discount_on_item'] = discountOnItem;
    data['discount_type'] = discountType;
    data['quantity'] = quantity;
    data['tax_amount'] = taxAmount;
    data['variant'] = variant;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['item_campaign_id'] = itemCampaignId;
    data['total_add_on_price'] = totalAddOnPrice;
    data['image_full_url'] = imageFullUrl;
    data['is_guest'] = isGuest;
    if (parcelCancellation != null) {
      data['parcel_cancellation'] = parcelCancellation!.toJson();
    }
    if (serviceBooking != null) {
      data['service_booking'] = serviceBooking!.toJson();
    }
    return data;
  }
}

/// The `service_booking` object nested inside an order detail row of a services-module
/// order. Everything here is optional: the staff may add extra services and an extra
/// amount while on the job, and leaves a completion note when the work is done.
class DetailServiceBooking {
  int? id;
  String? status;
  double? additionalAmount;
  String? completionNote;
  List<BookingAdditionalService>? additionalServices;

  DetailServiceBooking({this.id, this.status, this.additionalAmount, this.completionNote, this.additionalServices});

  DetailServiceBooking.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    status = json['status'];
    additionalAmount = json['additional_amount'] != null ? double.tryParse(json['additional_amount'].toString()) : null;
    completionNote = json['completion_note'];
    if (json['additional_services'] is List) {
      additionalServices = [];
      for (final dynamic v in json['additional_services']) {
        if (v is Map<String, dynamic>) {
          additionalServices!.add(BookingAdditionalService.fromJson(v));
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['status'] = status;
    data['additional_amount'] = additionalAmount;
    data['completion_note'] = completionNote;
    if (additionalServices != null) {
      data['additional_services'] = additionalServices!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class BookingAdditionalService {
  String? name;
  double? price;

  BookingAdditionalService({this.name, this.price});

  BookingAdditionalService.fromJson(Map<String, dynamic> json) {
    name = json['name']?.toString();
    price = json['price'] != null ? double.tryParse(json['price'].toString()) : null;
  }

  Map<String, dynamic> toJson() => {'name': name, 'price': price};
}

class AddOn {
  String? name;
  double? price;
  int? quantity;

  AddOn({
    this.name,
    this.price,
    this.quantity,
  });

  AddOn.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    price = json['price'].toDouble();
    quantity = int.parse(json['quantity'].toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['price'] = price;
    data['quantity'] = quantity;
    return data;
  }
}
