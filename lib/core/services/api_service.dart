import 'dart:io';
import 'package:dio/io.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final Logger _logger = Logger();

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.timeout,
        receiveTimeout: ApiConstants.timeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          // Chấp nhận cả status code lỗi để xử lý
          return status != null && status < 500;
        },
      ),
    );

    // THÊM ĐOẠN CODE NÀY ĐỂ BỎ QUA LỖI CHỨNG CHỈ SSL (HTTPS)
    // Chỉ dùng cho môi trường development
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      // Bỏ qua tất cả các chứng chỉ không hợp lệ
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = StorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
          _logger.d('DATA: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // debugPrint('RESP[${response.statusCode}] ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          _logger.e(
            'ERROR[${error.response?.statusCode}] => MESSAGE: ${error.message}',
          );
          _logger.e('ERROR DATA: ${error.response?.data}');

          if (error.response?.statusCode == 401) {
            await StorageService.clearAll();
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> get(
      String path, {
        Map<String, dynamic>? queryParameters,
      }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    String errorMessage = 'Đã xảy ra lỗi';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Kết nối timeout. Vui lòng kiểm tra mạng.';
        break;

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (data != null) {
          if (data is Map) {
            errorMessage =
                data['message'] ??
                    data['error'] ??
                    data['title'] ??
                    'Lỗi từ server (${statusCode})';
          } else if (data is String) {
            errorMessage = data;
          }
        } else {
          errorMessage = 'Lỗi ${statusCode}';
        }
        break;

      case DioExceptionType.cancel:
        errorMessage = 'Yêu cầu đã bị hủy';
        break;

    // Lỗi SSL thường rơi vào 1 trong 2 trường hợp này
      case DioExceptionType.connectionError:
        errorMessage = 'Không thể kết nối đến server. Kiểm tra IP/mạng/SSL.';
        break;
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          errorMessage = 'Lỗi Socket: Không thể kết nối. Kiểm tra IP/mạng/SSL.';
        } else {
          errorMessage = 'Lỗi không xác định: ${error.message}';
        }
        break;
    // ======================================================

      default:
        errorMessage = error.message ?? 'Lỗi không xác định';
    }

    return errorMessage;
  }
}