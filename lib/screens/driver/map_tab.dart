import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/polyline_decoder.dart';
import '../../models/route_model.dart';
import '../../providers/route_provider.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final _api = ApiService();
  final MapController _mapController = MapController();

  String? _error;
  List<Polyline> _polylines = <Polyline>[];
  List<Marker> _markers = <Marker>[];

  // (Giữ nguyên cấu hình Depot và MapTiler)
  static const LatLng _depot = LatLng(10.762622, 106.660172);
  static const int _defaultWs = 8 * 3600;
  static const int _defaultWe = 18 * 3600;
  static const String _mapTilerKey = 'J7ryDjb1c8pLmRYKmAew';
  static const String _mapUrl =
      'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=$_mapTilerKey';

  @override
  void initState() {
    super.initState();
    _api.init();
  }

  Future<void> _optimizeAndDraw() async {
    final routeProvider = context.read<RouteProvider>();

    setState(() {
      _error = null;
      _polylines = <Polyline>[];
      _markers = <Marker>[];
    });

    try {
      // (Bước 1 & 2: Lấy 'deliveries' và 'orderIds' - Giữ nguyên logic của bạn)
      final deliveriesResponse = await _api.get(ApiConstants.myDeliveries);
      if (deliveriesResponse.statusCode != 200 ||
          deliveriesResponse.data is! List) {
        throw Exception('Không lấy được danh sách đơn giao.');
      }
      final List deliveries = deliveriesResponse.data as List;
      final orderIds = deliveries
          .map((e) => (e as Map)['maDonHang'])
          .where((v) => v != null)
          .toSet()
          .toList();
      if (orderIds.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có đơn hàng nào để tối ưu')),
        );
        return;
      }

      // (Bước 3: Lấy 'orderDetails' - Giữ nguyên logic N+1 call của bạn)
      final orderDetails = <Map<String, dynamic>>[];
      for (final id in orderIds) {
        final res = await _api.get(ApiConstants.orderById(id.toString()));
        if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
          orderDetails.add(res.data as Map<String, dynamic>);
        }
      }

      // ----- BƯỚC 4: DỰNG 'points' VÀ TẠO MAP LIÊN KẾT -----
      final points = <Map<String, dynamic>>[
        {
          "id": 0, // 0 luôn là KHO
          "name": "Kho",
          "lat": _depot.latitude,
          "lng": _depot.longitude,
          "serviceMinutes": 0,
        },
      ];

      // MAP MỚI: (Key: pointId, Value: maDonHang)
      final Map<int, String> pointIdToMaDonMap = {};
      int nextId = 1; // Bắt đầu từ 1 (vì 0 là kho)

      for (final d in orderDetails) {
        // d là 'DonHangReadDto', có 'madon'
        final String maDon = (d['madon'] ?? '').toString();
        if (maDon.isEmpty) continue; // Bỏ qua nếu không có mã đơn

        final name =
            (d['tenDiemGiao'] ?? d['TenDiemGiao'] ?? 'Điểm giao $nextId')
                .toString();
        final lat =
            double.tryParse((d['lat'] ?? d['Lat'] ?? 0).toString()) ?? 0;
        final lng =
            double.tryParse((d['lng'] ?? d['Lng'] ?? 0).toString()) ?? 0;
        if (lat == 0 || lng == 0) continue;

        final int currentPointId = nextId++; // Lấy ID cho điểm này

        points.add({
          "id": currentPointId, // <-- Dùng ID này
          "name": name,
          "lat": lat,
          "lng": lng,
          "serviceMinutes": (d['serviceMinutes'] ?? 10) as int,
          // (Các trường 'ws', 'we' có thể thêm nếu cần)
        });

        // Tạo liên kết: pointId này tương ứng với maDon này
        pointIdToMaDonMap[currentPointId] = maDon;
      }
      // ---------------------------------------------------

      if (points.length < 2) {
        throw Exception('Không có đủ điểm để tối ưu.');
      }

      // 5) GỌI PROVIDER (Truyền cả 'points' và 'pointIdToMaDonMap')
      final success = await routeProvider.optimizeRoute(
        points,
        pointIdMap: pointIdToMaDonMap,
      );

      if (!success || routeProvider.route == null) {
        throw Exception(routeProvider.error ?? 'Tối ưu thất bại.');
      }

      final routeModel = routeProvider.route!;

      // 6) Vẽ tuyến (Giữ nguyên logic của bạn)
      final polylines = <Polyline>[];
      final markers = <Marker>[];
      final allPolylinePts = <LatLng>[];

      for (int i = 0; i < routeModel.stops.length; i++) {
        final s = routeModel.stops[i];

        if (s.polyline.isNotEmpty) {
          final seg = PolylineDecoder.decode(s.polyline);
          if (seg.isNotEmpty) {
            polylines.add(
              Polyline(points: seg, strokeWidth: 4, color: Colors.blueAccent),
            );
            allPolylinePts.addAll(seg);
          }
        }
        markers.add(
          Marker(
            point: LatLng(s.lat, s.lng),
            width: 40,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: i == 0 ? AppColors.driverPrimary : AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '$i', // Điểm 0 là kho
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }

      setState(() {
        _polylines = polylines;
        _markers = markers;
      });

      // 7) Fit bounds (Giữ nguyên logic của bạn)
      if (allPolylinePts.isNotEmpty) {
        _fitBounds(allPolylinePts);
      } else if (markers.isNotEmpty) {
        _mapController.move(markers.first.point, 14);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_error ?? 'Lỗi không xác định')));
    }
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe trạng thái loading từ provider
    final isLoading = context.watch<RouteProvider>().loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ lộ trình'),
        backgroundColor: AppColors.driverPrimary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(initialCenter: _depot, initialZoom: 12),
            children: [
              TileLayer(
                urlTemplate: _mapUrl,
                userAgentPackageName: 'com.example.app',
                maxZoom: 20,
              ),
              PolylineLayer(polylines: _polylines),
              MarkerLayer(markers: _markers),
              RichAttributionWidget(
                attributions: const [
                  TextSourceAttribution(
                    '© MapTiler © OpenStreetMap contributors',
                  ),
                ],
                popupInitialDisplayDuration: Duration.zero,
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _optimizeAndDraw,
            icon: const Icon(Icons.alt_route),
            label: const Text('Tối ưu & vẽ tuyến'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.driverPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
    );
  }
}
