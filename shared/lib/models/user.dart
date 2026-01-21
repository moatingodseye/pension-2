class User {
  final int? id;
  final String username;
  final String? password; // Write-only/Optional for updates
  final DateTime? dob; // Optional for list views
  final bool isAdmin;
  final bool isLocked;

  User({
    this.id,
    required this.username,
    this.password,
    this.dob,
    this.isAdmin = false,
    this.isLocked = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      username: json['username'] as String,
      password: json['password'] != null ? json['password'] as String : null, // not from db but is provided by client
      dob: json['dob'] != null ? DateTime.parse(json['dob'] as String) : null,
      isAdmin: (json['isadmin'] is int ? json['isadmin'] == 1 : json['isadmin'] as bool? ?? false),
      isLocked: (json['islocked'] is int ? json['islocked'] == 1 : json['islocked'] as bool? ?? true),
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? password,
    DateTime? dob,
    bool? isAdmin,
    bool? isLocked,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      dob: dob ?? this.dob,
      isAdmin: isAdmin ?? this.isAdmin,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      if (password != null) 'password': password,
      if (dob != null) 'dob': dob!.toIso8601String().split('T')[0],
      'isadmin': isAdmin ? 1 : 0,
      'islocked': isLocked ? 1 : 0,
    };
  }
}
