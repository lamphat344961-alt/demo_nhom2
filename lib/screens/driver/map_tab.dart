import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/polyline_decoder.dart';
import '../../models/order_model.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final ApiService _api = ApiService();
  final MapController _mapController = MapController();

  RouteModel? _routeModel;
  List<LatLng> _allPolylinePoints = [];
  bool _isLoading = false;
  bool _hasOptimized = false;

  // Depot coordinates (from appsettings.json)
  final LatLng _depotLocation = const LatLng(10.8592944, 106.8010938);

  @override
  void initState() {
    super.initState();
    // Center map at depot on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_depotLocation, 13);
    });
  }

  Future<void> _optimizeRoute() async {
    setState(() => _isLoading = true);

    try {
      // Step 1: Get all pending deliveries
      final deliveriesResponse = await _api.get(ApiConstants.myDeliveries);

      if (deliveriesResponse.data is String) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn chưa có đơn hàng nào')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final List deliveriesData = deliveriesResponse.data;
      final deliveries = deliveriesData
          .map((json) => DeliveryModel.fromJson(json))
          .toList();

      // Get unique order IDs
      final orderIds = deliveries.map((d) => d.maDonHang).toSet().toList();

      if (orderIds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không có đơn hàng nào để tối ưu')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Step 2: Call optimize API
      final optimizeResponse = await _api.post(
        ApiConstants.optimizeRoute,
        data: {
          'orderIds': orderIds,
          'vehicleSpeedKph': 40,
          'departureEpoch': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
      );

      final routeModel = RouteModel.fromJson(optimizeResponse.data);

      // Step 3: Decode all polylines
      List<LatLng> allPoints = [];
      for (var stop in routeModel.stops) {
        if (stop.polyline.isNotEmpty) {
          final decoded = PolylineDecoder.decode(stop.polyline);
          allPoints.addAll(decoded);
        }
      }

      setState(() {
        _routeModel = routeModel;
        _allPolylinePoints = allPoints;
        _hasOptimized = true;
        _isLoading = false;
      });

      // Fit bounds to show all points
      if (allPoints.isNotEmpty) {
        _fitBounds(allPoints);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã tối ưu ${routeModel.stops.length} điểm giao - ${routeModel.readableTotal}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ lộ trình'),
        backgroundColor: AppColors.driverPrimary,
        foregroundColor: Colors.white,
        actions: [
          if (_hasOptimized)
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: () {
                if (_allPolylinePoints.isNotEmpty) {
                  _fitBounds(_allPolylinePoints);
                }
              },
              tooltip: 'Xem toàn bộ',
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _depotLocation,
              initialZoom: 13,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.delivery_management',
              ),

              // Polyline layer
              if (_allPolylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _allPolylinePoints,
                      color: AppColors.primary,
                      strokeWidth: 4,
                    ),
                  ],
                ),

              // Markers layer
              MarkerLayer(
                markers: [
                  // Depot marker
                  Marker(
                    point: _depotLocation,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.warehouse,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  // Stop markers
                  if (_routeModel != null)
                    ..._routeModel!.stops.asMap().entries.map((entry) {
                      final index = entry.key;
                      final stop = entry.value;
                      return Marker(
                        point: LatLng(stop.lat, stop.lng),
                        width: 80,
                        height: 80,
                        child: GestureDetector(
                          onTap: () => _showStopInfo(stop, index + 1),
                          child: Column(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ],
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Đang tối ưu lộ trình...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Info card at bottom
          if (_routeModel != null && !_isLoading)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.route,
                            color: AppColors.driverPrimary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Lộ trình tối ưu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Số điểm',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${_routeModel!.stops.length}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.driverPrimary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Thời gian dự kiến',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _routeModel!.readableTotal,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.driverPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: !_hasOptimized
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _optimizeRoute,
              backgroundColor: AppColors.driverPrimary,
              icon: const Icon(Icons.route),
              label: const Text('Tối ưu lộ trình'),
            )
          : null,
    );
  }

  void _showStopInfo(RouteStopModel stop, int order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$order',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Điểm giao',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        stop.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.access_time,
              'Thời gian đến dự kiến',
              DateTime.fromMillisecondsSinceEpoch(
                stop.etaEpoch * 1000,
              ).toLocal().toString().substring(11, 16),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.location_on,
              'Tọa độ',
              '${stop.lat.toStringAsFixed(4)}, ${stop.lng.toStringAsFixed(4)}',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _mapController.move(LatLng(stop.lat, stop.lng), 16);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.driverPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.my_location),
                label: const Text('Xem trên bản đồ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
