class Photo {
  final int id;
  final String photographer;
  final String photographerUrl;
  final String imageUrl;
  final String title;

  Photo({
    required this.id,
    required this.photographer,
    required this.photographerUrl,
    required this.imageUrl,
    required this.title,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    final src = json['src'] as Map<String, dynamic>?;

    return Photo(
      id: json['id'] ?? 0,
      photographer: json['photographer'] ?? 'Unknown Photographer',
      photographerUrl: json['photographer_url'] ?? '',
      imageUrl: src?['medium'] ?? '',
      title: json['alt'] ?? 'Untitled',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'photographer': photographer,
      'photographer_url': photographerUrl,
      'src': {'medium': imageUrl},
      'alt': title,
    };
  }

  Photo copyWith({
    int? id,
    String? photographer,
    String? photographerUrl,
    String? imageUrl,
    String? title,
  }) {
    return Photo(
      id: id ?? this.id,
      photographer: photographer ?? this.photographer,
      photographerUrl: photographerUrl ?? this.photographerUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
    );
  }
}
