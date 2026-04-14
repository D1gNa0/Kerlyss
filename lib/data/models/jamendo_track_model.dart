class JamendoTrackModel {
  final String id;
  final String name;
  final String artistName;
  final String albumName;
  final int duration;
  final String image;
  final String audioUrl;
  final String audioDownloadUrl;

  JamendoTrackModel({
    required this.id,
    required this.name,
    required this.artistName,
    required this.albumName,
    required this.duration,
    required this.image,
    required this.audioUrl,
    required this.audioDownloadUrl,
  });

  factory JamendoTrackModel.fromJson(Map<String, dynamic> json) {
    return JamendoTrackModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Track',
      artistName: json['artist_name'] ?? 'Unknown Artist',
      albumName: json['album_name'] ?? 'Unknown Album',
      duration: json['duration'] ?? 0,
      image: json['image'] ?? '',
      audioUrl: json['audio'] ?? '',
      audioDownloadUrl: json['audiodownload'] ?? '',
    );
  }
}
