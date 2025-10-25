import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
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
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Cho phép nhận 4xx để tự xử lý, chặn 5xx để ném DioException
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Bỏ qua SSL (chỉ nên dùng khi DEV / localhost, không dùng production)
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Gắn Bearer token nếu có
          final token = StorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Log request
          _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
          // Log body ở dạng JSON string cho dễ đối chiếu với Swagger
          final data = options.data;
          if (data == null) {
            _logger.d('DATA: null');
          } else if (data is String) {
            _logger.d('DATA: $data');
          } else {
            try {
              _logger.d('DATA: ${jsonEncode(data)}');
            } catch (_) {
              _logger.d('DATA: $data');
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Bạn có thể mở log này nếu cần
          // _logger.d('RESP[${response.statusCode}] ${response.requestOptions.path}');
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

  /// Luôn gửi JSON hợp lệ:
  /// - Nếu `data` là Map/List => jsonEncode
  /// - Nếu `data` là String => dùng nguyên văn
  Future<Response> post(String path, {dynamic data}) async {
    try {
      final payload = (data is Map || data is List) ? jsonEncode(data) : data;
      return await _dio.post(
        path,
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer ${StorageService.getToken() ?? ''}',
          },
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      final payload = (data is Map || data is List) ? jsonEncode(data) : data;
      return await _dio.put(
        path,
        data: payload,
        options: Options(contentType: Headers.jsonContentType),
      );
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
                'Lỗi từ server ($statusCode)';
          } else if (data is String) {
            errorMessage = data;
          } else {
            errorMessage = 'Lỗi từ server ($statusCode)';
          }
        } else {
          errorMessage = 'Lỗi $statusCode';
        }
        break;

      case DioExceptionType.cancel:
        errorMessage = 'Yêu cầu đã bị hủy';
        break;

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

      default:
        errorMessage = error.message ?? 'Lỗi không xác định';
    }

    return errorMessage;
  }
}
