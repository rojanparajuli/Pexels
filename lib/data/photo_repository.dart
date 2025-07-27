import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import 'photo_model.dart';

class PhotoRepository {
  final Dio _dio = ApiClient.createDio();

  Future<List<Photo>> fetchCuratedPhotos({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        'curated',
        queryParameters: {'page': page, 'per_page': perPage},
      );

      if (response.statusCode == 200 && response.data['photos'] != null) {
        final List<dynamic> photosJson = response.data['photos'];
        return photosJson.map((json) => Photo.fromJson(json)).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      debugPrint("❌ Error fetching curated photos: ${e.message}");
      return [];
    } catch (e) {
      debugPrint("❌ Unknown error: $e");
      return [];
    }
  }

  Future<List<Photo>> searchPhotos(String query, {int page = 1}) async {
    try {
      final response = await _dio.get(
        'search',
        queryParameters: {'query': query, 'page': page, 'per_page': 20},
      );

      if (response.statusCode == 200 && response.data['photos'] != null) {
        final List<dynamic> photosJson = response.data['photos'];
        return photosJson.map((json) => Photo.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint("❌ Error searching photos: ${e.message}");
      return [];
    } catch (e) {
      debugPrint("❌ Unknown error: $e");
      return [];
    }
  }
}
