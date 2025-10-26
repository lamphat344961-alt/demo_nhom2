// File: lib/screens/owner/dashboard_tab.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import 'nfc_score_screen.dart'; // 🆕 THÊM MỚI: Import màn hình NFC

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _errorMessage;

  int _totalOrders = 0;
  int _totalVehicles = 0;
  int _totalProducts = 0;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _api.get(ApiConstants.orders),
        _api.get(ApiConstants.vehicles),
        _api.get(ApiConstants.products),
        _api.get(ApiConstants.deliveryPoints),
      ]);

      setState(() {
        _totalOrders =
            (results[0].data is List ? results[0].data as List : []).length;
        _totalVehicles =
            (results[1].data is List ? results[1].data as List : []).length;
        _totalProducts =
            (results[2].data is List ? results[2].data as List : []).length;
        _totalPoints =
            (results[3].data is List ? results[3].data as List : []).length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_errorMessage != null) {
      return ErrorDisplayWidget(
        message: _errorMessage!,
        onRetry: _loadDashboardData,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNfcButton(), // 🆕 THÊM: Nút Cộng điểm NFC
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            Text(
              'Biểu đồ tổng quan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildChart(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 🆕 THÊM MỚI: Nút Cộng điểm NFC và chuyển hướng
  Widget _buildNfcButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NfcScoreScreen()),
        );
      },
      icon: const Icon(Icons.nfc, size: 28),
      label: const Text('CỘNG ĐIỂM THƯỞNG BẰNG NFC'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê tổng quan'),
        backgroundColor: AppColors.ownerPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          'Đơn hàng',
          _totalOrders.toString(),
          Icons.inventory_2,
          AppColors.primary,
        ),
        _buildStatCard(
          'Xe',
          _totalVehicles.toString(),
          Icons.local_shipping,
          AppColors.success,
        ),
        _buildStatCard(
          'Hàng hóa',
          _totalProducts.toString(),
          Icons.category,
          AppColors.warning,
        ),
        _buildStatCard(
          'Điểm giao',
          _totalPoints.toString(),
          Icons.location_on,
          AppColors.error,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final totals = [_totalOrders, _totalVehicles, _totalProducts, _totalPoints];
    final maxCount = totals.fold(0, (a, b) => a > b ? a : b);
    final double safeMaxY = (maxCount > 0 ? maxCount * 1.2 : 5).toDouble();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: safeMaxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const titles = ['Đơn', 'Xe', 'Hàng', 'Điểm'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      titles[value.toInt()],
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            _buildBarGroup(0, _totalOrders.toDouble(), AppColors.primary),
            _buildBarGroup(1, _totalVehicles.toDouble(), AppColors.success),
            _buildBarGroup(2, _totalProducts.toDouble(), AppColors.warning),
            _buildBarGroup(3, _totalPoints.toDouble(), AppColors.error),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }
}
