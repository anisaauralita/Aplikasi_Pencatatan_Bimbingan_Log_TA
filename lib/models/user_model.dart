class UserModel {
  final String id; // uid Firebase
  final String nama;
  final String nim;
  final String email;

  UserModel({
    required this.id,
    required this.nama,
    required this.nim,
    required this.email,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> m) => UserModel(
        id: uid,
        nama: (m['nama'] ?? '') as String,
        nim: (m['nim'] ?? '') as String,
        email: (m['email'] ?? '') as String,
      );
}