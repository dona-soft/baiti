import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    Key? key,
    required this.origin,
    required this.markers,
    this.selected = '',
    this.isItNewMarker = false,
  }) : super(key: key);

  final CameraPosition origin;
  final List<Marker> markers;
  final String selected;
  final isItNewMarker;

  @override
  State<MapScreen> createState() => _MapScreenState(
        origin,
        markers,
        isNewMarker: isItNewMarker,
      );
}

class _MapScreenState extends State<MapScreen> {
  _MapScreenState(
    CameraPosition origin,
    List<Marker> list, {
    this.isNewMarker = false,
  }) {
    if (list.isNotEmpty && isNewMarker) {
      for (int i = 1; i < list.length - 1; i++) {
        list[i] = list[i].copyWith(alphaParam: 0.5);
      }
      latLng = list[list.length - 1].position;
      var temp = list.last;
      list.removeLast();
      list.add(Marker(
        markerId: temp.markerId,
        icon: temp.icon,
        infoWindow: temp.infoWindow,
        position: latLng,
        draggable: true,
        onDragEnd: (ll) {
          latLng = ll;
        },
      ));
    }

    markers = list;
    initialCameraPosition = origin;
  }

  late LatLng latLng;
  late CameraPosition? initialCameraPosition;
  late GoogleMapController _googleMapController;
  late Marker selectedMarker;
  List<Marker> markers = [];

  int markercounter = 0;

  String selected = '';

  bool isLoaded = false;
  bool isNewMarker;

  void deleteMarker(String markerId) async {
    var temp = markers;
    Marker? t;
    for (int i = 0; i < temp.length; i++) {
      if (temp[i].markerId.value == markerId) t = temp[i];
    }
    if (t != null) temp.remove(t);

    markers = temp;
    setState(() {
      selected = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.pop(context, false);
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Map"),
          actions: [
            if (isNewMarker)
              IconButton(
                onPressed: () {
                  markers.forEach((element) {});
                  Navigator.pop(context, latLng);
                },
                icon: Icon(Icons.check),
              ),
          ],
        ),
        body: Stack(children: [
          GoogleMap(
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            initialCameraPosition: initialCameraPosition as CameraPosition,
            onMapCreated: (controller) {
              _googleMapController = controller;

              if (initialCameraPosition != null) {
                _googleMapController.animateCamera(
                    CameraUpdate.newCameraPosition(
                        initialCameraPosition as CameraPosition));
                setState(() {
                  isLoaded = true;
                });
              }
            },
            onTap: (_) {
              setState(() {
                selected = '';
              });
            },
            markers: markers.toSet(),
          ),
          if (isNewMarker)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: double.infinity,
                height: 25,
                color: Colors.white,
                alignment: Alignment.center,
                child: Text(
                  'يمكنك تغيير مكان المؤشر الأخضر بالضغط المطول عليه!',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
        ]),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (isNewMarker) {
              setState(() {
                initialCameraPosition =
                    new CameraPosition(target: latLng, zoom: 15);
              });
            }
            _googleMapController.animateCamera(CameraUpdate.newCameraPosition(
                initialCameraPosition as CameraPosition));
          },
          child: Icon(
            Icons.location_on_rounded,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }
}
