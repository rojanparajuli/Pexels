
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pexels/data/photo_model.dart';
import 'package:pexels/logic/photo_bloc.dart';
import 'package:pexels/logic/photo_event.dart';
import 'package:pexels/logic/photo_state.dart';
import 'package:pexels/presentation/widgets/photo_grid.dart';

class EnhancedHomePage extends StatefulWidget {
  const EnhancedHomePage({super.key});

  @override
  State<EnhancedHomePage> createState() => _EnhancedHomePageState();
}

class _EnhancedHomePageState extends State<EnhancedHomePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingMore = false;
  bool _isSearching = false;
  List<Photo> _filteredPhotos = [];

  @override
  void initState() {
    super.initState();
    context.read<PhotoBloc>().add(LoadPhotos());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
  if (_scrollController.position.pixels ==
      _scrollController.position.maxScrollExtent) {
    _loadMorePhotos();
  }
}

void _loadMorePhotos() {
  if (!_isLoadingMore) {
    setState(() => _isLoadingMore = true);
    context.read<PhotoBloc>().add(LoadMorePhotos());
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _isLoadingMore = false);
    });
  }
}


  void _searchPhotos(String query, List<Photo> allPhotos) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _filteredPhotos = allPhotos.where((photo) =>
            photo.photographer.toLowerCase().contains(query.toLowerCase()) ||
            (photo.photographer).toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by photographer or description',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _isSearching = false;
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  final state = context.read<PhotoBloc>().state;
                  if (state is PhotoLoaded) {
                    _searchPhotos(value, state.photos);
                  }
                },
              )
            : const Text('Pexels Gallery'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.search_off : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: BlocBuilder<PhotoBloc, PhotoState>(
        builder: (context, state) {
          if (state is PhotoLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PhotoLoaded) {
            final photosToDisplay = _isSearching ? _filteredPhotos : state.photos;
            
            return RefreshIndicator(
              onRefresh: () async {
                context.read<PhotoBloc>().add(RefreshPhotos());
              },
              child: Stack(
                children: [
                  CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      if (!_isSearching) 
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          sliver: SliverToBoxAdapter(
                            child: _buildFeaturedPhoto(state.photos.isNotEmpty 
                                ? state.photos.first 
                                : null),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.all(8),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            _isSearching 
                                ? 'Search Results (${_filteredPhotos.length})'
                                : 'Recent Photos',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        sliver: EnhancedPhotoSliverGrid(photos: photosToDisplay),
                      ),
                      if (_isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      if (_isSearching && _filteredPhotos.isEmpty)
                        const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'No matching photos found!',
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          } else if (state is PhotoError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PhotoBloc>().add(LoadPhotos());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildFeaturedPhoto(Photo? photo) {
    if (photo == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 16/9,
              child: CachedNetworkImage(
                imageUrl: photo.url,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Featured Photo',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      photo.photographer,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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