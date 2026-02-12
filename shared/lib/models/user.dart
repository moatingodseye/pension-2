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

  factory User.fromDb(Map<String, Object?> row) {
    final json = <String,dynamic>{};
    row.forEach((columnName, value) {
      switch (columnName) {
        case 'intoid':
          json['intoId'] = value; // just a string at the point
          break;
        default:
          json[columnName] = value;
      }
    });

    // Single source of truth
    return User.fromJson(json); 
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      username: json['username'] as String,
      password: json['password'] != null ? json['password'] as String : null, // not from db but is provided by client
      dob: json['dob'] == null
          ? null
          : json['dob'] is String
              ? DateTime.tryParse(json['dob'] as String)
              : json['dob'] is int
                  ? DateTime.fromMillisecondsSinceEpoch(json['dob'] as int)
                  : null,
      isAdmin: (json['isAdmin'] ?? json['isadmin']) is int 
          ? ((json['isAdmin'] ?? json['isadmin']) == 1) 
          : ((json['isAdmin'] ?? json['isadmin']) as bool? ?? false),
      isLocked: (json['isLocked'] ?? json['islocked']) is int 
          ? ((json['isLocked'] ?? json['islocked']) == 1) 
          : ((json['isLocked'] ?? json['islocked']) as bool? ?? false),
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
