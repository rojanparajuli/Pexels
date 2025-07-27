import 'package:flutter_bloc/flutter_bloc.dart';
import 'photo_event.dart';
import 'photo_state.dart';
import '../../data/photo_repository.dart';

class PhotoBloc extends Bloc<PhotoEvent, PhotoState> {
  final PhotoRepository repository;

  int _currentPage = 1;
  final int _perPage = 20;
  bool _isFetching = false; // prevents duplicate calls

  PhotoBloc(this.repository) : super(PhotoInitial()) {
    on<LoadPhotos>(_onLoadPhotos);
    on<LoadMorePhotos>(_onLoadMorePhotos);
    on<RefreshPhotos>(_onRefreshPhotos);
    on<SearchPhotos>(_onSearchPhotos);
    on<RetryLoadPhotos>(_onRetryLoadPhotos);
  }

  Future<void> _onLoadPhotos(LoadPhotos event, Emitter<PhotoState> emit) async {
    emit(PhotoLoading());
    _currentPage = 1;
    try {
      final photos = await repository.fetchCuratedPhotos(
        page: _currentPage,
        perPage: _perPage,
      );

      emit(PhotoLoaded(photos: photos, hasMore: photos.length == _perPage));
    } catch (e) {
      emit(PhotoError('Failed to load photos: $e'));
    }
  }

  Future<void> _onLoadMorePhotos(
    LoadMorePhotos event,
    Emitter<PhotoState> emit,
  ) async {
    if (_isFetching || state is! PhotoLoaded) return;

    final currentState = state as PhotoLoaded;
    if (!currentState.hasMore) return; // No more pages

    emit(currentState.copyWith(isLoadingMore: true));
    _isFetching = true;

    try {
      _currentPage++;
      final morePhotos = await repository.fetchCuratedPhotos(
        page: _currentPage,
        perPage: _perPage,
      );

      final allPhotos = [...currentState.photos, ...morePhotos];

      emit(
        PhotoLoaded(photos: allPhotos, hasMore: morePhotos.length == _perPage),
      );
    } catch (e) {
      // If pagination fails, we keep the old photos
      emit(currentState.copyWith(isLoadingMore: false));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _onRefreshPhotos(
    RefreshPhotos event,
    Emitter<PhotoState> emit,
  ) async {
    _currentPage = 1;
    try {
      final photos = await repository.fetchCuratedPhotos(
        page: _currentPage,
        perPage: _perPage,
      );

      emit(PhotoLoaded(photos: photos, hasMore: photos.length == _perPage));
    } catch (e) {
      emit(PhotoError('Failed to refresh photos: $e'));
    }
  }

  Future<void> _onSearchPhotos(
    SearchPhotos event,
    Emitter<PhotoState> emit,
  ) async {
    emit(PhotoLoading());
    try {
      final photos = await repository.searchPhotos(event.query, page: 1);

      emit(PhotoLoaded(photos: photos, hasMore: photos.length == _perPage));
    } catch (e) {
      emit(PhotoError('Search failed: $e'));
    }
  }

  Future<void> _onRetryLoadPhotos(
    RetryLoadPhotos event,
    Emitter<PhotoState> emit,
  ) async {
    add(LoadPhotos());
  }
}
