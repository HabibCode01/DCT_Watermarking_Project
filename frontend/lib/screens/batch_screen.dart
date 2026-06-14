import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this to the top
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:file_saver/file_saver.dart';
import 'package:gal/gal.dart';

class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  List<PlatformFile> hostFiles = [];
  PlatformFile? watermarkFile;
  
  bool isProcessing = false;
  int completedCount = 0;
  
  // Tracks the status of each file: 'pending', 'processing', 'success', 'error'
  Map<String, String> fileStatuses = {};

  final String apiUrl = "";

  Future<void> pickHostImages() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: true, // Allows selecting multiple files!
      withData: true,
    );

    if (result != null) {
      setState(() {
        hostFiles = result.files;
        completedCount = 0;
        fileStatuses.clear();
        for (var file in hostFiles) {
          fileStatuses[file.name] = 'pending';
        }
      });
    }
  }

  Future<void> pickWatermarkLogo() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      setState(() {
        watermarkFile = result.files.first;
      });
    }
  }

  Future<void> startBatchProcess() async {
    if (hostFiles.isEmpty || watermarkFile == null) return;

    setState(() {
      isProcessing = true;
      completedCount = 0;
    });

    // Loop through every selected image asynchronously
    for (int i = 0; i < hostFiles.length; i++) {
      var currentFile = hostFiles[i];
      
      setState(() {
        fileStatuses[currentFile.name] = 'processing';
      });

      bool success = await _processAndSaveSingleFile(currentFile);

      setState(() {
        fileStatuses[currentFile.name] = success ? 'success' : 'error';
        completedCount++;
      });
    }

    setState(() {
      isProcessing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batch Processing Complete!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _processAndSaveSingleFile(PlatformFile hostFile) async {
    try {
      // 1. Read the user's custom Pro Settings
      final prefs = await SharedPreferences.getInstance();
      String alpha = (prefs.getDouble('alphaStrength') ?? 0.5).toString();
      String tiling = (prefs.getInt('tilingFactor') ?? 4).toString();

      // 2. Build the API Request
      var request = http.MultipartRequest('POST', Uri.parse('$apiUrl/embed'));
      
      request.files.add(http.MultipartFile.fromBytes('host_image', hostFile.bytes!, filename: hostFile.name));
      request.files.add(http.MultipartFile.fromBytes('watermark', watermarkFile!.bytes!, filename: watermarkFile!.name));

      // 3. ATTACH THE PRO SETTINGS!
      request.fields['alpha'] = alpha;
      request.fields['tiling_factor'] = tiling;

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        String newFileName = 'protected_${hostFile.name.split('.').first}_${DateTime.now().millisecondsSinceEpoch}';

        // Save to Public Device Storage
        if (Platform.isAndroid || Platform.isIOS) {
          bool hasAccess = await Gal.hasAccess();
          if (!hasAccess) await Gal.requestAccess();
          await Gal.putImageBytes(responseData, name: newFileName);
        } else {
          await FileSaver.instance.saveFile(
            name: newFileName,
            bytes: responseData,
            fileExtension: 'png',
            mimeType: MimeType.png,
          );
        }

        // Save a copy to the Secure Vault
        final directory = await getApplicationDocumentsDirectory();
        final vaultDir = Directory('${directory.path}/SecureVault');
        if (!await vaultDir.exists()) {
          await vaultDir.create(recursive: true);
        }
        final file = File('${vaultDir.path}/$newFileName.png');
        await file.writeAsBytes(responseData);

        return true; // Success
      } else {
        debugPrint("API Error: ${response.statusCode}");
        return false; // API Error
      }
    } catch (e) {
      debugPrint("Batch Error on ${hostFile.name}: $e");
      return false; // Network/Save Error
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate overall progress
    double progress = hostFiles.isEmpty ? 0 : completedCount / hostFiles.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Processing Engine', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ================= CONFIGURATION CARD =================
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.folder_open, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text("1. Select Media", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      ],
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(hostFiles.isEmpty ? "No host images selected" : "${hostFiles.length} images selected for batching"),
                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text("Add Images"),
                        onPressed: isProcessing ? null : pickHostImages,
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(watermarkFile == null ? "No watermark logo selected" : watermarkFile!.name),
                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.security),
                        label: const Text("Set Logo"),
                        onPressed: isProcessing ? null : pickWatermarkLogo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ================= PROGRESS & CONTROLS =================
            Card(
              elevation: 2,
              color: Colors.indigo[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: (hostFiles.isNotEmpty && watermarkFile != null) ? Colors.indigo : Colors.grey,
                      ),
                      icon: isProcessing 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.play_arrow),
                      label: Text(isProcessing ? "Processing Batch ($completedCount/${hostFiles.length})..." : "Start Batch Watermarking"),
                      onPressed: (hostFiles.isNotEmpty && watermarkFile != null && !isProcessing) ? startBatchProcess : null,
                    ),
                    if (hostFiles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        color: Colors.indigo,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${(progress * 100).toStringAsFixed(0)}% Complete",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ================= QUEUE LIST VIEW =================
            const Text("Processing Queue", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Divider(),
            Expanded(
              child: hostFiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.queue_play_next, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text("Queue is empty.", style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: hostFiles.length,
                      itemBuilder: (context, index) {
                        String fileName = hostFiles[index].name;
                        String status = fileStatuses[fileName] ?? 'pending';

                        // Determine the trailing icon based on status
                        Widget statusIcon;
                        if (status == 'pending') {
                          statusIcon = const Icon(Icons.schedule, color: Colors.grey);
                        } else if (status == 'processing') {
                          statusIcon = const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
                        } else if (status == 'success') {
                          statusIcon = const Icon(Icons.check_circle, color: Colors.green);
                        } else {
                          statusIcon = const Icon(Icons.error, color: Colors.red);
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo[100],
                              child: const Icon(Icons.image, color: Colors.indigo),
                            ),
                            title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(status.toUpperCase(), style: TextStyle(fontSize: 12, color: status == 'error' ? Colors.red : Colors.grey[600])),
                            trailing: statusIcon,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}