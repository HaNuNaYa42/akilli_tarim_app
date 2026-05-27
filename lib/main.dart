import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AkilliTarimApp());
}

class AkilliTarimApp extends StatelessWidget {
  const AkilliTarimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akıllı Tarım',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D9E75),
          primary: const Color(0xFF1D9E75),
        ),
        useMaterial3: true,
      ),
      home: const AnaEkran(),
    );
  }
}

// =================================================================
// ANA EKRAN
// =================================================================
class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  File? _secilenFoto;
  final TextEditingController _belirtiController = TextEditingController();
  bool _yukleniyor = false;
  final ImagePicker _picker = ImagePicker();

  // ----------------------------------------------------------------
  // Backend hazır olunca MOCK_MOD = false yapın ve API_URL'yi girin
  // ----------------------------------------------------------------
  static const bool MOCK_MOD = true;
  static const String API_URL =
      'https://KULLANICI-ADINIZ-akilli-tarim.hf.space/predict';

  // Mock yanıt — UI testi için
  Map<String, dynamic> _mockYanit() {
    final belirti = _belirtiController.text.toLowerCase();
    if (belirti.contains('pas') || belirti.contains('rust')) {
      return {
        'label': 'Corn_(maize)___Common_rust_',
        'confidence': 0.91,
        'recete':
            'Dayanıklı çeşitler seçilmeli ve aşırı azottan kaçınılmalıdır. Uygun bir fungisit ile ilaçlama yapılmalıdır.',
      };
    }
    return {
      'label': 'Tomato___Early_blight',
      'confidence': 0.94,
      'recete':
          'Alt yaprakları budayarak hava akımını artırın. Yağmurlama sulamadan kaçının. Tescilli fungisitlerle ilaçlama yapın.',
    };
  }

  Future<void> _fotoSec(ImageSource kaynak) async {
    final XFile? foto = await _picker.pickImage(
      source: kaynak,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (foto != null) setState(() => _secilenFoto = File(foto.path));
  }

  void _kaynakSecDialogu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: Color(0xFF1D9E75)),
                title: const Text('Kamera ile çek'),
                onTap: () {
                  Navigator.pop(ctx);
                  _fotoSec(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF1D9E75)),
                title: const Text('Galeriden seç'),
                onTap: () {
                  Navigator.pop(ctx);
                  _fotoSec(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _teshisEt() async {
    if (_secilenFoto == null && _belirtiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen fotoğraf veya belirti açıklaması girin.'),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );
      return;
    }

    setState(() => _yukleniyor = true);

    try {
      Map<String, dynamic> sonuc;

      if (MOCK_MOD) {
        // Mock mod — gerçek API olmadan test
        await Future.delayed(const Duration(seconds: 2));
        sonuc = _mockYanit();
      } else {
        // Gerçek API çağrısı
        final request = http.MultipartRequest('POST', Uri.parse(API_URL));
        if (_secilenFoto != null) {
          request.files.add(await http.MultipartFile.fromPath(
              'image', _secilenFoto!.path));
        }
        if (_belirtiController.text.trim().isNotEmpty) {
          request.fields['text'] = _belirtiController.text.trim();
        }
        final response =
            await request.send().timeout(const Duration(seconds: 60));
        final body = await response.stream.bytesToString();
        sonuc = jsonDecode(body);
      }

      if (!mounted) return;
      setState(() => _yukleniyor = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SonucEkrani(
            foto: _secilenFoto,
            teshis: sonuc['label'] ?? 'Bilinmiyor',
            guven: (sonuc['confidence'] ?? 0.0).toDouble(),
            recete: sonuc['recete'] ?? 'Reçete alınamadı.',
          ),
        ),
      );
    } catch (e) {
      setState(() => _yukleniyor = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Akıllı Tarım',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            Text('Bitki hastalığı teşhis asistanı',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          if (MOCK_MOD)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('TEST MODU',
                  style: TextStyle(fontSize: 10, color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FOTOĞRAF ALANI
            GestureDetector(
              onTap: _kaynakSecDialogu,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 200,
                decoration: BoxDecoration(
                  color: _secilenFoto != null
                      ? Colors.transparent
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: _secilenFoto != null
                      ? null
                      : Border.all(
                          color:
                              const Color(0xFF1D9E75).withOpacity(0.4),
                          width: 1.5,
                        ),
                ),
                child: _secilenFoto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_secilenFoto!, fit: BoxFit.cover),
                            Positioned(
                              bottom: 10, right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit,
                                        color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text('Değiştir',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              size: 40,
                              color: const Color(0xFF1D9E75)
                                  .withOpacity(0.6)),
                          const SizedBox(height: 10),
                          const Text('Bitkinin fotoğrafını ekle',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF5F5E5A))),
                          const SizedBox(height: 4),
                          Text('Dokunarak kamera veya galeriyi aç',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400])),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 10),

            // KAMERA / GALERİ BUTONLARI
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _fotoSec(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: const Text('Kamera',
                        style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1D9E75),
                      side: const BorderSide(
                          color: Color(0xFF1D9E75), width: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _fotoSec(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined,
                        size: 16),
                    label: const Text('Galeri',
                        style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1D9E75),
                      side: const BorderSide(
                          color: Color(0xFF1D9E75), width: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // BELİRTİ METİN KUTUSU
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.grey.withOpacity(0.2), width: 0.5),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Belirti açıklaması',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF888780))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _belirtiController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText:
                          'Yaprak rengini, leke biçimini veya diğer belirtileri yazın...',
                      hintStyle: TextStyle(
                          fontSize: 12, color: Color(0xFFB4B2A9)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // TEŞHİS BUTONU
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _yukleniyor ? null : _teshisEt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  disabledBackgroundColor: const Color(0xFF0F6E56),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _yukleniyor
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70),
                          ),
                          SizedBox(width: 10),
                          Text('Analiz ediliyor...',
                              style: TextStyle(fontSize: 14)),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 18),
                          SizedBox(width: 8),
                          Text('Teşhis et',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _belirtiController.dispose();
    super.dispose();
  }
}

// =================================================================
// SONUÇ EKRANI
// =================================================================
class SonucEkrani extends StatelessWidget {
  final File? foto;
  final String teshis;
  final double guven;
  final String recete;

  const SonucEkrani({
    super.key,
    required this.foto,
    required this.teshis,
    required this.guven,
    required this.recete,
  });

  static const Map<String, String> _ceviriler = {
    'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot':
        'Mısır Gri Yaprak Lekesi',
    'Corn_(maize)___Common_rust_': 'Mısır Adi Pas Hastalığı',
    'Corn_(maize)___Northern_Leaf_Blight': 'Mısır Kuzey Yaprak Yanıklığı',
    'Corn_(maize)___healthy': 'Sağlıklı Mısır',
    'Pepper,_bell___Bacterial_spot': 'Biber Bakteriyel Leke',
    'Pepper,_bell___healthy': 'Sağlıklı Biber',
    'Potato___Early_blight': 'Patates Erken Yanıklığı',
    'Potato___Late_blight': 'Patates Geç Yanıklığı',
    'Potato___healthy': 'Sağlıklı Patates',
    'Tomato___Bacterial_spot': 'Domates Bakteriyel Leke',
    'Tomato___Early_blight': 'Domates Erken Yanıklığı',
    'Tomato___Late_blight': 'Domates Geç Yanıklığı',
    'Tomato___Leaf_Mold': 'Domates Yaprak Küfü',
    'Tomato___Septoria_leaf_spot': 'Domates Septoria Lekesi',
    'Tomato___Spider_mites Two-spotted_spider_mite':
        'İki Noktalı Kırmızı Örümcek',
    'Tomato___Target_Spot': 'Domates Hedef Lekesi',
    'Tomato___Tomato_Yellow_Leaf_Curl_Virus':
        'Sarı Yaprak Kıvırcıklık Virüsü',
    'Tomato___Tomato_mosaic_virus': 'Domates Mozaik Virüsü',
    'Tomato___healthy': 'Sağlıklı Domates',
  };

  bool get _saglikli => teshis.contains('healthy');

  @override
  Widget build(BuildContext context) {
    final turkce = _ceviriler[teshis] ?? teshis.replaceAll('_', ' ');
    final guvenYuzde = (guven * 100).toStringAsFixed(0);
    final receteListesi = recete
        .split('.')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Teşhis sonucu',
            style:
                TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FOTOĞRAF
            SizedBox(
              height: 220,
              child: foto != null
                  ? Image.file(foto!, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFF0F6E56),
                      child: const Center(
                        child: Icon(Icons.eco_outlined,
                            size: 60, color: Colors.white38),
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // TEŞHİS KARTI
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.grey.withOpacity(0.15),
                          width: 0.5),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _saglikli
                                    ? const Color(0xFFE1F5EE)
                                    : const Color(0xFFFAEEDA),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _saglikli
                                    ? 'Sağlıklı'
                                    : 'Hastalık tespit edildi',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _saglikli
                                      ? const Color(0xFF0F6E56)
                                      : const Color(0xFF633806),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F1FB),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '%$guvenYuzde güven',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF185FA5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(turkce,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C2C2A))),
                        const SizedBox(height: 2),
                        Text(teshis.replaceAll('_', ' '),
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF888780))),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Text('Model güveni',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF888780))),
                            const Spacer(),
                            Text('%$guvenYuzde',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF888780))),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: guven,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFD3D1C7),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _saglikli
                                  ? const Color(0xFF1D9E75)
                                  : const Color(0xFFBA7517),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // REÇETE KARTI
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.grey.withOpacity(0.15),
                          width: 0.5),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.assignment_outlined,
                                size: 16, color: Color(0xFF1D9E75)),
                            SizedBox(width: 6),
                            Text('Tedavi reçetesi',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C2C2A))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...receteListesi.map((madde) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 6, height: 6,
                                    margin: const EdgeInsets.only(
                                        top: 5, right: 8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1D9E75),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(madde.trim(),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF444441),
                                            height: 1.5)),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // YENİ TEŞHİS
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Yeni teşhis'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5F5E5A),
                      side: const BorderSide(
                          color: Color(0xFFD3D1C7), width: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
