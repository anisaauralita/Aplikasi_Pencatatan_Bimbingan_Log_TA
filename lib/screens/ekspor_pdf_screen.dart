// =====================================================================
// FILE   : lib/screens/ekspor_pdf_screen.dart
// FUNGSI : Halaman EKSPOR PDF (Kartu Bimbingan + Rekap Revisi).
//          Alur kerja halaman ini:
//            1. Saat dibuka, memuat DATA ASLI dari Firestore: profil
//               (nama, NIM, judul TA, dosen), log bimbingan, revisi,
//               dan bab.
//            2. Menampilkan ringkasan jumlah data + pratinjau kartu.
//            3. Mahasiswa mengisi catatan tambahan (opsional).
//            4. Tombol "Ekspor ke PDF" membuat dokumen PDF berisi:
//               identitas (nama, NIM, judul TA, dosen), ringkasan
//               progres + PIE CHART revisi, tabel log bimbingan, tabel
//               revisi per bab, foto bukti perbaikan, catatan, dan
//               kotak pengesahan (kosong, untuk tanda tangan basah).
//            5. Setelah jadi, mahasiswa bisa membuka/mencetak PDF atau
//               membagikan/menyimpannya (Drive, WhatsApp, dll).
//          Halaman ini TIDAK memakai menu bawah (Beranda/Bab/Bimbingan/
//          Revisi) karena dibuka sebagai halaman tambahan; navigasi balik
//          lewat panah AppBar atau tombol "Batal" / "Kembali ke Beranda".
//          Paket yang dipakai (sudah ada di pubspec.yaml): pdf, printing,
//          cloud_firestore, provider.
// =====================================================================
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/fs_helper.dart';

// ---------- Model ringan khusus layar ini (hanya untuk membuat PDF) ----------

/// Satu log bimbingan
class _DataLog {
  final String id;
  final DateTime tanggal;
  final String catatan;
  const _DataLog(this.id, this.tanggal, this.catatan);
}

/// Satu revisi
class _DataRevisi {
  final String poin;
  final String bab;
  final bool selesai;
  final String? foto;
  final String? logId;
  const _DataRevisi({
    required this.poin,
    required this.bab,
    required this.selesai,
    this.foto,
    this.logId,
  });

  // 'Bab 2 - Tinjauan Pustaka' -> 'Bab 2'
  String get babPendek {
    final i = bab.indexOf(' - ');
    return i == -1 ? bab : bab.substring(0, i);
  }
}

// Definisi kelas EksporPdfScreen sebagai StatefulWidget karena halaman memiliki status interaktif (input, data)
class EksporPdfScreen extends StatefulWidget {
  const EksporPdfScreen({super.key});

  @override
  State<EksporPdfScreen> createState() => _EksporPdfScreenState();
}

class _EksporPdfScreenState extends State<EksporPdfScreen> {
  static const _primary = Color(0xFF4338CA);
  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  // Controller untuk membaca isi teks inputan "Catatan Tambahan"
  final TextEditingController _catatanController = TextEditingController();

  // ---------- Data dari Firestore ----------
  late final String _uid; // id pengguna yang sedang login
  DocumentReference<Map<String, dynamic>> get _base =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  bool _memuat = true; // true selama data masih diambil
  String? _error; // pesan error jika gagal memuat
  String _nama = '-';
  String _nim = '-';
  String _judul = 'Belum diisi';
  String _dosen = 'Belum diisi';
  List<_DataLog> _logs = [];
  List<_DataRevisi> _revisis = [];
  int _babTotal = 0; // jumlah semua bab
  int _babAcc = 0; // jumlah bab yang sudah ACC

  // ---------- Status ekspor ----------
  bool _mengekspor = false; // true saat PDF sedang dibuat
  Uint8List? _pdfBytes; // hasil PDF (null = belum diekspor)
  String? _namaFile; // nama file PDF hasil ekspor

  @override
  void initState() {
    super.initState();
    _uid = context.read<AuthProvider>().currentUser!.id;
    _muat();
  }

  // Membebaskan memori controller saat halaman ditutup
  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  // ====================== PENGAMBILAN DATA ======================

  // Ambil dokumen profil user (cache dulu, lalu server maksimal 6 detik)
  Future<DocumentSnapshot<Map<String, dynamic>>?> _ambilProfil() async {
    try {
      final c = await _base.get(const GetOptions(source: Source.cache));
      if (c.exists) return c;
    } catch (_) {}
    try {
      return await _base.get().timeout(const Duration(seconds: 6));
    } catch (_) {
      return null;
    }
  }

  // Nomor bab dari teks 'Bab 2 - ...' (dipakai untuk mengurutkan)
  int _nomorBab(String s) {
    final m = RegExp(r'Bab\s*(\d+)').firstMatch(s);
    return m == null ? 0 : int.parse(m.group(1)!);
  }

  // Muat semua data yang dibutuhkan PDF dari Firestore
  Future<void> _muat() async {
    try {
      final logSnap =
          await ambilCepat(_base.collection('logs').orderBy('tanggal'));
      final revSnap = await ambilCepat(_base.collection('revisions'));
      final babSnap = await ambilCepat(_base.collection('chapters'));
      final profil = await _ambilProfil();

      // Log bimbingan (urut dari tanggal terlama)
      final logs = logSnap.docs.map((d) {
        final x = d.data();
        final t = x['tanggal'];
        return _DataLog(
          d.id,
          t is Timestamp ? t.toDate() : DateTime.now(),
          (x['catatan'] ?? '').toString(),
        );
      }).toList();

      // Revisi (diurutkan menurut nomor bab)
      final revs = revSnap.docs.map((d) {
        final x = d.data();
        final foto = x['foto_path'] as String?;
        final lid = x['log_id'] as String?;
        return _DataRevisi(
          poin: (x['poin'] ?? '').toString(),
          bab: (x['bab'] ?? '').toString(),
          selesai: x['is_done'] == true,
          foto: (foto == null || foto.isEmpty) ? null : foto,
          logId: (lid == null || lid.isEmpty) ? null : lid,
        );
      }).toList()
        ..sort((a, b) => _nomorBab(a.bab).compareTo(_nomorBab(b.bab)));

      final u = profil?.data();
      if (!mounted) return;
      setState(() {
        _nama = (u?['nama'] ?? u?['name'] ?? u?['nama_lengkap'] ?? '-').toString();
        _nim = (u?['nim'] ?? '-').toString();
        _judul = (u?['judul_ta'] ?? 'Belum diisi').toString();
        _dosen = (u?['dosen'] ?? 'Belum diisi').toString();
        _logs = logs;
        _revisis = revs;
        _babTotal = babSnap.docs.length;
        _babAcc = babSnap.docs.where((c) => c.data()['is_done'] == true).length;
        _memuat = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _memuat = false;
        _error = e.toString();
      });
    }
  }

  // ====================== PEMBUATAN PDF ======================

  // Format tanggal '05 Okt 2026'
  String _tgl(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_bulan[d.month - 1]} ${d.year}';

  // Nama file, misal 'Kartu_Bimbingan_Siti.pdf'
  String _buatNamaFile() {
    final bersih = _nama.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final inti = (bersih.isEmpty || bersih == '_') ? 'TA' : bersih;
    return 'Kartu_Bimbingan_$inti.pdf';
  }

  // Membuat dokumen PDF lengkap dan mengembalikannya sebagai bytes.
  // TATA LETAK: kop judul berwarna, tabel identitas, ringkasan + pie chart,
  // tabel log, tabel revisi, foto bukti dalam kotak, catatan, dan kotak
  // pengesahan. Semua bagian memakai GARIS TEPI TEGAS supaya rapi dan jelas.
  Future<Uint8List> _buatPdf() async {
    final doc = pw.Document(title: 'Kartu Bimbingan Tugas Akhir', author: _nama);

    // --- Foto bukti perbaikan -> gambar PDF (hanya yang filenya masih ada) ---
    final fotos = <({String caption, pw.MemoryImage gambar})>[];
    if (!kIsWeb) {
      for (final r in _revisis) {
        final path = r.foto;
        if (path == null) continue;
        try {
          final f = File(path);
          if (!f.existsSync()) continue;
          fotos.add((
            caption: '${r.babPendek}: ${r.poin}',
            gambar: pw.MemoryImage(f.readAsBytesSync()),
          ));
        } catch (_) {
          // foto rusak/tidak terbaca dilewati supaya PDF tetap jadi
        }
      }
    }

    // --- Hitung data ringkasan ---
    final revSelesai = _revisis.where((r) => r.selesai).length;
    final revBelum = _revisis.length - revSelesai;
    final persenBab =
        _babTotal == 0 ? 0 : (_babAcc * 100 / _babTotal).round();

    // Peta id log -> tanggal, dan jumlah revisi per log
    final tglLog = {for (final l in _logs) l.id: l.tanggal};
    final totalPerLog = <String, int>{};
    final selesaiPerLog = <String, int>{};
    for (final r in _revisis) {
      final id = r.logId;
      if (id == null) continue;
      totalPerLog[id] = (totalPerLog[id] ?? 0) + 1;
      if (r.selesai) selesaiPerLog[id] = (selesaiPerLog[id] ?? 0) + 1;
    }

    // --- Warna, garis, dan gaya teks yang dipakai di seluruh dokumen ---
    const garis = PdfColors.grey800; // warna SEMUA garis tepi
    const isiHeader = PdfColors.indigo100; // latar header tabel
    const isiLabel = PdfColors.indigo50; // latar kolom label / judul kotak
    const lebarGaris = 0.8; // ketebalan garis tepi
    const kecil = pw.TextStyle(fontSize: 9);
    final tebal = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
    final borderTabel = pw.TableBorder.all(color: garis, width: lebarGaris);
    final borderKotak = pw.Border.all(color: garis, width: lebarGaris);

    // Satu sel tabel (label = latar berwarna + huruf tebal)
    pw.Widget sel(String teks, {bool label = false, pw.TextAlign? rata}) =>
        pw.Container(
          color: label ? isiLabel : null,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(teks, style: label ? tebal : kecil, textAlign: rata),
        );

    // Satu baris tabel identitas / ringkasan: [label | isi]
    pw.TableRow baris(String label, String isi) =>
        pw.TableRow(children: [sel(label, label: true), sel(isi)]);

    // Judul bagian berupa pita biru: "A. RINGKASAN PROGRES"
    pw.Widget bagian(String huruf, String judul) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: PdfColors.indigo700,
          child: pw.Text('$huruf. $judul',
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white)),
        );

    // Pie chart revisi selesai vs belum selesai
    pw.Widget pieChart() {
      final data = <pw.Dataset>[
        if (revSelesai > 0)
          pw.PieDataSet(
              value: revSelesai.toDouble(),
              legend: 'Selesai ($revSelesai)',
              color: PdfColors.green600,
              legendStyle: kecil),
        if (revBelum > 0)
          pw.PieDataSet(
              value: revBelum.toDouble(),
              legend: 'Belum ($revBelum)',
              color: PdfColors.red400,
              legendStyle: kecil),
      ];
      if (data.isEmpty) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 30),
          child: pw.Text('Belum ada revisi', style: kecil),
        );
      }
      return pw.SizedBox(
        width: 170,
        height: 100,
        child: pw.Chart(grid: pw.PieGrid(), datasets: data),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),

        // Header halaman 2 dst: judul kecil + nama, dengan garis bawah
        header: (c) => c.pageNumber == 1
            ? pw.SizedBox()
            : pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.only(bottom: 4),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(color: garis, width: lebarGaris)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Kartu Bimbingan Tugas Akhir', style: kecil),
                    pw.Text('$_nama - $_nim', style: kecil),
                  ],
                ),
              ),

        // Footer semua halaman: tanggal cetak + nomor halaman, dengan garis atas
        footer: (c) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 8),
          padding: const pw.EdgeInsets.only(top: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                top: pw.BorderSide(color: garis, width: lebarGaris)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Dicetak: ${_tgl(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              pw.Text('Halaman ${c.pageNumber} dari ${c.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            ],
          ),
        ),

        build: (c) => [
          // ===== Kop judul dokumen (kotak biru) =====
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.indigo700,
              border: borderKotak,
            ),
            child: pw.Column(
              children: [
                pw.Text('KARTU BIMBINGAN TUGAS AKHIR',
                    style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.SizedBox(height: 3),
                pw.Text('Rekap Log Bimbingan dan Revisi',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.white)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // ===== Tabel identitas =====
          pw.Table(
            border: borderTabel,
            columnWidths: {
              0: const pw.FixedColumnWidth(115),
              1: const pw.FlexColumnWidth(),
            },
            children: [
              baris('Nama', _nama),
              baris('NIM', _nim),
              baris('Judul Tugas Akhir', _judul),
              baris('Dosen Pembimbing', _dosen),
            ],
          ),

          // ===== A. Ringkasan progres + pie chart =====
          bagian('A', 'RINGKASAN PROGRES'),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Table(
                  border: borderTabel,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    baris('Progres total TA', '$persenBab%'),
                    baris('Bab selesai (ACC)', '$_babAcc dari $_babTotal bab'),
                    baris('Revisi selesai',
                        '$revSelesai dari ${_revisis.length}'),
                    baris('Jumlah log bimbingan', '${_logs.length}'),
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Container(
                width: 190,
                decoration: pw.BoxDecoration(border: borderKotak),
                child: pw.Column(
                  children: [
                    pw.Container(
                      width: double.infinity,
                      color: isiLabel,
                      padding: const pw.EdgeInsets.symmetric(vertical: 5),
                      child: pw.Text('Status Revisi',
                          style: tebal, textAlign: pw.TextAlign.center),
                    ),
                    pw.SizedBox(height: 6),
                    pieChart(),
                    pw.SizedBox(height: 6),
                  ],
                ),
              ),
            ],
          ),

          // ===== B. Tabel log bimbingan =====
          bagian('B', 'RIWAYAT LOG BIMBINGAN'),
          if (_logs.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: borderKotak),
              child: pw.Text('Belum ada log bimbingan.', style: kecil),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: ['No', 'Tanggal', 'Catatan Hasil Bimbingan', 'Revisi'],
              data: [
                for (var i = 0; i < _logs.length; i++)
                  [
                    '${i + 1}',
                    _tgl(_logs[i].tanggal),
                    _logs[i].catatan,
                    '${selesaiPerLog[_logs[i].id] ?? 0}/${totalPerLog[_logs[i].id] ?? 0}',
                  ],
              ],
              border: borderTabel,
              headerStyle: tebal,
              headerDecoration: const pw.BoxDecoration(color: isiHeader),
              headerAlignment: pw.Alignment.center,
              cellStyle: kecil,
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                3: pw.Alignment.center,
              },
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey100),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              columnWidths: {
                0: const pw.FixedColumnWidth(26),
                1: const pw.FixedColumnWidth(72),
                2: const pw.FlexColumnWidth(),
                3: const pw.FixedColumnWidth(46),
              },
            ),

          // ===== C. Tabel revisi per bab =====
          bagian('C', 'DAFTAR REVISI PER BAB'),
          if (_revisis.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: borderKotak),
              child: pw.Text('Belum ada revisi.', style: kecil),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: ['No', 'Bab', 'Poin Revisi', 'Bimbingan', 'Foto', 'Status'],
              data: [
                for (var i = 0; i < _revisis.length; i++)
                  [
                    '${i + 1}',
                    _revisis[i].babPendek,
                    _revisis[i].poin,
                    tglLog[_revisis[i].logId] == null
                        ? '-'
                        : _tgl(tglLog[_revisis[i].logId]!),
                    _revisis[i].foto != null ? 'Ada' : '-',
                    _revisis[i].selesai ? 'Selesai' : 'Belum',
                  ],
              ],
              border: borderTabel,
              headerStyle: tebal,
              headerDecoration: const pw.BoxDecoration(color: isiHeader),
              headerAlignment: pw.Alignment.center,
              cellStyle: kecil,
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
              },
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey100),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              columnWidths: {
                0: const pw.FixedColumnWidth(26),
                1: const pw.FixedColumnWidth(40),
                2: const pw.FlexColumnWidth(),
                3: const pw.FixedColumnWidth(66),
                4: const pw.FixedColumnWidth(34),
                5: const pw.FixedColumnWidth(48),
              },
            ),

          // ===== D. Foto bukti perbaikan (kotak berbingkai, 2 per baris) =====
          bagian('D', 'FOTO BUKTI PERBAIKAN'),
          if (fotos.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: borderKotak),
              child: pw.Text('Belum ada foto bukti yang dapat dilampirkan.',
                  style: kecil),
            )
          else
            pw.Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final f in fotos)
                  pw.Container(
                    width: 255,
                    decoration: pw.BoxDecoration(border: borderKotak),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Judul kotak: bab + poin revisi
                        pw.Container(
                          width: double.infinity,
                          color: isiLabel,
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(f.caption, style: tebal, maxLines: 2),
                        ),
                        pw.Container(
                          height: 1,
                          color: garis,
                        ),
                        // Area foto
                        pw.Container(
                          height: 150,
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(5),
                          alignment: pw.Alignment.center,
                          child: pw.Image(f.gambar, fit: pw.BoxFit.contain),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

          // ===== E. Catatan tambahan =====
          bagian('E', 'CATATAN TAMBAHAN'),
          pw.Container(
            width: double.infinity,
            constraints: const pw.BoxConstraints(minHeight: 40),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(border: borderKotak),
            child: pw.Text(
              _catatanController.text.trim().isEmpty
                  ? '-'
                  : _catatanController.text.trim(),
              style: kecil,
            ),
          ),

          // ===== F. Pengesahan (kolom dibiarkan kosong untuk tanda tangan basah) =====
          bagian('F', 'PENGESAHAN'),
          pw.Table(
            border: borderTabel,
            columnWidths: {
              0: const pw.FlexColumnWidth(),
              1: const pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(children: [
                sel('Dosen Pembimbing',
                    label: true, rata: pw.TextAlign.center),
                sel('Mahasiswa', label: true, rata: pw.TextAlign.center),
              ]),
              pw.TableRow(children: [
                pw.Container(height: 75),
                pw.Container(height: 75),
              ]),
              pw.TableRow(children: [
                sel('( $_dosen )', rata: pw.TextAlign.center),
                sel('( $_nama )', rata: pw.TextAlign.center),
              ]),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ====================== AKSI TOMBOL ======================

  void _pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  // Tombol "Ekspor ke PDF": cek data -> buat PDF -> tampilkan layar berhasil
  Future<void> _ekspor() async {
    // Sesuai flowchart: jika tidak ada data bimbingan, ekspor tidak dilanjutkan
    if (_logs.isEmpty && _revisis.isEmpty) {
      _pesan('Belum ada data bimbingan atau revisi untuk diekspor.');
      return;
    }
    setState(() => _mengekspor = true);
    try {
      final bytes = await _buatPdf();
      if (!mounted) return;
      setState(() {
        _pdfBytes = bytes;
        _namaFile = _buatNamaFile();
        _mengekspor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _mengekspor = false);
      _pesan('Gagal membuat PDF: $e');
    }
  }

  // Tombol "Buka PDF": pratinjau + cetak
  Future<void> _bukaPdf() async {
    final bytes = _pdfBytes;
    if (bytes == null) return;
    try {
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: _namaFile ?? 'Kartu_Bimbingan_TA.pdf',
      );
    } catch (e) {
      _pesan('Gagal membuka PDF: $e');
    }
  }

  // Tombol "Bagikan / Simpan": buka menu bagikan HP (simpan ke Drive, kirim WA, dll)
  Future<void> _bagikanPdf() async {
    final bytes = _pdfBytes;
    if (bytes == null) return;
    try {
      await Printing.sharePdf(
        bytes: bytes,
        filename: _namaFile ?? 'Kartu_Bimbingan_TA.pdf',
      );
    } catch (e) {
      _pesan('Gagal membagikan PDF: $e');
    }
  }

  // ====================== TAMPILAN ======================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar: bilah navigasi bagian atas layar
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ekspor PDF',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Container(
        // Latar gradien warna
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4338CA),
              Color(0xFF5B52E0),
              Color(0xFFB8B4F5),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                if (_memuat)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        Text('Gagal memuat data:\n$_error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _memuat = true;
                              _error = null;
                            });
                            _muat();
                          },
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white)),
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  )
                else if (_pdfBytes != null)
                  // Setelah ekspor berhasil: tampilkan kartu hasil
                  _buildBerhasilCard()
                else ...[
                  // 1. Kartu ringkasan statistik (Log, Revisi, Foto Bukti)
                  _buildStatistikCard(),
                  const SizedBox(height: 14),

                  // 2. Kartu catatan tambahan
                  _buildCatatanCard(),
                  const SizedBox(height: 14),

                  // 3. Kartu pratinjau kartu bimbingan
                  _buildPratinjauKartuCard(),
                  const SizedBox(height: 16),

                  // 4. Tombol utama: Ekspor ke PDF
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _mengekspor ? null : _ekspor,
                      icon: _mengekspor
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.picture_as_pdf_outlined,
                              color: Colors.white),
                      label: Text(
                        _mengekspor ? 'Membuat PDF...' : 'Ekspor ke PDF',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _primary.withAlpha(150),
                        disabledForegroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                // 5. Tombol sekunder: Batal / Kembali
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(200),
                      foregroundColor: _primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _pdfBytes != null ? 'Kembali ke Beranda' : 'Batal',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),

      // CATATAN: di sini dulu ada `bottomNavigationBar` (ikon Beranda, Bab,
      // Bimbingan, Revisi) yang sudah DIHAPUS. Alasannya: halaman Ekspor PDF
      // dibuka lewat Navigator.push di atas halaman utama, jadi bar itu
      // hanya tiruan tampilan dan tidak bisa ditekan (menyesatkan pengguna).
      // Untuk kembali, pengguna cukup memakai panah di AppBar atau tombol
      // "Batal" / "Kembali ke Beranda" di bagian bawah isi halaman.
    );
  }

  // --- SUB-WIDGET HELPER ---

  /// BARU: Kartu hasil setelah PDF berhasil dibuat (nama file, ukuran, tombol aksi)
  Widget _buildBerhasilCard() {
    final kb = ((_pdfBytes?.length ?? 0) / 1024).toStringAsFixed(0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
                color: Color(0xFFE3F6EA), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle,
                size: 40, color: Color(0xFF1E9E55)),
          ),
          const SizedBox(height: 12),
          const Text('Ekspor Berhasil',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_outlined, color: _primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_namaFile ?? 'Kartu_Bimbingan_TA.pdf',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      Text('Dokumen PDF - $kb KB',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _bukaPdf,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Buka PDF',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _bagikanPdf,
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Bagikan / Simpan',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => setState(() {
              _pdfBytes = null;
              _namaFile = null;
            }),
            child: const Text('Ekspor ulang'),
          ),
        ],
      ),
    );
  }

  /// Kartu ringkasan statistik: jumlah Log, Revisi, dan Foto Bukti (data asli)
  Widget _buildStatistikCard() {
    final jumlahFoto = _revisis.where((r) => r.foto != null).length;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              Icons.reorder_rounded, '${_logs.length}', 'Log Bimbingan'),
          Container(height: 35, width: 1, color: Colors.grey.shade300),
          _buildStatItem(
              Icons.assignment_outlined, '${_revisis.length}', 'Revisi'),
          Container(height: 35, width: 1, color: Colors.grey.shade300),
          _buildStatItem(Icons.image_outlined, '$jumlahFoto', 'Foto Bukti'),
        ],
      ),
    );
  }

  // Sub-item statistik (ikon, angka, label)
  Widget _buildStatItem(IconData icon, String count, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primary, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          count,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  /// Form catatan tambahan
  Widget _buildCatatanCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CATATAN TAMBAHAN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Kolom catatan tambahan (opsional)
          TextField(
            controller: _catatanController,
            decoration: InputDecoration(
              hintText: 'Catatan tambahan (opsional)',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pratinjau miniatur kartu bimbingan (memakai data asli, 3 log terbaru)
  Widget _buildPratinjauKartuCard() {
    final terbaru =
        _logs.length > 3 ? _logs.sublist(_logs.length - 3) : _logs;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRATINJAU KARTU BIMBINGAN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Miniatur kertas dokumen
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'KARTU BIMBINGAN TUGAS AKHIR',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Nama: $_nama   NIM: $_nim',
                    style:
                        const TextStyle(fontSize: 10, color: Colors.black87)),
                const SizedBox(height: 2),
                Text('Judul: $_judul',
                    style:
                        const TextStyle(fontSize: 9, color: Colors.black54)),
                const SizedBox(height: 2),
                Text('Dosen: $_dosen',
                    style:
                        const TextStyle(fontSize: 9, color: Colors.black54)),
                const SizedBox(height: 8),

                // Header tabel log
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  child: const Row(
                    children: [
                      SizedBox(
                          width: 70,
                          child: Text('Tanggal',
                              style: TextStyle(
                                  fontSize: 9, fontWeight: FontWeight.bold))),
                      Expanded(
                          child: Text('Catatan',
                              style: TextStyle(
                                  fontSize: 9, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                if (terbaru.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    child: Text('Belum ada log bimbingan.',
                        style: TextStyle(fontSize: 8.5, color: Colors.grey)),
                  )
                else
                  ...terbaru.map((l) => _buildTableRow(_tgl(l.tanggal), l.catatan)),
                const SizedBox(height: 12),

                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pratinjau (data lengkap ada di PDF)',
                        style: TextStyle(fontSize: 8, color: Colors.grey)),
                    Text('Format Resmi LogTA',
                        style: TextStyle(fontSize: 8, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Satu baris data tabel pratinjau
  Widget _buildTableRow(String tanggal, String catatan) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(tanggal,
                style: const TextStyle(fontSize: 8.5, color: Colors.black87)),
          ),
          Expanded(
            child: Text(catatan,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 8.5, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}