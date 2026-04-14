class SpotifyMetadataModel {
  final String title;
  final String thumbnailUrl;

  SpotifyMetadataModel({
    required this.title,
    required this.thumbnailUrl,
  });

  factory SpotifyMetadataModel.fromJson(Map<String, dynamic> json) {
    return SpotifyMetadataModel(
      title: json['title'] ?? 'Unknown Track',
      thumbnailUrl: json['thumbnail_url'] ?? '',
    );
  }
}
