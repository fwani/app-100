class Post {
  final int id;
  final int roomId;
  final int? authorId;
  final String? text;
  final List<String> photos;
  final String? mood;
  final DateTime? shotAt;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.roomId,
    this.authorId,
    this.text,
    required this.photos,
    this.mood,
    this.shotAt,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> j) => Post(
    id: j['id'],
    roomId: j['room_id'],
    authorId: j['author_id'],
    text: j['text'],
    photos: (j['photos'] as List).cast<String>(),
    mood: j['mood'],
    shotAt: j['shot_at'] != null ? DateTime.parse(j['shot_at']) : null,
    createdAt: DateTime.parse(j['created_at']),
  );
}