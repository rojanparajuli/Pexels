import 'package:dio/dio.dart';

class ApiClient {
  static Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.pexels.com/v1/',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Authorization':
              '4tL8cAJsHMYjdE9fjBmGXuVBolbojwp4WqoS1QcfrG1CevXXAwbn1A8O',
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: false,
        responseBody: false,
        responseHeader: false,
        error: true,
      ),
    );

    return dio;
  }
}
