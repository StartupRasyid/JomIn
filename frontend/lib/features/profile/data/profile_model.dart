class ProfileModel {
  final String userId;
  final String fullName;
  final String? faculty;
  final int? yearOfStudy;
  final String? bio;
  final int postCount;
  final List<PostModel> posts;

  ProfileModel({
    required this.userId,
    required this.fullName,
    this.faculty,
    this.yearOfStudy,
    this.bio,
    required this.postCount,
    required this.posts,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: json['userId'],
      fullName: json['fullName'],
      faculty: json['faculty'],
      yearOfStudy: json['yearOfStudy'],
      bio: json['studentProfile']?['bio'],
      postCount: json['_count']?['events'] ?? 0,
      posts: (json['events'] as List<dynamic>?)
              ?.map((e) => PostModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class PostModel {
  final String eventId;
  final String title;
  final String mediaUrl;

  PostModel({required this.eventId, required this.title, required this.mediaUrl});

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      eventId: json['eventId'],
      title: json['title'],
      mediaUrl: json['mediaUrl'],
    );
  }
}