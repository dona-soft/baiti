import 'dart:io';

import 'package:baiti_ana_baitak/auxiliary/constents.dart';
import 'package:baiti_ana_baitak/auxiliary/database.dart';
import 'package:baiti_ana_baitak/screens/addFamilyPage.dart';
import 'package:baiti_ana_baitak/screens/map_Page.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  _HomePageState() {
    verifyLocationPermission();
    markersList();
  }
  var database = MarkersDB();

  bool loading = false;
  bool showMenu = false;

  int bannerIndex = 0;

  double translateMenu = 300;
  late double myLat, myLng;

  CameraPosition? initialCameraPosition;
  loc.Location location = loc.Location();
  Map<Permission, PermissionStatus> status = {};

  List<Marker> markers = [];
  List<Markers> families = [];
  late Position position;
  late SharedPreferences prefs;

  /// this method checks for the location permission [status]
  /// and returns a [bool] for the availability of the permission.
  Future<bool> verifyLocationPermission() async {
    prefs = await SharedPreferences.getInstance();
    if (await Permission.location.status.isPermanentlyDenied) {
      return false;
    } else if (await Permission.location.status.isDenied) {
      status = await [Permission.location].request();
      if (await Permission.location.status.isGranted) {
        if (await location.serviceEnabled()) {
          await myLocation();
          return true;
        } else if (await location.requestService()) {
          await myLocation();
          return true;
        }
      }
    } else if (await Permission.location.status.isGranted) {
      if (await location.serviceEnabled()) {
        await myLocation();
        return true;
      } else if (await location.requestService()) {
        await myLocation();
        return true;
      }
    }
    return false;
  }

  Future<void> myLocation() async {
    bool connection = await testConnection();
    if (!connection) {
      return;
    }

    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    if (prefs.getDouble('myLat') == null) {
      myLat = position.latitude;
      myLng = position.longitude;
      await prefs.setDouble('myLat', myLat);
      await prefs.setDouble('myLng', myLng);
    } else {
      myLat = prefs.getDouble('myLat') as double;
      myLng = prefs.getDouble('myLng') as double;
    }
    if (markers.isEmpty || markers.first.markerId != MarkerId('origin')) {
      var orig = Marker(
        markerId: MarkerId('origin'),
        infoWindow: InfoWindow(title: 'Origin'),
        position: LatLng(myLat, myLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
      markers.insert(0, orig);
    }
  }

  Future<bool> testConnection() async {
    try {
      final result = await InternetAddress.lookup('www.google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<void> markersList() async {
    await database.init();
    families = await database.getAllMarkers();
    print("Debug: $families");
    families.forEach((element) {
      var temp = new Marker(
        markerId: MarkerId('${element.id}'),
        infoWindow: InfoWindow(title: element.fullName),
        position: element.latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      );
      if (!markers.contains(temp)) markers.add(temp);
    });
    print("Debug: $markers");
    setState(() {});
  }

  void showItemOnMap(int index) async {
    setState(() {
      if (!loading) loading = true;
    });
    bool permission = await verifyLocationPermission();

    bool connection = await testConnection();

    if (!permission) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            'لا يمكن الوصول للموقع',
            style: TextStyle(fontWeight: FontWeight.bold),
            textDirection: TextDirection.rtl,
          ),
          content: Text(
            'لا يمكن للتطبيق العمل بدون صلاحية الوصول للموقع...',
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
                onPressed: () {
                  setState(() {
                    loading = false;
                  });
                  Navigator.pop(context);
                },
                child: Text('موافق'))
          ],
        ).build(context),
      );
      return;
    }
    if (!connection) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            'لا يوجد الاتصال بالانترنت؟',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'حدث خطأ اثناء محاولة الاتصال بالخادم الرجاء التأكد من جودة الاتصال بالانترنت...',
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
                onPressed: () {
                  setState(() {
                    loading = false;
                  });
                  Navigator.pop(context);
                },
                child: Text('موافق'))
          ],
        ).build(context),
      );
      return;
    }
    if (index > -1) {
      initialCameraPosition = families[index - 1].cameraPosition;
      var temp = markers[index];
      List<Marker> listM = [];
      markers.forEach((element) {
        if (element == temp) {
          listM.add(
            Marker(
              markerId: temp.markerId,
              infoWindow: temp.infoWindow,
              position: temp.position,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure),
            ),
          );
        } else
          listM.add(element);
      });

      loading = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MapScreen(
            origin: initialCameraPosition as CameraPosition,
            markers: listM,
          ),
        ),
      );
      setState(() {});
    } else {
      loading = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MapScreen(
            origin: CameraPosition(
              target: LatLng(myLat, myLng),
              zoom: 15,
            ),
            markers: markers,
          ),
        ),
      );
      setState(() {});
    }
  }

  Future<void> deleteItem(int index) async {
    await database.deleteMark(families[index]);
    showMenu = false;
    var temp = markers.first;
    markers.clear();
    markers.add(temp);
    await markersList();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (showMenu) {
          setState(() {
            showMenu = false;
            bannerIndex = -1;
          });
          return Future.value(false);
        } else
          return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(Constants.APP_TITLE),
          actions: [
            IconButton(
              onPressed: () {
                showItemOnMap(-1);
              },
              tooltip: 'فتح الخريطة',
              icon: Icon(Icons.grid_view_rounded),
              splashRadius: 25,
            ),
            IconButton(
              onPressed: () async {
                if (await verifyLocationPermission()) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AddFamilyPage(
                              locationList: markers,
                            )),
                  );
                  markersList();
                } else {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'حدث خطأ تأكد من تفعيل بيانات الموقع والانترنت!',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
              },
              tooltip: 'اضافة عائلة',
              icon: Icon(Icons.add),
              splashRadius: 25,
            ),
          ],
        ),
        body: Stack(
          children: [
            families.isNotEmpty
                ? ListView.builder(
                    itemCount: families.length,
                    itemBuilder: (buildContext, index) {
                      return ListTile(
                        leading: Icon(Icons.accessibility),
                        title: Text(families[index].fullName),
                        subtitle: Text(families[index].smartCardNum),
                        onTap: () {
                          showItemOnMap(index + 1);
                        },
                        onLongPress: () {
                          setState(() {
                            bannerIndex = index;
                            showMenu = true;
                          });
                        },
                      );
                    },
                  )
                : Center(
                    child: Text(
                    'لا يوجد عناصر لعرضها',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  )),
            if (loading)
              Container(
                color: Color.fromARGB(150, 0, 0, 0),
                child: Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey[800],
                    ),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    ),
                  ),
                ),
              ),
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
            ),
            if (showMenu)
              Listener(
                onPointerUp: (event) {
                  setState(() {
                    showMenu = false;
                  });
                },
                child: Container(
                  color: Color.fromARGB(120, 0, 0, 0),
                ),
              ),
            if (families.isNotEmpty)
              AnimatedPositioned(
                width: MediaQuery.of(context).size.width * 0.9,
                left: MediaQuery.of(context).size.width * 0.05,
                // top: showMenu ? 20 : MediaQuery.of(context).size.height,
                bottom: showMenu ? 20 : -400,
                duration: Duration(milliseconds: 200),
                // onEnd: () {
                //   setState(() {
                //     // if(!showMenu)
                //   });
                // },
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(children: [
                    Text(
                      'الاسم الثلاثي لرب الاسرة: ${families[bannerIndex].fullName}', //fullName
                      textDirection: TextDirection.rtl,
                    ),
                    Text(
                      'رقم البطاقة الذكية: ${families[bannerIndex].smartCardNum}', //smartCardNum
                      textDirection: TextDirection.rtl,
                    ),
                    Text(
                      'عدد افراد الاسرة: ${families[bannerIndex].familyNum}', //familyNum
                      textDirection: TextDirection.rtl,
                    ),
                    Text(
                      'عدد طلاب الجامعات: ${families[bannerIndex].collageStudNum}', //collageStudNum
                      textDirection: TextDirection.rtl,
                    ),
                    Text(
                      'عدد ذوي الاحتياجات الخاصة: ${families[bannerIndex].specialNeedsNum}', //specialNeedsNum
                      textDirection: TextDirection.rtl,
                    ),
                    Text(
                      'نوع السكن: ${families[bannerIndex].propertyType}', //propertyType
                      textDirection: TextDirection.rtl,
                    ),
                    if (families[bannerIndex].propertyType ==
                        Constants.propType[1])
                      Text(
                        'اسم صاحب السكن: ${families[bannerIndex].ownerName}', //ownerName
                        textDirection: TextDirection.rtl,
                      ),
                    Container(
                      height: 15,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                            onPressed: () async {
                              setState(() {
                                showMenu = false;
                              });
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddFamilyPage(
                                    locationList: markers,
                                    updateFamily: families[bannerIndex],
                                  ),
                                ),
                              );
                              await markersList();
                            },
                            child: Text(
                              'تعديل',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )),
                        ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text('هل انت متأكد؟'),
                                  content: Text(
                                    'سيتم حذف جميع البيانات المتعلقة ب ${families[bannerIndex].fullName} بما في ذلك الموقع؟؟',
                                    textDirection: TextDirection.rtl,
                                  ),
                                  actions: [
                                    OutlinedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        'إلغاء',
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await deleteItem(bannerIndex);
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        'حذف',
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text(
                              'حذف',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )),
                      ],
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
