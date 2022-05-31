import 'dart:async';
import 'dart:io';

import 'package:baiti_ana_baitak/auxiliary/constents.dart';
import 'package:baiti_ana_baitak/auxiliary/database.dart';
import 'package:baiti_ana_baitak/screens/map_Page.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddFamilyPage extends StatefulWidget {
  const AddFamilyPage({
    Key? key,
    required this.locationList,
    this.updateFamily,
  }) : super(key: key);

  final List<Marker> locationList;
  final Markers? updateFamily;
  @override
  State<AddFamilyPage> createState() =>
      _AddFamilyPageState(locationList, updateFam: updateFamily);
}

class _AddFamilyPageState extends State<AddFamilyPage> {
  _AddFamilyPageState(this.locations, {this.updateFam}) {
    pasteDate();
  }

  var fullNameC = TextEditingController();
  var smartCardNumC = TextEditingController();
  var familyNumC = TextEditingController();
  var collageStudNumC = TextEditingController();
  var specialNeedC = TextEditingController();
  var ownerNameC = TextEditingController();

  final liveSatus = Constants.propType;
  List<Marker> locations;
  Markers? updateFam;

  String selected = '';

  late LatLng latLng;
  bool isLocationAvailabe = false;

  late CameraPosition origin;

  var dataBase = MarkersDB();

  void pasteDate() async {
    if (updateFam != null) {
      locations.removeLast();
      try {
        fullNameC.text = updateFam!.fullName;
        smartCardNumC.text = updateFam!.smartCardNum;
        familyNumC.text = updateFam!.familyNum.toString();
        collageStudNumC.text = updateFam!.collageStudNum.toString();
        specialNeedC.text = updateFam!.specialNeedsNum.toString();
        selected = updateFam!.propertyType;
        if (selected == liveSatus[1]) ownerNameC.text = updateFam!.ownerName;
        latLng = updateFam!.latLng;
        isLocationAvailabe = true;
      } on Exception catch (e) {
        print(e);
      }
    }
  }

  DropdownMenuItem<String> dropMenuBuilder(String option) => DropdownMenuItem(
        value: option,
        child: Container(
          child: Text(
            option,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );

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

  Future<void> getCoordinates() async {
    Position pos;

    if (!(await testConnection())) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Text('لايوجد اتصال بالانترنت '),
              Icon(
                Icons.wifi_off,
                color: Colors.white,
              ),
            ],
          ),
        ),
      );
      return;
    }

    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } on Exception catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Text(
                'الرجاء التحقق من خاصية الوصول الى الموقع! ',
                textDirection: TextDirection.rtl,
              ),
              Icon(
                Icons.location_off,
                color: Colors.white,
              ),
            ],
          ),
        ),
      );
      return;
    }

    String mId = '???';
    if (fullNameC.value.text.isNotEmpty) mId = fullNameC.value.text;
    Marker destination;
    if (!isLocationAvailabe) {
      destination = Marker(
        markerId: MarkerId(mId),
        position: LatLng(pos.latitude, pos.longitude),
        infoWindow: InfoWindow(title: mId),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
      origin = CameraPosition(
        target: LatLng(pos.latitude, pos.longitude),
        zoom: 15,
      );
    } else {
      destination = Marker(
        markerId: MarkerId(mId),
        position: LatLng(latLng.latitude, latLng.longitude),
        infoWindow: InfoWindow(title: mId),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
      origin = CameraPosition(
        target: LatLng(latLng.latitude, latLng.longitude),
        zoom: 15,
      );
    }

    var res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapScreen(
          origin: origin,
          markers: [...locations, destination],
          isItNewMarker: true,
        ),
      ),
    );

    if (res != null && res != false) {
      latLng = res;
      setState(() {
        isLocationAvailabe = true;
      });
    } else {
      isLocationAvailabe = false;
    }
  }

  Future<void> saveInfo() async {
    var snackBar = SnackBar(
      content: Text(
        "الرجاء ملء جميع الخانات الموجودة!!",
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
      ),
    );

    if (fullNameC.value.text.isEmpty ||
        collageStudNumC.value.text.isEmpty ||
        familyNumC.value.text.isEmpty ||
        smartCardNumC.value.text.isEmpty ||
        specialNeedC.value.text.isEmpty ||
        selected.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      if (selected == liveSatus[1] && ownerNameC.value.text.isEmpty) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } else {
        if (updateFam != null) {
          await dataBase.updateMark(
            Markers(
              id: updateFam!.id,
              latitude: latLng.latitude,
              longitude: latLng.longitude,
              familyNum: int.parse(familyNumC.text),
              fullName: fullNameC.text,
              collageStudNum: int.parse(collageStudNumC.text),
              smartCardNum: smartCardNumC.text,
              propertyType: selected,
              specialNeedsNum: int.parse(specialNeedC.text),
            ),
          );
        } else
          await dataBase.insertMark(
            fullName: fullNameC.text,
            collageStudNum: int.parse(collageStudNumC.text),
            familyNum: int.parse(familyNumC.text),
            latitude: latLng.latitude,
            longitude: latLng.longitude,
            smartCardNum: smartCardNumC.text,
            specialNeedsNum: int.parse(specialNeedC.text),
            ownerName: ownerNameC.text,
            propertyType: selected,
            // moreDiscreption: ,
          );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add"),
        actions: [],
      ),
      body: ListView(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: TextField(
              decoration: InputDecoration(
                label: Text('الاسم الثلاثي لرب الأسرة'),
              ),
              controller: fullNameC,
              textInputAction: TextInputAction.next,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              decoration: InputDecoration(
                label: Text('عدد افراد الأسرة'),
              ),
              keyboardType: TextInputType.number,
              controller: familyNumC,
              textInputAction: TextInputAction.next,
              onChanged: (newVal) {
                if (!newVal.contains(RegExp(r'^[0-9]*$'))) {
                  familyNumC.text = newVal.substring(0, newVal.length - 1);
                  familyNumC.selection = TextSelection(
                      baseOffset: familyNumC.text.length,
                      extentOffset: familyNumC.text.length);
                }
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: TextField(
              decoration: InputDecoration(
                label: Text('عدد طلاب الجامعة في المنزل'),
              ),
              keyboardType: TextInputType.number,
              controller: collageStudNumC,
              textInputAction: TextInputAction.next,
              onChanged: (newVal) {
                if (!newVal.contains(RegExp(r'^[0-9]*$'))) {
                  collageStudNumC.text = newVal.substring(0, newVal.length - 1);
                  collageStudNumC.selection = TextSelection(
                      baseOffset: collageStudNumC.text.length,
                      extentOffset: collageStudNumC.text.length);
                }
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              decoration: InputDecoration(
                label: Text('رقم البطاقة الذكية'),
              ),
              keyboardType: TextInputType.number,
              controller: smartCardNumC,
              textInputAction: TextInputAction.next,
              onChanged: (newVal) {
                if (!newVal.contains(RegExp(r'^[0-9]*$'))) {
                  smartCardNumC.text = newVal.substring(0, newVal.length - 1);
                  smartCardNumC.selection = TextSelection(
                      baseOffset: smartCardNumC.text.length,
                      extentOffset: smartCardNumC.text.length);
                }
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: TextField(
              decoration: InputDecoration(
                label: Text('عدد أصحاب الاحتياج في المنزل'),
              ),
              keyboardType: TextInputType.number,
              controller: specialNeedC,
              textInputAction: selected == liveSatus[1]
                  ? TextInputAction.next
                  : TextInputAction.done,
              onChanged: (newVal) {
                if (!newVal.contains(RegExp(r'^[0-9]*$'))) {
                  specialNeedC.text = newVal.substring(0, newVal.length - 1);
                  specialNeedC.selection = TextSelection(
                      baseOffset: specialNeedC.text.length,
                      extentOffset: specialNeedC.text.length);
                }
              },
            ),
          ),
          if (selected == liveSatus[1])
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                decoration: InputDecoration(
                  label: Text('اسم صاحب السكن'),
                ),
                controller: ownerNameC,
                textInputAction: TextInputAction.done,
              ),
            ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    // if (!isLocationAvailabe) {
                    await getCoordinates();
                    // }
                  },
                  child: Row(
                    children: [
                      isLocationAvailabe
                          ? Icon(Icons.check_circle, color: Colors.green[600])
                          : Icon(Icons.location_on, color: Colors.red[800]),
                      Text(
                        isLocationAvailabe ? 'تم الطلب ' : 'طلب الاحداثيات',
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
                DropdownButton<String>(
                  items: liveSatus.map(dropMenuBuilder).toList(),
                  value: selected.isEmpty ? null : selected,
                  hint: Text('نوع السكن'),
                  onChanged: (a) => setState(() {
                    selected = a.toString();
                    if (selected == liveSatus[0]) ownerNameC.clear();
                  }),
                  alignment: Alignment.center,
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 20),
            alignment: Alignment.center,
            child: ElevatedButton(
              child: Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: isLocationAvailabe
                  ? () {
                      saveInfo();
                    }
                  : null,
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    collageStudNumC.dispose();
    fullNameC.dispose();
    familyNumC.dispose();
    ownerNameC.dispose();
    smartCardNumC.dispose();
    specialNeedC.dispose();

    super.dispose();
  }
}
