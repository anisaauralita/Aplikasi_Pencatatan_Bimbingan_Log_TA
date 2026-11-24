class UserModel {
  final String id; // uid Firebase
  final String nama;
  final String nim;
  final String email;

  // Data profil tambahan (opsional, diisi dari halaman Profil)
  final String prodi; // program studi
  final String angkatan; // tahun masuk, misal '2023'
  final String noHp;
  final String? fotoPath; // path foto profil di HP ini (lokal), null = belum ada

  UserModel({
    required this.id,
    required this.nama,
    required this.nim,
    required this.email,
    this.prodi = '',
    this.angkatan = '',
    this.noHp = '',
    this.fotoPath,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> m) {
    final foto = (m['foto_profil_path'] ?? '').toString();
    return UserModel(
      id: uid,
      nama: (m['nama'] ?? '') as String,
      nim: (m['nim'] ?? '') as String,
      email: (m['email'] ?? '') as String,
      prodi: (m['prodi'] ?? '').toString(),
      angkatan: (m['angkatan'] ?? '').toString(),
      noHp: (m['no_hp'] ?? '').toString(),
      fotoPath: foto.isEmpty ? null : foto,
    );
  }
}