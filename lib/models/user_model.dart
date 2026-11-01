class UserModel {
  final int? id;
  final String nama;
  final String nim;
  final String email;
  final String passwordHash;
  final String salt;
  final String createdAt;

  UserModel({
    this.id,
    required this.nama,
    required this.nim,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'nim': nim,
        'email': email,
        'password_hash': passwordHash,
        'salt': salt,
        'created_at': createdAt,
      };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        id: m['id'] as int?,
        nama: m['nama'] as String,
        nim: m['nim'] as String,
        email: m['email'] as String,
        passwordHash: m['password_hash'] as String,
        salt: m['salt'] as String,
        createdAt: m['created_at'] as String,
      );
}