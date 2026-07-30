class DeezerTrackDetailModel {
  final String id;
  final String title;
  final String artistName;
  final String albumTitle;
  final String albumCoverUrl;
  final int duration;
  final int? bpm;

  DeezerTrackDetailModel({
    required this.id,
    required this.title,
    required this.artistName,
    required this.albumTitle,
    required this.albumCoverUrl,
    required this.duration,
    this.bpm,
  });

  factory DeezerTrackDetailModel.fromJson(Map<String, dynamic> json) {
    return DeezerTrackDetailModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Unknown Track',
      artistName: json['artist']?['name'] ?? 'Unknown Artist',
      albumTitle: json['album']?['title'] ?? 'Unknown Album',
      albumCoverUrl: json['album']?['cover_xl'] ?? 
                     json['album']?['cover_big'] ?? 
                     json['album']?['cover_medium'] ?? '',
      duration: json['duration'] ?? 0,
      bpm: json['bpm'] != null ? (json['bpm'] as num).toInt() : null,
    );
  }
}
