import 'package:equatable/equatable.dart';

abstract class PhotoEvent extends Equatable {
  const PhotoEvent();

  @override
  List<Object?> get props => [];
}

class LoadPhotos extends PhotoEvent {}

class RefreshPhotos extends PhotoEvent {}

class LoadMorePhotos extends PhotoEvent {}

class SearchPhotos extends PhotoEvent {
  final String query;
  const SearchPhotos(this.query);

  @override
  List<Object?> get props => [query];
}

class RetryLoadPhotos extends PhotoEvent {}
