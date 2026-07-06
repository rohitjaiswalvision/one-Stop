import 'dart:async';
import 'dart:collection';
import 'package:sixam_mart/api/api_client.dart';

import 'package:geolocator/geolocator.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/widgets/permission_dialog_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/marker_helper.dart';
import 'package:sixam_mart/helper/pusher_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/features/order/widgets/track_details_view_widget.dart';
import 'package:sixam_mart/features/order/widgets/tracking_stepper_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String? orderID;
  final String? contactNumber;
  const OrderTrackingScreen({super.key, required this.orderID, this.contactNumber});

  @override
  OrderTrackingScreenState createState() => OrderTrackingScreenState();
}

class OrderTrackingScreenState extends State<OrderTrackingScreen> with WidgetsBindingObserver {
  GoogleMapController? _controller;
  bool _isLoading = true;
  Set<Marker> _markers = HashSet<Marker>();
  Set<Polyline> _polylines = HashSet<Polyline>();
  Timer? _timer;
  bool showChatPermission = true;
  bool isHovered = false;

  void _loadData() async {
    await Get.find<LocationController>().getCurrentLocation(true, notify: false, defaultLatLng: LatLng(
      double.parse(AddressHelper.getUserAddressFromSharedPref()!.latitude!),
      double.parse(AddressHelper.getUserAddressFromSharedPref()!.longitude!),
    ));
    await Get.find<OrderController>().trackOrder(widget.orderID, null, true, contactNumber: widget.contactNumber);

    final track = Get.find<OrderController>().trackModel;
    if (track != null) {
      _fetchAndDrawRoute(track);
    }

    if(Get.find<SplashController>().configModel!.websocketEnabled!) {
      _trackWithPusher();
    } else {
      _timerTrackOrder();
    }
  }

  void _trackWithPusher() {
    bool canTrackDeliveryman = Get.find<OrderController>().trackModel?.orderStatus != 'delivered' && Get.find<OrderController>().trackModel?.orderStatus != 'failed' && Get.find<OrderController>().trackModel?.orderStatus != 'canceled';
    if(Get.find<OrderController>().trackModel != null && Get.find<OrderController>().trackModel!.deliveryMan != null && canTrackDeliveryman) {
      Get.find<OrderController>().timerTrackOrder(widget.orderID.toString(), contactNumber: widget.contactNumber);

      PusherHelper().pusherDriverStatus(
        deliverymanId: Get.find<OrderController>().trackModel!.deliveryMan!.id.toString(),
        onLocationReceived: (RecordLocationBodyModel dmLocation) {
          updateDeliverymanMarker(dmLocation);
        },
      );


    }
  }

  void _timerTrackOrder(){
    if(Get.find<OrderController>().trackModel?.orderStatus != 'delivered' && Get.find<OrderController>().trackModel?.orderStatus != 'failed' && Get.find<OrderController>().trackModel?.orderStatus != 'canceled') {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if(Get.currentRoute.contains(RouteHelper.orderDetails) || Get.currentRoute.contains(RouteHelper.orderTracking)){
          Get.find<OrderController>().timerTrackOrder(widget.orderID.toString(), contactNumber: widget.contactNumber).then((_) {
            if(!mounted) return;
            if(Get.find<OrderController>().trackModel != null) {
              updateMarker(
                Get.find<OrderController>().trackModel?.store, Get.find<OrderController>().trackModel!.deliveryMan,
                Get.find<OrderController>().trackModel?.orderType == 'take_away' ? Get.find<LocationController>().position.latitude == 0 ? Get.find<OrderController>().trackModel?.deliveryAddress : AddressModel(
                  latitude: Get.find<LocationController>().position.latitude.toString(),
                  longitude: Get.find<LocationController>().position.longitude.toString(),
                  address: Get.find<LocationController>().address,
                ) : Get.find<OrderController>().trackModel?.deliveryAddress,
                Get.find<OrderController>().trackModel?.orderType == 'take_away', Get.find<OrderController>().trackModel?.orderType == 'parcel', Get.find<OrderController>().trackModel?.moduleType == 'food',
              );
            }
          });
        } else {
          _timer?.cancel();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    PusherHelper.initializePusher();
    _loadData();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _timerTrackOrder();
    }else if(state == AppLifecycleState.paused){
      _timer?.cancel();
      _controller?.dispose();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller?.dispose();
    _timer?.cancel();
    PusherHelper().pusherDisconnectPusher();
    WidgetsBinding.instance.removeObserver(this);
  }

  void onEntered(bool isHovered) {
    setState(() {
      this.isHovered = isHovered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'order_tracking'.tr),
      endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,
      body: GetBuilder<OrderController>(builder: (orderController) {
        OrderModel? track;
        if(orderController.trackModel != null) {
          track = orderController.trackModel;

          if(track!.orderType != 'parcel') {
            if (track.store!.storeBusinessModel == 'commission') {
              showChatPermission = true;
            } else if (track.store!.storeSubscription != null && track.store!.storeBusinessModel == 'subscription') {
              showChatPermission = track.store!.storeSubscription!.chat == 1;
            } else {
              showChatPermission = false;
            }
          } else {
            showChatPermission = AuthHelper.isLoggedIn();
          }
        }

        return track != null ? SingleChildScrollView(
          physics: isHovered || !ResponsiveHelper.isDesktop(context) ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
          child: FooterView(
            child: Center(child: SizedBox(width: Dimensions.webMaxWidth, height: ResponsiveHelper.isDesktop(context) ? 700 : MediaQuery.of(context).size.height * 0.85, child: Stack(children: [

              MouseRegion(
                onEnter: (event) => onEntered(true),
                onExit: (event) => onEntered(false),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: LatLng(
                    double.parse(track.deliveryAddress!.latitude!), double.parse(track.deliveryAddress!.longitude!),
                  ), zoom: 16),
                  minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
                  zoomControlsEnabled: false,
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (GoogleMapController controller) {
                    _controller = controller;
                    _isLoading = false;
                    setMarker(
                      track!.orderType == 'parcel' ? Store(latitude: track.receiverDetails!.latitude, longitude: track.receiverDetails!.longitude,
                          address: track.receiverDetails!.address, name: track.receiverDetails!.contactPersonName) : track.store, track.deliveryMan,
                      track.orderType == 'take_away' ? Get.find<LocationController>().position.latitude == 0 ? track.deliveryAddress : AddressModel(
                        latitude: Get.find<LocationController>().position.latitude.toString(),
                        longitude: Get.find<LocationController>().position.longitude.toString(),
                        address: Get.find<LocationController>().address,
                      ) : track.deliveryAddress, track.orderType == 'take_away', track.orderType == 'parcel', track.moduleType == 'food',
                    );
                    _fetchAndDrawRoute(track);
                  },
                  style: Get.isDarkMode ? Get.find<ThemeController>().darkMap : Get.find<ThemeController>().lightMap,
                ),
              ),

              _isLoading ? const Center(child: CircularProgressIndicator()) : const SizedBox(),

              Positioned(
                top: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
                child: TrackingStepperWidget(status: track.orderStatus, takeAway: track.orderType == 'take_away'),
              ),

              Positioned(
                right: 15, bottom: track.orderType != 'take_away' && track.deliveryMan == null ? 150 : 220,
                child: InkWell(
                  onTap: () => _checkPermission(() async {
                    AddressModel address = await Get.find<LocationController>().getCurrentLocation(false, mapController: _controller);
                    setMarker(
                      track!.orderType == 'parcel' ? Store(latitude: track.receiverDetails!.latitude, longitude: track.receiverDetails!.longitude,
                          address: track.receiverDetails!.address, name: track.receiverDetails!.contactPersonName) : track.store, track.deliveryMan,
                      track.orderType == 'take_away' ? Get.find<LocationController>().position.latitude == 0 ? track.deliveryAddress : AddressModel(
                        latitude: Get.find<LocationController>().position.latitude.toString(),
                        longitude: Get.find<LocationController>().position.longitude.toString(),
                        address: Get.find<LocationController>().address,
                      ) : track.deliveryAddress, track.orderType == 'take_away', track.orderType == 'parcel', track.moduleType == 'food',
                      currentAddress: address, fromCurrentLocation: true,
                    );
                  }),
                  child: Container(
                    padding: const EdgeInsets.all( Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: Colors.white),
                    child: Icon(Icons.my_location_outlined, color: Theme.of(context).primaryColor, size: 25),
                  ),
                ),
              ),

              Positioned(
                bottom: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
                child: TrackDetailsViewWidget(status: track.orderStatus, track: track, showChatPermission: showChatPermission, callback: () async{
                  bool takeAway = track?.orderType == 'take_away';
                  _timer?.cancel();
                  await Get.toNamed(RouteHelper.getChatRoute(
                    notificationBody: takeAway ? NotificationBodyModel(restaurantId: track!.store!.id, orderId: int.parse(widget.orderID!))
                        : NotificationBodyModel(deliverymanId: track!.deliveryMan!.id, orderId: int.parse(widget.orderID!)),
                    user: User(
                      id: takeAway ? track.store!.id : track.deliveryMan!.id,
                      fName: takeAway ? track.store!.name : track.deliveryMan!.fName,
                      lName: takeAway ? '' : track.deliveryMan!.lName,
                      imageFullUrl: takeAway ? track.store!.logoFullUrl : track.deliveryMan!.imageFullUrl,
                    ),
                  ));
                  _timerTrackOrder();
                }),
              ),

            ]))),
          ),
        ) : const Center(child: CircularProgressIndicator());
      }),
    );
  }

  void setMarker(Store? store, DeliveryMan? deliveryMan, AddressModel? addressModel, bool takeAway, bool parcel, bool isRestaurant, {AddressModel? currentAddress, bool fromCurrentLocation = false}) async {
    try {

      BitmapDescriptor restaurantImageData = await MarkerHelper.convertAssetToBitmapDescriptor(
        width: 30, imagePath: parcel ? Images.userMarker : isRestaurant ? Images.restaurantMarker : Images.markerStore,
      );

      BitmapDescriptor deliveryBoyImageData = await MarkerHelper.convertAssetToBitmapDescriptor(
        width: 30, imagePath: Images.deliveryManMarker,
      );
      BitmapDescriptor destinationImageData = await MarkerHelper.convertAssetToBitmapDescriptor(
        width: 30, imagePath: Images.userMarker,
      );

      /// Animate to coordinate
      LatLngBounds? bounds;
      double rotation = 0;
      if(_controller != null) {
        if (double.parse(addressModel!.latitude!) < double.parse(store!.latitude!)) {
          bounds = LatLngBounds(
            southwest: LatLng(double.parse(addressModel.latitude!), double.parse(addressModel.longitude!)),
            northeast: LatLng(double.parse(store.latitude!), double.parse(store.longitude!)),
          );
          rotation = 0;
        }else {
          bounds = LatLngBounds(
            southwest: LatLng(double.parse(store.latitude!), double.parse(store.longitude!)),
            northeast: LatLng(double.parse(addressModel.latitude!), double.parse(addressModel.longitude!)),
          );
          rotation = 180;
        }
      }
      LatLng centerBounds = LatLng(
        (bounds!.northeast.latitude + bounds.southwest.latitude)/2,
        (bounds.northeast.longitude + bounds.southwest.longitude)/2,
      );

      if(fromCurrentLocation && currentAddress != null) {
        LatLng currentLocation = LatLng(
          double.parse(currentAddress.latitude!),
          double.parse(currentAddress.longitude!),
        );
        _controller!.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(target: currentLocation, zoom: GetPlatform.isWeb ? 7 : 15)));
      }

      if(!fromCurrentLocation) {
        _controller!.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(target: centerBounds, zoom: GetPlatform.isWeb ? 10 : 17)));
        if(!ResponsiveHelper.isWeb()) {
          zoomToFit(_controller, bounds, centerBounds, padding: GetPlatform.isWeb ? 15 : 3);
        }
      }

      /// user for normal order , but sender for parcel order
      _markers = HashSet<Marker>();

      ///current location marker set
      if(currentAddress != null) {
        _markers.add(Marker(
          markerId: const MarkerId('current_location'),
          visible: true,
          draggable: false,
          zIndexInt: 2,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          position: LatLng(
            double.parse(currentAddress.latitude!),
            double.parse(currentAddress.longitude!),
          ),
          icon: destinationImageData,
        ));
        setState(() {});
      }

      if(currentAddress == null){
        addressModel != null ? _markers.add(Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(double.parse(addressModel.latitude!), double.parse(addressModel.longitude!)),
          infoWindow: InfoWindow(
            title: parcel ? 'sender'.tr : 'Destination'.tr,
            snippet: addressModel.address,
          ),
          icon: destinationImageData,
        )) : const SizedBox();
      }

      ///store for normal order , but receiver for parcel order
      store != null ? _markers.add(Marker(
        markerId: const MarkerId('store'),
        position: LatLng(double.parse(store.latitude!), double.parse(store.longitude!)),
        infoWindow: InfoWindow(
          title: parcel ? 'receiver'.tr : Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText! ? 'store'.tr : 'store'.tr,
          snippet: store.address,
        ),
        icon: restaurantImageData,
      )) : const SizedBox();

      deliveryMan != null ? _markers.add(Marker(
        markerId: const MarkerId('delivery_boy'),
        position: LatLng(double.parse(deliveryMan.lat ?? '0'), double.parse(deliveryMan.lng ?? '0')),
        infoWindow: InfoWindow(
          title: 'delivery_man'.tr,
          snippet: deliveryMan.location,
        ),
        rotation: rotation,
        icon: deliveryBoyImageData,
      )) : const SizedBox();

    }catch(_) {}
    setState(() {});
    // Draw route polyline after initial markers are set
    final track = Get.find<OrderController>().trackModel;
    if(track != null) _fetchAndDrawRoute(track);
  }

  Future<void> updateDeliverymanMarker(RecordLocationBodyModel dmLocation) async {
    if (!mounted) return;
    BitmapDescriptor deliveryBoyImageData = await MarkerHelper.convertAssetToBitmapDescriptor(
      width: 30, imagePath: Images.deliveryManMarker,
    );

    if(dmLocation.latitude != null && dmLocation.latitude!.isNotEmpty) {
      double rotation = 0;
      if (Get.find<OrderController>().trackModel?.deliveryMan != null) {
        double oldLat = double.tryParse(Get.find<OrderController>().trackModel!.deliveryMan!.lat ?? '0') ?? 0;
        double oldLng = double.tryParse(Get.find<OrderController>().trackModel!.deliveryMan!.lng ?? '0') ?? 0;
        double newLat = double.tryParse(dmLocation.latitude ?? '0') ?? 0;
        double newLng = double.tryParse(dmLocation.longitude ?? '0') ?? 0;
        if (oldLat != 0 && oldLng != 0 && newLat != 0 && newLng != 0 && (oldLat != newLat || oldLng != newLng)) {
          rotation = Geolocator.bearingBetween(oldLat, oldLng, newLat, newLng);
        }
      }

      _markers.removeWhere((m) => m.markerId.value == 'delivery_boy');
      _markers.add(Marker(
        markerId: const MarkerId('delivery_boy'),
        position: LatLng(double.parse(dmLocation.latitude ?? '0'), double.parse(dmLocation.longitude ?? '0')),
        infoWindow: InfoWindow(
          title: 'delivery_man'.tr,
          snippet: dmLocation.location,
        ),
        rotation: rotation,
        icon: deliveryBoyImageData,
      ));

      if (Get.find<OrderController>().trackModel?.deliveryMan != null) {
        Get.find<OrderController>().trackModel!.deliveryMan!.lat = dmLocation.latitude;
        Get.find<OrderController>().trackModel!.deliveryMan!.lng = dmLocation.longitude;
      }

      if(mounted) setState(() { });
      final track = Get.find<OrderController>().trackModel;
      if (track != null) _fetchAndDrawRoute(track);
    }
  }

  void updateMarker(Store? store, DeliveryMan? deliveryMan, AddressModel? addressModel, bool takeAway, bool parcel, bool isRestaurant, {AddressModel? currentAddress, bool fromCurrentLocation = false}) async {
    try {

      BitmapDescriptor restaurantImageData = await MarkerHelper.convertAssetToBitmapDescriptor(
        width: 30, imagePath: parcel ? Images.userMarker : isRestaurant ? Images.restaurantMarker : Images.markerStore,
      );

      BitmapDescriptor deliveryBoyImageData = await MarkerHelper.convertAssetToBitmapDescriptor(
        width: 30, imagePath: Images.deliveryManMarker,
      );
      BitmapDescriptor destinationImageData = await MarkerHelper.convertAssetToBitmapDescriptor(
        width: 30, imagePath: Images.userMarker,
      );

      LatLngBounds? bounds;
      debugPrint(bounds.toString());
      double rotation = 0;
      if(_controller != null) {
        if (double.parse(addressModel!.latitude!) < double.parse(store!.latitude!)) {
          bounds = LatLngBounds(
            southwest: LatLng(double.parse(addressModel.latitude!), double.parse(addressModel.longitude!)),
            northeast: LatLng(double.parse(store.latitude!), double.parse(store.longitude!)),
          );
          rotation = 0;
        }else {
          bounds = LatLngBounds(
            southwest: LatLng(double.parse(store.latitude!), double.parse(store.longitude!)),
            northeast: LatLng(double.parse(addressModel.latitude!), double.parse(addressModel.longitude!)),
          );
          rotation = 180;
        }
      }

      /// user for normal order , but sender for parcel order
      _markers = HashSet<Marker>();

      ///current location marker set
      if(currentAddress != null) {
        _markers.add(Marker(
          markerId: const MarkerId('current_location'),
          visible: true,
          draggable: false,
          zIndexInt: 2,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          position: LatLng(
            double.parse(currentAddress.latitude!),
            double.parse(currentAddress.longitude!),
          ),
          icon: destinationImageData,
        ));
        setState(() {});
      }

      if(currentAddress == null){
        addressModel != null ? _markers.add(Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(double.parse(addressModel.latitude!), double.parse(addressModel.longitude!)),
          infoWindow: InfoWindow(
            title: parcel ? 'sender'.tr : 'Destination'.tr,
            snippet: addressModel.address,
          ),
          icon: destinationImageData,
        )) : const SizedBox();
      }

      ///store for normal order , but receiver for parcel order
      store != null ? _markers.add(Marker(
        markerId: const MarkerId('store'),
        position: LatLng(double.parse(store.latitude!), double.parse(store.longitude!)),
        infoWindow: InfoWindow(
          title: parcel ? 'receiver'.tr : Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText! ? 'store'.tr : 'store'.tr,
          snippet: store.address,
        ),
        icon: restaurantImageData,
      )) : const SizedBox();

      deliveryMan != null ? _markers.add(Marker(
        markerId: const MarkerId('delivery_boy'),
        position: LatLng(double.parse(deliveryMan.lat ?? '0'), double.parse(deliveryMan.lng ?? '0')),
        infoWindow: InfoWindow(
          title: 'delivery_man'.tr,
          snippet: deliveryMan.location,
        ),
        rotation: rotation,
        icon: deliveryBoyImageData,
      )) : const SizedBox();

    }catch(_) {}
    if(mounted) setState(() {});
    // Draw route polyline after markers are updated
    if(mounted) {
      final track = Get.find<OrderController>().trackModel;
      if(track != null) _fetchAndDrawRoute(track);
    }
  }

  /// Fetches the route from deliveryman (or store/sender) → customer (or receiver) and draws the blue polyline.
  Future<void> _fetchAndDrawRoute(OrderModel track) async {
    if (!mounted) return;
    try {
      // Determine origin: deliveryman location if available, else store or parcel sender address
      String? originLat, originLng;
      if (track.deliveryMan != null && (track.deliveryMan!.lat?.isNotEmpty ?? false) && track.deliveryMan!.lat != '0') {
        originLat = track.deliveryMan!.lat;
        originLng = track.deliveryMan!.lng;
      } else if (track.orderType == 'parcel' && track.deliveryAddress != null) {
        originLat = track.deliveryAddress!.latitude;
        originLng = track.deliveryAddress!.longitude;
      } else if (track.store != null) {
        originLat = track.store!.latitude;
        originLng = track.store!.longitude;
      }

      // Determine destination: customer delivery address or parcel receiver address
      String? destLat, destLng;
      if (track.orderType == 'parcel' && track.receiverDetails != null) {
        destLat = track.receiverDetails!.latitude;
        destLng = track.receiverDetails!.longitude;
      } else if (track.deliveryAddress != null) {
        destLat = track.deliveryAddress!.latitude;
        destLng = track.deliveryAddress!.longitude;
      }

      if (originLat == null || originLng == null || destLat == null || destLng == null) {
        debugPrint('====> _fetchAndDrawRoute: Missing origin or destination coordinates ($originLat, $originLng -> $destLat, $destLng)');
        return;
      }

      debugPrint('====> Fetching Route: $originLat,$originLng to $destLat,$destLng');
      final apiClient = Get.find<ApiClient>();
      final response = await apiClient.getData(
        '${AppConstants.directionUri}?origin_lat=$originLat&origin_lng=$originLng&destination_lat=$destLat&destination_lng=$destLng',
      );
      if (response.statusCode != 200) {
        debugPrint('====> _fetchAndDrawRoute failed with status code ${response.statusCode}: ${response.body}');
        return;
      }

      final data = response.body as Map<String, dynamic>?;
      if (data == null) return;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        debugPrint('====> _fetchAndDrawRoute: No routes found in direction API response.');
        return;
      }

      String? encodedPoints;
      if (routes[0] is Map) {
        final route = routes[0] as Map;
        if (route['overview_polyline'] != null && route['overview_polyline'] is Map) {
          encodedPoints = route['overview_polyline']['points'] as String?;
        } else if (route['polyline'] != null && route['polyline'] is Map) {
          encodedPoints = route['polyline']['encodedPolyline'] as String?;
        }
      }
      if (encodedPoints == null || encodedPoints.isEmpty) {
        debugPrint('====> _fetchAndDrawRoute: Empty overview_polyline/encodedPolyline points.');
        return;
      }

      final List<LatLng> points = _decodePolyline(encodedPoints);
      if (!mounted) return;

      debugPrint('====> Route decoded successfully with ${points.length} points!');
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('delivery_route'),
            color: const Color(0xFF1A73E8), // Google blue
            width: 5,
            points: points,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        };
      });
    } catch (e) {
      debugPrint('====> _fetchAndDrawRoute Error: $e');
    }
  }

  /// Decodes a Google Maps encoded polyline string into a list of LatLng points.
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> zoomToFit(GoogleMapController? controller, LatLngBounds? bounds, LatLng centerBounds, {double padding = 0.5}) async {
    bool keepZoomingOut = true;

    while(keepZoomingOut) {
      final LatLngBounds screenBounds = await controller!.getVisibleRegion();
      if(fits(bounds!, screenBounds)){
        keepZoomingOut = false;
        final double zoomLevel = await controller.getZoomLevel() - padding;
        controller.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: centerBounds,
          zoom: zoomLevel,
        )));
        break;
      }
      else {
        // Zooming out by 0.1 zoom level per iteration
        final double zoomLevel = await controller.getZoomLevel() - 0.1;
        controller.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: centerBounds,
          zoom: zoomLevel,
        )));
      }
    }
  }

  bool fits(LatLngBounds fitBounds, LatLngBounds screenBounds) {
    final bool northEastLatitudeCheck = screenBounds.northeast.latitude >= fitBounds.northeast.latitude;
    final bool northEastLongitudeCheck = screenBounds.northeast.longitude >= fitBounds.northeast.longitude;

    final bool southWestLatitudeCheck = screenBounds.southwest.latitude <= fitBounds.southwest.latitude;
    final bool southWestLongitudeCheck = screenBounds.southwest.longitude <= fitBounds.southwest.longitude;

    return northEastLatitudeCheck && northEastLongitudeCheck && southWestLatitudeCheck && southWestLongitudeCheck;
  }

  void _checkPermission(Function onTap) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if(permission == LocationPermission.denied) {
      showCustomSnackBar('you_have_to_allow'.tr);
    }else if(permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialogWidget());
    }else {
      onTap();
    }
  }

}
