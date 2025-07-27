import 'package:equatable/equatable.dart';
import '../../data/photo_model.dart';

abstract class PhotoState extends Equatable {
  const PhotoState();

  @override
  List<Object?> get props => [];
}

class PhotoInitial extends PhotoState {}

class PhotoLoading extends PhotoState {}

class PhotoLoaded extends PhotoState {
  final List<Photo> photos;
  final bool hasMore;
  final bool isLoadingMore;

  const PhotoLoaded({
    required this.photos,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  PhotoLoaded copyWith({
    List<Photo>? photos,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PhotoLoaded(
      photos: photos ?? this.photos,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [photos, hasMore, isLoadingMore];
}

class PhotoError extends PhotoState {
  final String message;
  const PhotoError(this.message);

  @override
  List<Object?> get props => [message];
}
