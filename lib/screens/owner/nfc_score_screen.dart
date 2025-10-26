// File: lib/screens/owner/nfc_score_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/owner_service.dart';

class NfcScoreScreen extends StatefulWidget {
  const NfcScoreScreen({super.key});

  @override
  State<NfcScoreScreen> createState() => _NfcScoreScreenState();
}

class _NfcScoreScreenState extends State<NfcScoreScreen> {
  final OwnerService _ownerService = OwnerService();
  final TextEditingController _pointsController = TextEditingController(
    text: '1',
  );
  String _scanStatus = 'Sẵn sàng. Nhấn nút để bắt đầu quét.';
  bool _isNFCAvailable = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
  }

  @override
  void dispose() {
    // Đảm bảo session NFC dừng khi màn hình bị hủy
    if (_isScanning) {
      _finishNfcOperation();
    }
    _pointsController.dispose();
    super.dispose();
  }

  // Kiểm tra thiết bị có hỗ trợ NFC không
  Future<void> _checkNFCAvailability() async {
    final avail = await FlutterNfcKit.nfcAvailability;
    final isAvailable = avail == NFCAvailability.available;
    if (mounted) {
      setState(() {
        _isNFCAvailable = isAvailable;
        _scanStatus = isAvailable
            ? 'NFC khả dụng. Nhấn nút để quét.'
            : 'Lỗi: Thiết bị không hỗ trợ hoặc chưa bật NFC.';
      });
    }
  }

  // Hàm kết thúc thao tác NFC
  Future<void> _finishNfcOperation() async {
    try {
      await FlutterNfcKit.finish();
    } catch (_) {}
  }

  void _startNfcScan() async {
    if (!_isNFCAvailable) {
      _showSnackbar('Thiết bị không hỗ trợ NFC.');
      return;
    }

    final int? points = int.tryParse(_pointsController.text.trim());
    if (points == null || points <= 0) {
      _showSnackbar('Vui lòng nhập số điểm hợp lệ (> 0).');
      return;
    }

    setState(() {
      _isScanning = true;
      _scanStatus = 'Đang quét... Vui lòng chạm thẻ NFC.';
    });

    try {
      // SỬA LỖI: Xóa tham số iosMultipleTagDiscovery: false,
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 20),
        // Các tham số khác của poll() được giữ nguyên nếu cần
      );

      // 1. Lấy ID thẻ: tag.id là cách lấy UID chính xác trong flutter_nfc_kit
      final nfcId = tag.id;
      if (nfcId == null || nfcId.isEmpty) {
        throw Exception('Không đọc được ID thẻ NFC. Hãy thử lại.');
      }

      // Sử dụng context an toàn
      final currentContext = context;
      if (!currentContext.mounted) {
        await _finishNfcOperation();
        return;
      }

      _handleScanResult(
        'Đã quét thẻ ID: $nfcId. Đang gửi yêu cầu cộng điểm...',
        success: true,
      );

      // 2. Gọi API Backend
      try {
        // ID thẻ cần được gửi dưới dạng chuỗi Hex (tag.id đã là chuỗi Hex)
        final result = await _ownerService.addScoreByNfc(
          nfcId.toUpperCase(),
          points,
        );

        _handleScanResult(
          'Thành công! ${result['message']}\nĐiểm mới: ${result['newScore']}',
          success: true,
        );
      } catch (e) {
        _handleScanResult('Lỗi API: ${e.toString()}', success: false);
      }
    } catch (e) {
      // Bắt các lỗi từ FlutterNfcKit.poll()
      _handleScanResult('Lỗi quét: ${e.toString()}', success: false);
    } finally {
      await _finishNfcOperation();
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  void _handleScanResult(String message, {required bool success}) {
    if (!mounted) return;

    setState(() {
      _scanStatus = message;
      _isScanning = false;
    });

    _showSnackbar(message, isError: !success);
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cộng điểm bằng NFC'),
        backgroundColor: AppColors.ownerPrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Chức năng này dùng để Owner (Chủ xe) quét thẻ NFC của tài xế để cộng điểm thưởng. ID thẻ sẽ được Backend sử dụng để nhận diện tài xế.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // INPUT SỐ ĐIỂM
            TextField(
              controller: _pointsController,
              keyboardType: TextInputType.number,
              enabled: !_isScanning,
              decoration: InputDecoration(
                labelText: 'Số điểm muốn cộng',
                hintText: 'Nhập số điểm (ví dụ: 1)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _pointsController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // BUTTON BẮT ĐẦU QUÉT
            ElevatedButton.icon(
              onPressed: _isScanning || !_isNFCAvailable ? null : _startNfcScan,
              icon: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.nfc),
              label: Text(_isScanning ? 'ĐANG QUÉT...' : 'BẮT ĐẦU QUÉT THẺ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ownerPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // KHU VỰC TRẠNG THÁI
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trạng thái:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _scanStatus,
                      style: TextStyle(
                        color: _scanStatus.contains('Lỗi')
                            ? AppColors.error
                            : AppColors.textPrimary,
                        fontStyle: _isScanning
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
