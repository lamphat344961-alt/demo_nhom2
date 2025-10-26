// File: lib/core/services/owner_service.dart

import '../constants/api_constants.dart';
import 'api_service.dart';

class OwnerService {
  final ApiService _api = ApiService();

  /// Gọi API cộng điểm cho tài xế bằng ID thẻ NFC
  /// Backend: POST /api/Owner/add-score
  Future<Map<String, dynamic>> addScoreByNfc(
    String cardId,
    int pointsToAdd,
  ) async {
    try {
      final response = await _api.post(
        ApiConstants.addDriverScore,
        data: {'cardId': cardId, 'pointsToAdd': pointsToAdd},
      );

      // Backend trả về: { message: ..., newScore: ... }
      if (response.statusCode == 200 && response.data != null) {
        return {
          'success': true,
          'message': response.data['message'],
          'newScore': response.data['newScore'],
        };
      }

      // Xử lý lỗi 4xx (đã được ApiService bắt và ném ra dưới dạng String)
      if (response.statusCode! >= 400 && response.statusCode! < 500) {
        throw response.data['message'] ??
            'Thẻ không hợp lệ hoặc lỗi nghiệp vụ.';
      }

      throw 'Lỗi Server: ${response.statusCode}';
    } catch (e) {
      // Re-throw lỗi đã được xử lý từ ApiService
      if (e is String) rethrow;
      throw 'Lỗi kết nối khi cộng điểm: ${e.toString()}';
    }
  }
}
