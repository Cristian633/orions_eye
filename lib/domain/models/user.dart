class User {
  final String id;
  final String email;
  final String?  name;
  final String? avatarUrl;
  final DateTime? createdAt; 
  final String? cognitoId;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.createdAt,  
    this.cognitoId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      cognitoId: json['cognitoId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt?.toIso8601String(),
      'cognitoId':  cognitoId,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
    String? cognitoId,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      cognitoId: cognitoId ?? this.cognitoId,
    );
  }

  // Usuario vacío (no autenticado)
  static const User empty = User(
    id: '',
    email: '',
  );

  // Getter para saber si está autenticado
  bool get isAuthenticated => id.isNotEmpty;
}