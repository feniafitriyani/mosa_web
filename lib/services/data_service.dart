import 'package:latlong2/latlong.dart';
import '../models/asset.dart';

class DataService {
  static final List<Asset> _assets = [
    Asset(
      id: '390-01',
      name: 'CAT 390 390-01',
      type: EquipmentType.excavator,
      status: AssetStatus.operating,
      position: const LatLng(
        2.08129385,
        117.44800935,
      ), // Shifted into Berau bounds
      site: 'Binungan Mine Operation-1',
      block: 'Binungan Block 1',
      pit: 'Pit-01',
      operator: 'Dadang', // Current shift II operator
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    Asset(
      id: '733-01',
      name: 'CAT 773 733-01',
      type: EquipmentType.hauler,
      status: AssetStatus.inactive,
      position: const LatLng(
        2.08229385,
        117.44900935,
      ), // Shifted into Berau bounds
      site: 'Binungan Mine Operation-1',
      block: 'Binungan Block 1',
      pit: 'Pit-01',
      operator: null, // Inactive unit
      lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Asset(
      id: '733-02',
      name: 'CAT 773 733-02',
      type: EquipmentType.hauler,
      status: AssetStatus.operating,
      position: const LatLng(
        2.08029385,
        117.45000935,
      ), // Shifted into Berau bounds
      site: 'Binungan Mine Operation-1',
      block: 'Binungan Block 1',
      pit: 'Pit-01',
      operator: 'Ahmad Fathoni', // Current shift II operator
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    Asset(
      id: 'D85-01',
      name: 'D85 D85-01',
      type: EquipmentType.dozer,
      status: AssetStatus.inactive,
      position: const LatLng(
        2.08329385,
        117.44700935,
      ), // Shifted into Berau bounds
      site: 'Binungan Mine Operation-1',
      block: 'Binungan Block 1',
      pit: 'Pit-01',
      operator: null, // Inactive unit
      lastUpdated: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Asset(
      id: 'P320-01',
      name: 'P320 Fuel Truck P320-01',
      type: EquipmentType.fuel,
      status: AssetStatus.operating,
      position: const LatLng(2.08429385, 117.44600935),
      site: 'Binungan Mine Operation-1',
      block: 'Binungan Block 1',
      pit: 'Pit-01',
      operator: 'Ari Priya Andrian', // shift II
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
    Asset(
      id: 'P320-02',
      name: 'P320 Fuel Truck P320-02',
      type: EquipmentType.fuel,
      status: AssetStatus.operating,
      position: const LatLng(
        2.09129385,
        117.45100935,
      ), // lebih ke utara & timur
      site: 'Binungan Mine Operation-1',
      block: 'Binungan Block 1',
      pit: 'Pit-01',
      operator: 'Danu Sohika', // shift II
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    Asset(
      id: '733-09',
      name: 'CAT 773 733-09',
      type: EquipmentType.hauler,
      status: AssetStatus.operating,
      position: const LatLng(
        2.07629385,
        117.43900935,
      ), // agak ke selatan & barat
      site: 'Binungan Mine Operation-1',
      block: 'Binungan Block 1',
      pit: 'Pit-01',
      operator: 'Muhammad Nur', // shift II
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 6)),
    ),
    Asset(
      id: 'EX-1200-01',
      name: 'EX-1200 Excavator EX-1200-01',
      type: EquipmentType.excavator,
      status: AssetStatus.operating,
      position: const LatLng(2.09529385, 117.46000935), // lebih jauh ke timur
      site: 'Binungan Mine Operation-1',
      block: 'Binungan Block 1',
      pit: 'Pit-01',
      operator: 'Bayu Krisna', // shift II
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 7)),
    ),
    Asset(
      id: 'EX-1200-02',
      name: 'EX-1200 Excavator EX-1200-02',
      type: EquipmentType.excavator,
      status: AssetStatus.operating,
      position: const LatLng(
        2.08179385, // lebih ke tengah
        117.44850935, // lebih ke tengah
      ),
      site: 'Binungan Mine Operation-1',
      block: 'Binungan Block 1',
      pit: 'Pit-01',
      operator: 'Sutrisno', // shift II
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
  ];

  static List<Asset> get assets => _assets;

  static List<Asset> getFilteredAssets({
    String? site,
    EquipmentType? equipmentType,
    String? unit,
    AssetStatus? status,
  }) {
    return _assets.where((asset) {
      if (site != null &&
          site.isNotEmpty &&
          !asset.site.toLowerCase().contains(site.toLowerCase())) {
        return false;
      }
      if (equipmentType != null && asset.type != equipmentType) {
        return false;
      }
      if (unit != null &&
          unit.isNotEmpty &&
          !asset.name.toLowerCase().contains(unit.toLowerCase())) {
        return false;
      }
      if (status != null && asset.status != status) {
        return false;
      }
      return true;
    }).toList();
  }

  static List<String> get sites => ['Binungan Mine Operation-1'];

  static List<String> get units => _assets.map((e) => e.name).toList();

  static List<TaskHistory> getTaskHistory(
    String assetId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // Realistic task history based on the provided dummy data
    List<TaskHistory> history = [];

    // Base date for the task history (August 2025)
    final baseDate = DateTime(2025, 8, 1);

    switch (assetId) {
      case '390-01': // CAT 390 Excavator
        history.addAll([
          TaskHistory(
            id: '390-01-task-1',
            date: DateTime(2025, 8, 1, 6, 0), // SHIFT I
            shift: 'SHIFT I',
            operator: 'Santoso',
            activity: 'SOIL LOADING',
            site: 'Binungan Mine Operation-1',
            block: 'Binungan Block 1',
            pit: 'Pit-01',
            origin: 'B01-S01',
            destination: 'B01-S01',
          ),
          TaskHistory(
            id: '390-01-task-2',
            date: DateTime(2025, 8, 1, 18, 0), // SHIFT II
            shift: 'SHIFT II',
            operator: 'Dadang',
            activity: 'SOIL LOADING',
            site: 'Binungan Mine Operation-1',
            block: 'Binungan Block 1',
            pit: 'Pit-01',
            origin: 'B01-S01',
            destination: 'B01-S01',
          ),
          TaskHistory(
            id: '390-01-task-3',
            date: DateTime(2025, 8, 2, 6, 0), // SHIFT I
            shift: 'SHIFT I',
            operator: 'Santoso',
            activity: 'SOIL LOADING',
            site: 'Binungan Mine Operation-1',
            block: 'Binungan Block 1',
            pit: 'Pit-01',
            origin: 'B01-S01',
            destination: 'B01-S01',
          ),
          TaskHistory(
            id: '390-01-task-4',
            date: DateTime(2025, 8, 2, 18, 0), // SHIFT II
            shift: 'SHIFT II',
            operator: 'Dadang',
            activity: 'SOIL LOADING',
            site: 'Binungan Mine Operation-1',
            block: 'Binungan Block 1',
            pit: 'Pit-01',
            origin: 'B01-S01',
            destination: 'B01-S01',
          ),
          TaskHistory(
            id: '390-01-task-5',
            date: DateTime(2025, 8, 3, 6, 0), // SHIFT I
            shift: 'SHIFT I',
            operator: 'Santoso',
            activity: 'SOIL LOADING',
            site: 'Binungan Mine Operation-1',
            block: 'Binungan Block 1',
            pit: 'Pit-01',
            origin: 'B01-S01',
            destination: 'B01-S01',
          ),
          TaskHistory(
            id: '390-01-task-6',
            date: DateTime(2025, 8, 3, 18, 0), // SHIFT II
            shift: 'SHIFT II',
            operator: 'Dadang',
            activity: 'SOIL LOADING',
            site: 'Binungan Mine Operation-1',
            block: 'Binungan Block 1',
            pit: 'Pit-01',
            origin: 'B01-S01',
            destination: 'B01-S01',
          ),
        ]);
        break;

      case '733-01': // CAT 773 Hauler (Inactive)
        history.addAll([
          TaskHistory(
            id: '733-01-task-1',
            date: DateTime(2025, 8, 1, 6, 0), // SHIFT I
            shift: 'SHIFT I',
            operator: 'Adhi Muharam',
            activity: 'SOIL LOADING',
            site: 'Binungan Mine Operation-1',
            block: 'Binungan Block 1',
            pit: 'Pit-01',
            origin: 'B01-S01',
            destination: 'OPD-01',
          ),
          TaskHistory(
            id: '733-01-task-2',
            date: DateTime(2025, 8, 1, 18, 0), // SHIFT II
            shift: 'SHIFT II',
            operator: 'Bambang Wibowo',
            activity: 'SOIL LOADING',
            site: 'Binungan Mine Operation-1',
            block: 'Binungan Block 1',
            pit: 'Pit-01',
            origin: 'B01-S01',
            destination: 'OPD-01',
          ),
        ]);
        break;

      case '733-02': // CAT 773 Hauler (Operating)
        history.addAll([
          TaskHistory(
            id: '733-02-task-1',
            date: DateTime(2025, 8, 2, 6, 0), // SHIFT I
            shift: 'SHIFT I',
            operator: 'Rafka Imanudin',
            activity: 'SOIL LOADING',
            site: 'Binungan Mine Operation-1',
            block: 'Binungan Block 1',
            pit: 'Pit-01',
            origin: 'B01-S01',
            destination: 'OPD-01',
          ),
          TaskHistory(
            id: '733-02-task-2',
            date: DateTime(2025, 8, 2, 18, 0), // SHIFT II
            shift: 'SHIFT II',
            operator: 'Iqbal Nuron',
            activity: 'SOIL LOADING',
            site: 'Binungan Mine Operation-1',
            block: 'Binungan Block 1',
            pit: 'Pit-01',
            origin: 'B01-S01',
            destination: 'OPD-01',
          ),
          TaskHistory(
            id: '733-02-task-3',
            date: DateTime(2025, 8, 3, 6, 0), // SHIFT I
            shift: 'SHIFT I',
            operator: 'Cepi Agus Kurniawan',
            activity: 'SOIL LOADING',
            site: 'Binungan Mine Operation-1',
            block: 'Binungan Block 1',
            pit: 'Pit-01',
            origin: 'B01-S01',
            destination: 'OPD-01',
          ),
          TaskHistory(
            id: '733-02-task-4',
            date: DateTime(2025, 8, 3, 18, 0), // SHIFT II
            shift: 'SHIFT II',
            operator: 'Ahmad Fathoni',
            activity: 'SOIL LOADING',
            site: 'Binungan Mine Operation-1',
            block: 'Binungan Block 1',
            pit: 'Pit-01',
            origin: 'B01-S01',
            destination: 'OPD-01',
          ),
        ]);
        break;

      case 'D85-01': // D85 Bulldozer (Inactive)
        history.addAll([
          TaskHistory(
            id: 'D85-01-task-1',
            date: DateTime(2025, 8, 1, 6, 0), // SHIFT I
            shift: 'SHIFT I',
            operator: 'Suheri',
            activity: 'LAND CLEARING',
            site: 'Binungan Mine Operation-1',
            block: 'Binungan Block 1',
            pit: 'Pit-01',
            origin: 'B01-S01',
            destination: 'B01-S01',
          ),
          TaskHistory(
            id: 'D85-01-task-2',
            date: DateTime(2025, 8, 2, 6, 0), // SHIFT I
            shift: 'SHIFT I',
            operator: 'Suheri',
            activity: 'LAND CLEARING',
            site: 'Binungan Mine Operation-1',
            block: 'Binungan Block 1',
            pit: 'Pit-01',
            origin: 'B01-S01',
            destination: 'B01-S01',
          ),
          TaskHistory(
            id: 'D85-01-task-3',
            date: DateTime(2025, 8, 3, 6, 0), // SHIFT I
            shift: 'SHIFT I',
            operator: 'Suheri',
            activity: 'LAND CLEARING',
            site: 'Binungan Mine Operation-1',
            block: 'Binungan Block 1',
            pit: 'Pit-01',
            origin: 'B01-S01',
            destination: 'B01-S01',
          ),
        ]);
        break;
    }

    // Filter by date range if provided
    if (startDate != null || endDate != null) {
      final start = startDate ?? DateTime(2025, 7, 1);
      final end = endDate ?? DateTime.now();
      history =
          history
              .where(
                (task) =>
                    task.date.isAfter(
                      start.subtract(const Duration(days: 1)),
                    ) &&
                    task.date.isBefore(end.add(const Duration(days: 1))),
              )
              .toList();
    }

    return history..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<AssetTrackingPoint> getTrackingData(String assetId) {
    final baseTime = DateTime.now();

    switch (assetId) {
      case '390-01':
        return _buildTrack(assetId, baseTime, [
          // --- Hari 1: 8 Oktober 2025 ---
          _TrackingSample(
            minutesAgo: 0,
            dateTime: DateTime(2025, 10, 8, 6, 0),
            position: LatLng(2.08129385, 117.44800935),
            speed: 0,
            status: 'Unit parked for daily inspection',
          ),
          _TrackingSample(
            minutesAgo: 660,
            dateTime: DateTime(2025, 10, 8, 7, 0),
            position: LatLng(2.08150000, 117.44840000),
            speed: 5,
            status: 'Leaving workshop area',
          ),
          _TrackingSample(
            minutesAgo: 600,
            dateTime: DateTime(2025, 10, 8, 8, 0),
            position: LatLng(2.08180000, 117.44890000),
            speed: 10,
            status: 'En route to ramp entry',
          ),
          _TrackingSample(
            minutesAgo: 540,
            dateTime: DateTime(2025, 10, 8, 9, 0),
            position: LatLng(2.08220000, 117.44940000),
            speed: 8,
            status: 'Short stop before ramp',
          ),
          _TrackingSample(
            minutesAgo: 480,
            dateTime: DateTime(2025, 10, 8, 10, 0),
            position: LatLng(2.08250000, 117.44990000),
            speed: 0,
            status: 'Parked at refuel zone',
          ),
          _TrackingSample(
            minutesAgo: 420,
            dateTime: DateTime(2025, 10, 8, 11, 0),
            position: LatLng(2.08280000, 117.45030000),
            speed: 6,
            status: 'Departing refuel area',
          ),
          _TrackingSample(
            minutesAgo: 360,
            dateTime: DateTime(2025, 10, 8, 12, 0),
            position: LatLng(2.08310000, 117.45080000),
            speed: 0,
            status: 'Parked at workshop pad (end of shift)',
          ),

          // --- Transisi malam menuju hari berikutnya ---
          _TrackingSample(
            minutesAgo: 240,
            dateTime: DateTime(2025, 10, 8, 18, 0),
            position: LatLng(2.08315000, 117.45085000),
            speed: 0,
            status: 'Unit standby overnight',
          ),

          // --- Hari 2: 9 Oktober 2025 ---
          _TrackingSample(
            minutesAgo: 210,
            dateTime: DateTime(2025, 10, 9, 6, 30),
            position: LatLng(2.08340000, 117.45100000),
            speed: 3,
            status: 'Starting up for next shift',
          ),
          _TrackingSample(
            minutesAgo: 180,
            dateTime: DateTime(2025, 10, 9, 7, 0),
            position: LatLng(2.08370000, 117.45130000),
            speed: 7,
            status: 'Heading to pit access road',
          ),
          _TrackingSample(
            minutesAgo: 150,
            dateTime: DateTime(2025, 10, 9, 7, 30),
            position: LatLng(2.08430000, 117.45190000),
            speed: 12,
            status: 'Mobilizing to pit',
          ),
          _TrackingSample(
            minutesAgo: 120,
            dateTime: DateTime(2025, 10, 9, 8, 0),
            position: LatLng(2.08490000, 117.45250000),
            speed: 16,
            status: 'Ascending main ramp',
          ),
          _TrackingSample(
            minutesAgo: 90,
            dateTime: DateTime(2025, 10, 9, 8, 30),
            position: LatLng(2.08540000, 117.45310000),
            speed: 20,
            status: 'Climbing ramp',
          ),
          _TrackingSample(
            minutesAgo: 60,
            dateTime: DateTime(2025, 10, 9, 9, 0),
            position: LatLng(2.08590000, 117.45380000),
            speed: 17,
            status: 'Arriving at bench',
          ),
          _TrackingSample(
            minutesAgo: 30,
            dateTime: DateTime(2025, 10, 9, 9, 30),
            position: LatLng(2.08630000, 117.45440000),
            speed: 11,
            status: 'Looping production face',
          ),
          _TrackingSample(
            minutesAgo: 15,
            dateTime: DateTime(2025, 10, 9, 9, 45),
            position: LatLng(2.08660000, 117.45500000),
            speed: 5,
            status: 'Loading hauler route',
          ),
          _TrackingSample(
            minutesAgo: 0,
            dateTime: DateTime(2025, 10, 9, 10, 0),
            position: LatLng(2.08690000, 117.45550000),
            speed: 0,
            status: 'Standby at stockpile',
          ),
        ]);

      case '733-01':
        return _buildTrack(assetId, baseTime, [
          // --- Hari 1: 8 Oktober 2025 ---
          _TrackingSample(
            minutesAgo: 0,
            dateTime: DateTime(2025, 10, 8, 5, 45),
            position: LatLng(2.0818, 117.4485),
            speed: 0,
            status: 'Prestart inspection',
          ),
          _TrackingSample(
            minutesAgo: 660,
            dateTime: DateTime(2025, 10, 8, 6, 30),
            position: LatLng(2.0822, 117.4490),
            speed: 8,
            status: 'Departing standby zone',
          ),
          _TrackingSample(
            minutesAgo: 600,
            dateTime: DateTime(2025, 10, 8, 7, 30),
            position: LatLng(2.0830, 117.4494),
            speed: 14,
            status: 'Mobilizing to pit 2 area',
          ),
          _TrackingSample(
            minutesAgo: 540,
            dateTime: DateTime(2025, 10, 8, 8, 30),
            position: LatLng(2.0839, 117.4488),
            speed: 16,
            status: 'Hauling from pit 2 to crusher road',
          ),
          _TrackingSample(
            minutesAgo: 480,
            dateTime: DateTime(2025, 10, 8, 9, 30),
            position: LatLng(2.0848, 117.4478),
            speed: 18,
            status: 'Passing haul road intersection',
          ),
          _TrackingSample(
            minutesAgo: 420,
            dateTime: DateTime(2025, 10, 8, 10, 30),
            position: LatLng(2.0854, 117.4469),
            speed: 14,
            status: 'Approaching workshop gate',
          ),
          _TrackingSample(
            minutesAgo: 360,
            dateTime: DateTime(2025, 10, 8, 11, 30),
            position: LatLng(2.0861, 117.4458),
            speed: 8,
            status: 'Entering workshop area',
          ),
          _TrackingSample(
            minutesAgo: 300,
            dateTime: DateTime(2025, 10, 8, 12, 30),
            position: LatLng(2.0867, 117.4450),
            speed: 4,
            status: 'Refuel and inspection',
          ),
          _TrackingSample(
            minutesAgo: 240,
            dateTime: DateTime(2025, 10, 8, 13, 30),
            position: LatLng(2.0870, 117.4444),
            speed: 0,
            status: 'Stopped for refueling',
          ),
          _TrackingSample(
            minutesAgo: 60,
            dateTime: DateTime(2025, 10, 8, 18, 0),
            position: LatLng(2.0872, 117.4439),
            speed: 0,
            status: 'Standby overnight at workshop area',
          ),

          // --- Hari 2: 9 Oktober 2025 ---
          _TrackingSample(
            minutesAgo: 30,
            dateTime: DateTime(2025, 10, 9, 6, 0),
            position: LatLng(2.0871, 117.4438),
            speed: 6,
            status: 'Engine start from workshop',
          ),
          _TrackingSample(
            minutesAgo: 20,
            dateTime: DateTime(2025, 10, 9, 6, 30),
            position: LatLng(2.0865, 117.4446),
            speed: 10,
            status: 'Departing workshop area',
          ),
          _TrackingSample(
            minutesAgo: 15,
            dateTime: DateTime(2025, 10, 9, 7, 0),
            position: LatLng(2.0856, 117.4461),
            speed: 14,
            status: 'Heading toward haul road',
          ),
          _TrackingSample(
            minutesAgo: 10,
            dateTime: DateTime(2025, 10, 9, 7, 30),
            position: LatLng(2.0842, 117.4478),
            speed: 16,
            status: 'On haul road to pit 2',
          ),
          _TrackingSample(
            minutesAgo: 5,
            dateTime: DateTime(2025, 10, 9, 8, 0),
            position: LatLng(2.0830, 117.4490),
            speed: 10,
            status: 'Re-entering pit area',
          ),
          _TrackingSample(
            minutesAgo: 0,
            dateTime: DateTime(2025, 10, 9, 8, 30),
            position: LatLng(2.0823, 117.4490),
            speed: 0,
            status: 'Stopped for maintenance at pit 2',
          ),
        ]);

      case '733-02':
        return _buildTrack(assetId, baseTime, [
          // --- Hari 1: 8 Oktober 2025 ---
          _TrackingSample(
            minutesAgo: 1440 + 500, // Hari 1, 8 Okt 2025, 05:45
            dateTime: DateTime(2025, 10, 8, 5, 45),
            position: LatLng(2.08029385, 117.45000935),
            speed: 0,
            status: 'Loading at pit',
          ),
          _TrackingSample(
            minutesAgo: 1440 + 420,
            dateTime: DateTime(2025, 10, 8, 7, 05),
            position: LatLng(2.07920000, 117.44780000),
            speed: 18,
            status: 'Hauling to OPD',
          ),
          _TrackingSample(
            minutesAgo: 1440 + 360,
            dateTime: DateTime(2025, 10, 8, 8, 05),
            position: LatLng(2.07790000, 117.44450000),
            speed: 27,
            status: 'Descending ramp',
          ),
          _TrackingSample(
            minutesAgo: 1440 + 300,
            dateTime: DateTime(2025, 10, 8, 9, 05),
            position: LatLng(2.07640000, 117.44180000),
            speed: 23,
            status: 'Approaching dump',
          ),
          _TrackingSample(
            minutesAgo: 1440 + 240,
            dateTime: DateTime(2025, 10, 8, 10, 05),
            position: LatLng(2.07490000, 117.43990000),
            speed: 15,
            status: 'Entering dump loop',
          ),
          _TrackingSample(
            minutesAgo: 1440 + 210,
            dateTime: DateTime(2025, 10, 8, 10, 35),
            position: LatLng(2.07380000, 117.43840000),
            speed: 9,
            status: 'Looping for dumping',
          ),
          _TrackingSample(
            minutesAgo: 1440 + 120,
            dateTime: DateTime(2025, 10, 8, 12, 05),
            position: LatLng(2.07290000, 117.43760000),
            speed: 6,
            status: 'Completing loop',
          ),
          _TrackingSample(
            minutesAgo: 1440 + 0,
            dateTime: DateTime(2025, 10, 8, 14, 05),
            position: LatLng(2.07180000, 117.43680000),
            speed: 0,
            status: 'Dump complete - queue / parked overnight',
          ),

          // --- Hari 2: 9 Oktober 2025 ---
          _TrackingSample(
            minutesAgo: 500,
            dateTime: DateTime(2025, 10, 9, 5, 45),
            position: LatLng(2.07180000, 117.43680000),
            speed: 0,
            status: 'Prestart inspection at dump area',
          ),
          _TrackingSample(
            minutesAgo: 420,
            dateTime: DateTime(2025, 10, 9, 7, 05),
            position: LatLng(2.07300000, 117.43870000),
            speed: 14,
            status: 'Traveling back to pit',
          ),
          _TrackingSample(
            minutesAgo: 360,
            dateTime: DateTime(2025, 10, 9, 8, 05),
            position: LatLng(2.07500000, 117.44130000),
            speed: 21,
            status: 'Ascending ramp to pit',
          ),
          _TrackingSample(
            minutesAgo: 300,
            dateTime: DateTime(2025, 10, 9, 9, 05),
            position: LatLng(2.07680000, 117.44450000),
            speed: 24,
            status: 'Crossing haul road',
          ),
          _TrackingSample(
            minutesAgo: 240,
            dateTime: DateTime(2025, 10, 9, 10, 05),
            position: LatLng(2.07830000, 117.44680000),
            speed: 16,
            status: 'Approaching pit loading zone',
          ),
          _TrackingSample(
            minutesAgo: 180,
            dateTime: DateTime(2025, 10, 9, 11, 05),
            position: LatLng(2.07960000, 117.44890000),
            speed: 10,
            status: 'Entering loading queue',
          ),
          _TrackingSample(
            minutesAgo: 60,
            dateTime: DateTime(2025, 10, 9, 13, 05),
            position: LatLng(2.08010000, 117.44980000),
            speed: 3,
            status: 'Positioning for loading',
          ),
          _TrackingSample(
            minutesAgo: 0,
            dateTime: DateTime(2025, 10, 9, 14, 05),
            position: LatLng(2.08029385, 117.45000935),
            speed: 0,
            status: 'Loading at pit - new cycle start',
          ),
        ]);

      case 'D85-01':
        return _buildTrack(assetId, baseTime, const [
          _TrackingSample(
            minutesAgo: 520,
            position: LatLng(2.08329385, 117.44700935),
            speed: 0,
            status: 'Prestart at standby pad',
          ),
          _TrackingSample(
            minutesAgo: 450,
            position: LatLng(2.08250000, 117.44620000),
            speed: 9,
            status: 'Moving to push area',
          ),
          _TrackingSample(
            minutesAgo: 360,
            position: LatLng(2.08140000, 117.44550000),
            speed: 6,
            status: 'Cutting slope',
          ),
          _TrackingSample(
            minutesAgo: 300,
            position: LatLng(2.08050000, 117.44440000),
            speed: 4,
            status: 'Working face north',
          ),
          _TrackingSample(
            minutesAgo: 180,
            position: LatLng(2.07980000, 117.44460000),
            speed: 5,
            status: 'Looping along bench',
          ),
          _TrackingSample(
            minutesAgo: 120,
            position: LatLng(2.07930000, 117.44550000),
            speed: 4,
            status: 'Looping back',
          ),
          _TrackingSample(
            minutesAgo: 60,
            position: LatLng(2.07990000, 117.44620000),
            speed: 3,
            status: 'Final loop pass',
          ),
          _TrackingSample(
            minutesAgo: 0,
            position: LatLng(2.07920000, 117.44490000),
            speed: 0,
            status: 'Parked at push corner',
          ),
        ]);
      case 'P320-01':
        return _buildTrack(assetId, baseTime, const [
          _TrackingSample(
            minutesAgo: 480,
            position: LatLng(2.08429385, 117.44600935),
            speed: 0,
            status: 'Standby for dispatch',
          ),
          _TrackingSample(
            minutesAgo: 420,
            position: LatLng(2.08550000, 117.44720000),
            speed: 17,
            status: 'En route to refuel zone',
          ),
          _TrackingSample(
            minutesAgo: 360,
            position: LatLng(2.08690000, 117.44890000),
            speed: 24,
            status: 'Crossing service road',
          ),
          _TrackingSample(
            minutesAgo: 300,
            position: LatLng(2.08820000, 117.44970000),
            speed: 18,
            status: 'Arriving at fueling pad',
          ),
          _TrackingSample(
            minutesAgo: 180,
            position: LatLng(2.08930000, 117.44890000),
            speed: 10,
            status: 'Looping pad clockwise',
          ),
          _TrackingSample(
            minutesAgo: 120,
            position: LatLng(2.08980000, 117.44840000),
            speed: 7,
            status: 'Looping pad clockwise',
          ),
          _TrackingSample(
            minutesAgo: 60,
            position: LatLng(2.08910000, 117.44790000),
            speed: 4,
            status: 'Positioning for hose connection',
          ),
          _TrackingSample(
            minutesAgo: 0,
            position: LatLng(2.08960000, 117.44820000),
            speed: 0,
            status: 'Fueling static',
          ),
        ]);
      case 'P320-02':
        return _buildTrack(assetId, baseTime, const [
          _TrackingSample(
            minutesAgo: 540,
            position: LatLng(2.09129385, 117.45100935),
            speed: 0,
            status: 'Leaving fuel depot',
          ),
          _TrackingSample(
            minutesAgo: 450,
            position: LatLng(2.09260000, 117.45210000),
            speed: 16,
            status: 'Delivering to EX1200',
          ),
          _TrackingSample(
            minutesAgo: 360,
            position: LatLng(2.09380000, 117.45320000),
            speed: 22,
            status: 'Crossing bench',
          ),
          _TrackingSample(
            minutesAgo: 300,
            position: LatLng(2.09490000, 117.45410000),
            speed: 18,
            status: 'Approaching fueling bay',
          ),
          _TrackingSample(
            minutesAgo: 180,
            position: LatLng(2.09570000, 117.45480000),
            speed: 11,
            status: 'Looping around bay',
          ),
          _TrackingSample(
            minutesAgo: 120,
            position: LatLng(2.09510000, 117.45540000),
            speed: 7,
            status: 'Looping around bay',
          ),
          _TrackingSample(
            minutesAgo: 60,
            position: LatLng(2.09450000, 117.45490000),
            speed: 5,
            status: 'Final alignment',
          ),
          _TrackingSample(
            minutesAgo: 0,
            position: LatLng(2.09530000, 117.45440000),
            speed: 0,
            status: 'Fueling stationary',
          ),
        ]);
      case '733-09':
        return _buildTrack(assetId, baseTime, const [
          _TrackingSample(
            minutesAgo: 600,
            position: LatLng(2.07629385, 117.43900935),
            speed: 0,
            status: 'Loading at pit',
          ),
          _TrackingSample(
            minutesAgo: 480,
            position: LatLng(2.07540000, 117.43750000),
            speed: 19,
            status: 'En route to west dump',
          ),
          _TrackingSample(
            minutesAgo: 360,
            position: LatLng(2.07420000, 117.43590000),
            speed: 26,
            status: 'Crossing ramp',
          ),
          _TrackingSample(
            minutesAgo: 240,
            position: LatLng(2.07310000, 117.43440000),
            speed: 23,
            status: 'Approaching dump loop',
          ),
          _TrackingSample(
            minutesAgo: 180,
            position: LatLng(2.07240000, 117.43360000),
            speed: 14,
            status: 'Dump loop entry',
          ),
          _TrackingSample(
            minutesAgo: 120,
            position: LatLng(2.07290000, 117.43430000),
            speed: 9,
            status: 'Loop around dump',
          ),
          _TrackingSample(
            minutesAgo: 60,
            position: LatLng(2.07330000, 117.43390000),
            speed: 6,
            status: 'Completing loop',
          ),
          _TrackingSample(
            minutesAgo: 0,
            position: LatLng(2.07250000, 117.43380000),
            speed: 0,
            status: 'Queued for next load',
          ),
        ]);
      case 'EX-1200-01':
        return _buildTrack(assetId, baseTime, const [
          _TrackingSample(
            minutesAgo: 48,
            position: LatLng(2.09529385, 117.46000935),
            speed: 0,
            status: 'Standby at face',
          ),
          _TrackingSample(
            minutesAgo: 39,
            position: LatLng(2.09670000, 117.46150000),
            speed: 9,
            status: 'Tracking to eastern cut',
          ),
          _TrackingSample(
            minutesAgo: 30,
            position: LatLng(2.09790000, 117.46280000),
            speed: 12,
            status: 'Relocating bench',
          ),
          _TrackingSample(
            minutesAgo: 22,
            position: LatLng(2.09900000, 117.46370000),
            speed: 9,
            status: 'Approaching new face',
          ),
          _TrackingSample(
            minutesAgo: 16,
            position: LatLng(2.09960000, 117.46460000),
            speed: 6,
            status: 'Looping along cut',
          ),
          _TrackingSample(
            minutesAgo: 11,
            position: LatLng(2.09890000, 117.46490000),
            speed: 4,
            status: 'Looping along cut',
          ),
          _TrackingSample(
            minutesAgo: 5,
            position: LatLng(2.09870000, 117.46390000),
            speed: 3,
            status: 'Positioning for dig',
          ),
          _TrackingSample(
            minutesAgo: 0,
            position: LatLng(2.09920000, 117.46450000),
            speed: 0,
            status: 'Parked at new face',
          ),
        ]);
      case 'EX-1200-02':
        return _buildTrack(assetId, baseTime, const [
          _TrackingSample(
            minutesAgo: 37,
            position: LatLng(2.08179385, 117.44850935),
            speed: 0,
            status: 'Standby at bench',
          ),
          _TrackingSample(
            minutesAgo: 30,
            position: LatLng(2.08250000, 117.44980000),
            speed: 8,
            status: 'Tracking to mid bench',
          ),
          _TrackingSample(
            minutesAgo: 24,
            position: LatLng(2.08300000, 117.45090000),
            speed: 11,
            status: 'Relocating working pad',
          ),
          _TrackingSample(
            minutesAgo: 18,
            position: LatLng(2.08370000, 117.45160000),
            speed: 7,
            status: 'Approaching slot',
          ),
          _TrackingSample(
            minutesAgo: 12,
            position: LatLng(2.08420000, 117.45210000),
            speed: 5,
            status: 'Loop around pad',
          ),
          _TrackingSample(
            minutesAgo: 8,
            position: LatLng(2.08390000, 117.45260000),
            speed: 4,
            status: 'Loop around pad',
          ),
          _TrackingSample(
            minutesAgo: 3,
            position: LatLng(2.08330000, 117.45200000),
            speed: 3,
            status: 'Final positioning',
          ),
          _TrackingSample(
            minutesAgo: 0,
            position: LatLng(2.08410000, 117.45190000),
            speed: 0,
            status: 'Parked at central bench',
          ),
        ]);
      default:
        return _buildFallbackTrack(assetId, baseTime);
    }
  }

  // Returns tracking data filtered by optional date range
  static List<AssetTrackingPoint> getTrackingDataFiltered(
    String assetId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var data = getTrackingData(assetId);
    if (startDate != null) {
      data =
          data
              .where(
                (p) =>
                    p.timestamp.isAfter(startDate) ||
                    p.timestamp.isAtSameMomentAs(startDate),
              )
              .toList();
    }
    if (endDate != null) {
      data =
          data
              .where(
                (p) =>
                    p.timestamp.isBefore(endDate) ||
                    p.timestamp.isAtSameMomentAs(endDate),
              )
              .toList();
    }
    return data;
  }

  static List<AssetTrackingPoint> _buildTrack(
    String assetId,
    DateTime baseTime,
    List<_TrackingSample> samples,
  ) {
    final points =
        samples.asMap().entries.map((entry) {
            final index = entry.key;
            final sample = entry.value;
            final timestamp =
                sample.dateTime ??
                baseTime.subtract(Duration(minutes: sample.minutesAgo));
            return AssetTrackingPoint(
              id: '$assetId-track-$index',
              timestamp: timestamp,
              position: sample.position,
              status: sample.status,
            );
          }).toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return points;
  }

  static List<AssetTrackingPoint> _buildFallbackTrack(
    String assetId,
    DateTime baseTime,
  ) {
    final samples = List<_TrackingSample>.generate(6, (index) {
      final minutesAgo = (5 - index) * 6;
      final baseLat = 2.08000000;
      final baseLng = 117.45000000;
      final lat = baseLat + index * 0.00035;
      final lng = baseLng + index * 0.00028;
      final status =
          index < 4
              ? 'Moving between pads'
              : index == 4
              ? 'Looping at pad'
              : 'Awaiting assignment';
      final movingSpeed = (20 - index * 3).toDouble();
      final double speed =
          index < 5 ? movingSpeed.clamp(4, 22).toDouble() : 0.0;
      return _TrackingSample(
        minutesAgo: minutesAgo,
        position: LatLng(
          index == 5 ? lat + 0.00020 : lat,
          index == 5 ? lng + 0.00015 : lng,
        ),
        speed: speed,
        status: status,
      );
    });

    return _buildTrack(assetId, baseTime, samples);
  }
}

class _TrackingSample {
  final DateTime? dateTime; // optional date for filtering
  final int minutesAgo;
  final LatLng position;
  final double speed;
  final String status;

  const _TrackingSample({
    required this.minutesAgo,
    required this.position,
    required this.speed,
    required this.status,
    this.dateTime,
  });
}
