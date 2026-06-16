import 'dart:io';
import 'dart:convert'; // Untuk parsing JSON dari graf
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart'; 
import 'package:gal/gal.dart'; 
import '../widgets/ai_chat_sheet.dart';
import '../widgets/audit_graph_sheet.dart'; // Import graf baharu

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Pembolehubah Embed
  Uint8List? hostImageBytes;
  String? hostFileName;
  Uint8List? watermarkBytes;
  String? watermarkFileName;
  Uint8List? resultImageBytes;
  bool isEmbedding = false;

  // Pembolehubah Attack/Extract
  Uint8List? testImageBytes;
  String? testFileName;
  Uint8List? extractedWatermarkBytes;
  bool isExtracting = false;
  bool isAttacking = false;
  bool isStressTesting = false; // State baharu untuk butang graf
  
  // Metrik Analisis
  String? attackMse;
  String? attackPsnr;
  String? attackSsim; // Metrik SSIM baharu
  String? currentAttackName; 

  final String apiUrl = "https://dct-watermarking-project.onrender.com";

  Future<void> pickImage({required String target}) async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.image, withData: true);
    if (result != null) {
      setState(() {
        if (target == 'host') {
          hostImageBytes = result.files.first.bytes;
          hostFileName = result.files.first.name;
        } else if (target == 'logo') {
          watermarkBytes = result.files.first.bytes;
          watermarkFileName = result.files.first.name;
        } else if (target == 'test') { 
          testImageBytes = result.files.first.bytes;
          testFileName = result.files.first.name;
          extractedWatermarkBytes = null;
          attackMse = null;
          attackPsnr = null;
          attackSsim = null; 
          currentAttackName = null; 
        }
      });
    }
  }

  Future<void> downloadImage() async {
    if (resultImageBytes == null) return;
    try {
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = 'Protected_Asset_$timestamp';

      if (Platform.isAndroid || Platform.isIOS) {
        bool hasAccess = await Gal.hasAccess();
        if (!hasAccess) await Gal.requestAccess();
        await Gal.putImageBytes(resultImageBytes!, name: fileName);
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: resultImageBytes,
          fileExtension: 'png',
          mimeType: MimeType.png,
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final vaultDir = Directory('${directory.path}/SecureVault');
      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
      }
      final file = File('${vaultDir.path}/$fileName.png');
      await file.writeAsBytes(resultImageBytes!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Success! Image saved to Gallery AND Secure Vault.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> embedWatermark() async {
    if (hostImageBytes == null || watermarkBytes == null) return;
    setState(() => isEmbedding = true);

    final prefs = await SharedPreferences.getInstance();
    String alpha = (prefs.getDouble('alphaStrength') ?? 0.5).toString();
    String tiling = (prefs.getInt('tilingFactor') ?? 4).toString();

    var request = http.MultipartRequest('POST', Uri.parse('$apiUrl/embed'));
    
    request.files.add(http.MultipartFile.fromBytes('host_image', hostImageBytes!, filename: hostFileName));
    request.files.add(http.MultipartFile.fromBytes('watermark', watermarkBytes!, filename: watermarkFileName));
    request.fields['alpha'] = alpha;
    request.fields['tiling_factor'] = tiling;

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        setState(() => resultImageBytes = responseData);
      }
    } finally {
      setState(() => isEmbedding = false);
    }
  }

  Future<void> triggerAttack(String attackType) async {
    if (testImageBytes == null) return;
    setState(() => isAttacking = true);
    var request = http.MultipartRequest('POST', Uri.parse('$apiUrl/attack/$attackType'));
    request.files.add(http.MultipartFile.fromBytes('file', testImageBytes!, filename: testFileName ?? 'attack_target.png'));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        String formattedName = {'jpeg': "JPEG Compression", 'noise': "Gaussian Noise", 'crop': "Cropping", 'scale': "Scaling"}[attackType] ?? "Attack";
        setState(() {
          testImageBytes = responseData; 
          extractedWatermarkBytes = null; 
          attackMse = response.headers['x-mse'];
          attackPsnr = response.headers['x-psnr'];
          attackSsim = response.headers['x-ssim']; // <-- Membaca nilai SSIM dari Server
          currentAttackName = formattedName; 
        });
      }
    } finally {
      setState(() => isAttacking = false);
    }
  }

  // FUNGSI BAHARU: STRESS TEST GRAF
  Future<void> runStressTest() async {
    if (testImageBytes == null) return;
    setState(() => isStressTesting = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$apiUrl/stresstest'));
      request.files.add(http.MultipartFile.fromBytes('file', testImageBytes!, filename: testFileName ?? 'stress_target.png'));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = json.decode(responseData);
        
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AuditGraphSheet(testData: jsonData['data']),
          );
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Server Error: Failed to run audit.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => isStressTesting = false);
    }
  }

  Future<void> extractWatermark() async {
    if (testImageBytes == null) return;
    setState(() => isExtracting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String tiling = (prefs.getInt('tilingFactor') ?? 4).toString();
      String heavyVoting = (prefs.getBool('heavyVoting') ?? true).toString();

      var request = http.MultipartRequest('POST', Uri.parse('$apiUrl/extract'));
      String safeFileName = testFileName ?? 'attacked_target.png';
      request.files.add(http.MultipartFile.fromBytes('watermarked_image', testImageBytes!, filename: safeFileName));
      
      request.fields['tiling_factor'] = tiling;
      request.fields['heavy_voting'] = heavyVoting;

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        setState(() => extractedWatermarkBytes = responseData);
      } else {
        var errorData = await response.stream.bytesToString();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server Error: $errorData'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network Error.'), backgroundColor: Colors.red));
    } finally {
      setState(() => isExtracting = false);
    }
  }

  void _showScoresAiInsights() {
    if (attackPsnr == null || attackSsim == null) return;
    String prompt = 'Act as a multimedia security expert. I ran a robustness test on a DCT watermarked image. The Peak Signal-to-Noise Ratio (PSNR) is $attackPsnr dB and the Structural Similarity Index (SSIM) is $attackSsim. Give a brief, 2-3 sentence analysis of what these scores mean for the image structural quality.';
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => AiChatSheet(initialPrompt: prompt, titleName: "Gemini Analyst", themeColor: Colors.indigo));
  }

  void _showExtractionAiInsights() {
    String attackContext = currentAttackName != null ? "a $currentAttackName attack" : "an attack";
    String prompt = 'Briefly explain how the DCT redundant tiling and majority voting algorithm manages to recover the watermark even after $attackContext.';
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => AiChatSheet(initialPrompt: prompt, titleName: "Extraction Analyst", themeColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ==============================
          // 1. EMBED CARD
          // ==============================
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("1. Embed Security Payload", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(icon: const Icon(Icons.image), label: const Text("Host"), onPressed: () => pickImage(target: 'host')),
                      ElevatedButton.icon(icon: const Icon(Icons.security), label: const Text("Logo"), onPressed: () => pickImage(target: 'logo')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (hostImageBytes != null || watermarkBytes != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hostImageBytes != null)
                          Expanded(child: Column(children: [const Text("Host", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), Image.memory(hostImageBytes!, height: 100)])),
                        if (watermarkBytes != null)
                          Expanded(child: Column(children: [const Text("Logo", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), Image.memory(watermarkBytes!, height: 100)])),
                      ],
                    ),
                  const SizedBox(height: 16),

                  if (hostImageBytes != null && watermarkBytes != null)
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      onPressed: isEmbedding ? null : embedWatermark,
                      child: isEmbedding ? const CircularProgressIndicator(color: Colors.white) : const Text("Run DCT Embedding"),
                    ),
                  if (resultImageBytes != null) ...[
                    const SizedBox(height: 16),
                    Image.memory(resultImageBytes!, height: 150),
                    TextButton.icon(icon: const Icon(Icons.download), label: const Text("Save Protected Asset"), onPressed: downloadImage),
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // ==============================
          // 2. ATTACK & AUDIT CARD
          // ==============================
          Card(
            elevation: 2,
            color: Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("2. Robustness Testing & Audit", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    icon: const Icon(Icons.upload_file, color: Colors.red),
                    label: const Text("Upload Test Target", style: TextStyle(color: Colors.red)),
                    onPressed: () => pickImage(target: 'test'),
                  ),
                  const SizedBox(height: 16),
                  if (testImageBytes != null) ...[
                    isAttacking 
                      ? const CircularProgressIndicator()
                      : Wrap(
                          spacing: 8, alignment: WrapAlignment.center,
                          children: [
                            ActionChip(label: const Text("JPEG"), onPressed: () => triggerAttack('jpeg')),
                            ActionChip(label: const Text("Noise"), onPressed: () => triggerAttack('noise')),
                            ActionChip(label: const Text("Crop"), onPressed: () => triggerAttack('crop')),
                            ActionChip(label: const Text("Scale"), onPressed: () => triggerAttack('scale')),
                          ],
                        ),
                    const SizedBox(height: 16),
                    
                    // UI BAHARU: SSIM & BUTANG GRAF
                    if (attackMse != null && attackPsnr != null)
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Chip(label: Text("PSNR: $attackPsnr dB"), backgroundColor: Colors.white),
                              const SizedBox(width: 8),
                              Chip(label: Text("SSIM: $attackSsim"), backgroundColor: Colors.white),
                              IconButton(icon: const Icon(Icons.auto_awesome, color: Colors.indigo), onPressed: _showScoresAiInsights),
                            ],
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.indigo, side: const BorderSide(color: Colors.indigo)),
                            icon: isStressTesting 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.analytics),
                            label: Text(isStressTesting ? "Generating Audit..." : "Generate Deep Security Audit Graph"),
                            onPressed: isStressTesting ? null : runStressTest,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    
                    Image.memory(testImageBytes!, height: 150),
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ==============================
          // 3. EXTRACT CARD
          // ==============================
          Card(
            elevation: 2,
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("3. Extract Watermark", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
                    icon: isExtracting ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.search),
                    label: const Text("Run DCT Extraction"),
                    onPressed: isExtracting || testImageBytes == null ? null : extractWatermark,
                  ),
                  if (extractedWatermarkBytes != null) ...[
                    const SizedBox(height: 16),
                    Image.memory(extractedWatermarkBytes!, height: 120),
                    TextButton.icon(icon: const Icon(Icons.auto_awesome, color: Colors.green), label: const Text("Explain Extraction", style: TextStyle(color: Colors.green)), onPressed: _showExtractionAiInsights),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}