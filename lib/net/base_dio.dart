import 'package:dio/dio.dart';
import 'package:flutter_bloc_basic/net/base_response.dart';
import 'package:flutter_bloc_basic/net/base_response_converter.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

enum Method { GET, POST, PUT, PATCH, DELETE, HEAD }

extension MethodExtension on Method {
  String get value => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD'][index];
}

class BaseDio {
  static BaseDio get instance => BaseDio();

  factory BaseDio() {
    return _singleton;
  }

  static final BaseDio _singleton = BaseDio._internal();

  static late final Dio _dio;

  static late final BaseResponseConverter converter;

  BaseDio._internal() {
    _dio = Dio();
    _dio.options = BaseOptions(
      receiveTimeout: 15 * 1000,
      connectTimeout: 15 * 1000,
      sendTimeout: 15 * 1000,
    );

    /// HTTP Log 拦截器
    _dio.interceptors.add(PrettyDioLogger(
        // 添加日志格式化工具类
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: false,
        maxWidth: 200));
  }

  configDio(
      {required String baseUrl,
      required BaseResponseConverter baseResponseConverter}) {
    _dio.options.baseUrl = baseUrl;
    converter = baseResponseConverter;
  }

  /// 数据返回格式统一
  Future<BaseResponse<T>?> request<T>(
    String method,
    String url, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    final _result = await _dio.request<Map<String, dynamic>>(
      url,
      data: body,
      queryParameters: queryParameters,
      options: _checkOptions(method, options),
      cancelToken: cancelToken,
    );
    if (_result.data != null) {
      return BaseResponse(
          code: _result.data!["code"],
          message: _result.data!["message"],
          result: await converter.convertFromJson<T>(_result.data!["result"]));
    } else {
      return null;
    }
  }

  Options _checkOptions(String method, Options? options) {
    options ??= Options();
    options.method = method;
    return options;
  }
}
