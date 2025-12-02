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
  final int? postId; // 게시글 ID (내가 쓴 댓글 조회 시 필요)

  Comment({
    required this.commentId,
    required this.userId,
    required this.nickname,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    required this.owner,
    this.postId,
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
      postId: json['postId'] as int?,
    );
  }
}

// 내가 쓴 게시글 DTO
class MyPost {
  final int postId;
  final String boardName;
  final String title;
  final DateTime createdAt;

  MyPost({
    required this.postId,
    required this.boardName,
    required this.title,
    required this.createdAt,
  });

  factory MyPost.fromJson(Map<String, dynamic> json) {
    return MyPost(
      postId: json['postId'] as int,
      boardName: json['boardName'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

// 내가 쓴 댓글 DTO
class MyComment {
  final int commentId;
  final int postId;
  final String postTitle;
  final String content;
  final DateTime createdAt;

  MyComment({
    required this.commentId,
    required this.postId,
    required this.postTitle,
    required this.content,
    required this.createdAt,
  });

  factory MyComment.fromJson(Map<String, dynamic> json) {
    return MyComment(
      commentId: json['commentId'] as int,
      postId: json['postId'] as int,
      postTitle: json['postTitle'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
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
  final bool isLiked; // 좋아요 상태

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
    required this.isLiked,
  });

  // 좋아요 상태와 개수를 업데이트한 새 인스턴스 생성
  PostDetail copyWith({
    bool? isLiked,
    int? likeCount,
    bool? owner,
  }) {
    return PostDetail(
      postId: postId,
      title: title,
      content: content,
      userId: userId,
      nickname: nickname,
      imageUrl: imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: status,
      likeCount: likeCount ?? this.likeCount,
      comments: comments,
      owner: owner ?? this.owner,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  factory PostDetail.fromJson(Map<String, dynamic> json) {
    // 백엔드에서 likedByUser 필드로 좋아요 상태를 제공
    final likedByUserValue = json['likedByUser'];
    bool isLiked = false;

    // 디버깅: 백엔드 응답 확인
    print('PostDetail.fromJson - likedByUser 값: $likedByUserValue (타입: ${likedByUserValue.runtimeType})');

    if (likedByUserValue != null) {
      if (likedByUserValue is bool) {
        isLiked = likedByUserValue;
      } else if (likedByUserValue is String) {
        // 문자열로 오는 경우 처리
        isLiked = likedByUserValue.toLowerCase() == 'true';
      }
    }

    final likeCount = json['likeCount'] as int;
    print('PostDetail.fromJson - likeCount: $likeCount, 초기 isLiked: $isLiked');

    // 좋아요 개수가 0이면 무조건 좋아요를 누르지 않은 상태로 설정
    if (likeCount == 0) {
      isLiked = false;
      print('PostDetail.fromJson - likeCount가 0이므로 isLiked를 false로 설정');
    }

    print('PostDetail.fromJson - 최종 isLiked: $isLiked');

    // 백엔드에서 isOwner 필드로 본인 작성 여부를 제공
    final isOwnerValue = json['isOwner'];
    bool isOwner = false;

    // 디버깅: 백엔드 응답 확인
    print('PostDetail.fromJson - isOwner 값: $isOwnerValue (타입: ${isOwnerValue.runtimeType})');

    if (isOwnerValue != null) {
      if (isOwnerValue is bool) {
        isOwner = isOwnerValue;
      } else if (isOwnerValue is String) {
        // 문자열로 오는 경우 처리
        isOwner = isOwnerValue.toLowerCase() == 'true';
      }
    }

    print('PostDetail.fromJson - 최종 isOwner: $isOwner');

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
      likeCount: likeCount,
      comments: (json['comments'] as List? ?? [])
          .map((x) => Comment.fromJson(x as Map<String, dynamic>))
          .toList(),
      owner: isOwner,
      isLiked: isLiked,
    );
  }
}

