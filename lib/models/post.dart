class Post {
  final int postId;
  final String title;
  final String content;
  final int userId;
  final String nickname;
  final String? imageUrl;
  final DateTime createdAt;

  Post({
    required this.postId,
    required this.title,
    required this.content,
    required this.userId,
    required this.nickname,
    this.imageUrl,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['postId'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      userId: json['userId'] as int,
      nickname: json['nickname'] as String,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class PostListResponse {
  final List<Post> content;
  final int totalElements;
  final int totalPages;
  final int page;
  final int size;
  final bool last;

  PostListResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.page,
    required this.size,
    required this.last,
  });

  factory PostListResponse.fromJson(Map<String, dynamic> json) {
    return PostListResponse(
      content: (json['content'] as List)
          .map((x) => Post.fromJson(x as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      page: json['page'] as int,
      size: json['size'] as int,
      last: json['last'] as bool,
    );
  }
}

