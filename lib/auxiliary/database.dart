import 'package:baiti_ana_baitak/auxiliary/constents.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Markers {
  late double latitude, longitude;
  late String fullName, smartCardNum, propertyType, ownerName;
  late int familyNum, collageStudNum, specialNeedsNum, id;
  late CameraPosition cameraPosition;
  late LatLng latLng;

  Markers({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.familyNum,
    required this.fullName,
    required this.collageStudNum,
    required this.smartCardNum,
    required this.propertyType,
    required this.specialNeedsNum,
    this.ownerName = '',
  }) {
    cameraPosition =
        CameraPosition(target: LatLng(latitude, longitude), zoom: 15);
    latLng = LatLng(latitude, longitude);
  }

  @override
  String toString() {
    return '\nMarker {\n'
        'id: $id,\n'
        'LatLng: $latitude,$longitude,\n'
        'fullName: $fullName,\n'
        'collageStudNum: $collageStudNum,\n'
        'smartCardNum: $smartCardNum,\n'
        'ownerName: $ownerName,\n'
        'specialNeedsNum: $specialNeedsNum,\n'
        'propertyType: $propertyType,\n'
        '}';
  }

  // data flow romatric
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'familyNum': familyNum,
      'fullName': fullName,
      'collageStudNum': collageStudNum,
      'smartCardNum': smartCardNum,
      'ownerName': ownerName,
      'specialNeedsNum': specialNeedsNum,
      'propertyType': propertyType,
    };
  }

  Markers.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    familyNum = map['familyNum'];
    collageStudNum = map['collageStudNum'];
    specialNeedsNum = map['specialNeedsNum'];
    fullName = map['fullName'];
    latitude = double.parse(map['latitude']);
    longitude = double.parse(map['longitude']);
    ownerName = map['ownerName'];
    propertyType = map['propertyType'];
    smartCardNum = map['smartCardNum'];

    latLng = LatLng(latitude, longitude);
    cameraPosition = CameraPosition(target: latLng, zoom: 15);
  }
}

class MarkersDB {
  String dbPath = '';
  Database? db;

  MarkersDB() {
    init();
  }

  Future<void> init() async {
    db = await openDatabase(
      join(await getDatabasesPath(), Constants.DATABASE),
      version: 1,
      onCreate: (database, version) {
        database.execute(
          'CREATE TABLE IF NOT EXISTS ${Constants.MARKERS_TABLE}('
                  'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
              'latitude TEXT,' +
              'longitude TEXT,' +
              'fullName TEXT,' +
              'familyNum INTEGER,' +
              'collageStudNum INTEGER,' +
              'specialNeedsNum INTEGER,' +
              'smartCardNum TEXT,' +
              'propertyType TEXT,' +
              'ownerName TEXT' +
              ')',
        );
      },
    );
  }

  Future<int?> insertMark({
    required double latitude,
    required double longitude,
    required String fullName,
    required int familyNum,
    required int collageStudNum,
    required int specialNeedsNum,
    required String smartCardNum,
    required String propertyType,
    String ownerName = '.',
  }) async {
    Map<String, dynamic> newMark = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'familyNum': familyNum,
      'fullName': fullName,
      'collageStudNum': collageStudNum,
      'smartCardNum': smartCardNum,
      'ownerName': ownerName,
      'specialNeedsNum': specialNeedsNum,
      'propertyType': propertyType,
    };

    var res = await db?.insert(
      Constants.MARKERS_TABLE,
      newMark,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return res;
  }

  Future<void> updateMark(Markers updatedMark) async {
    await db?.update(
      Constants.MARKERS_TABLE,
      updatedMark.toMap(),
      where: 'id = ?',
      whereArgs: [updatedMark.id],
    );
  }

  Future<void> deleteMark(Markers mark) async {
    await db?.delete(
      Constants.MARKERS_TABLE,
      where: 'id=?',
      whereArgs: [mark.id],
    );
  }

  Future<List<Markers>> getAllMarkers() async {
    final List<Map<String, dynamic>>? locations =
        await db?.query(Constants.MARKERS_TABLE);
    final List<Markers> result = [];

    if (locations != null) {
      locations.forEach((element) {
        result.add(Markers.fromMap(element));
      });
    }
    return result;
  }
}
