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

class Comment {
  final int commentId;
  final int userId;
  final String nickname;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool owner; // 댓글 작성자인지 여부

  Comment({
    required this.commentId,
    required this.userId,
    required this.nickname,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    required this.owner,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['commentId'] as int,
      userId: json['userId'] as int,
      nickname: json['nickname'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      owner: json['owner'] as bool,
    );
  }
}

class PostDetail {
  final int postId;
  final String title;
  final String content;
  final int userId;
  final String nickname;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String status;
  final int likeCount;
  final List<Comment> comments;
  final bool owner; // 게시글 작성자인지 여부

  PostDetail({
    required this.postId,
    required this.title,
    required this.content,
    required this.userId,
    required this.nickname,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    required this.status,
    required this.likeCount,
    required this.comments,
    required this.owner,
  });

  factory PostDetail.fromJson(Map<String, dynamic> json) {
    return PostDetail(
      postId: json['postId'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      userId: json['userId'] as int,
      nickname: json['nickname'] as String,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      status: json['status'] as String,
      likeCount: json['likeCount'] as int,
      comments: (json['comments'] as List? ?? [])
          .map((x) => Comment.fromJson(x as Map<String, dynamic>))
          .toList(),
      owner: json['owner'] as bool,
    );
  }
}

