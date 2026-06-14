import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  List<FileSystemEntity> savedImages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVaultImages();
  }

  // Refreshes the vault when you navigate back to this tab
  Future<void> _loadVaultImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final vaultDir = Directory('${directory.path}/SecureVault');
      
      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
      }

      // Fetch all PNG files in the vault folder
      final files = vaultDir.listSync()
          .where((item) => item.path.endsWith('.png'))
          .toList();
      
      // Sort files by newest modified date
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      setState(() {
        savedImages = files;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Vault Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Vault', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              _loadVaultImages();
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : savedImages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text("Your vault is empty.", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: savedImages.length,
                  itemBuilder: (context, index) {
                    final file = File(savedImages[index].path);
                    final fileName = file.path.split(Platform.pathSeparator).last;

                    return Card(
                      elevation: 3,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Display the actual saved image file
                          Image.file(file, fit: BoxFit.cover),
                          
                          // Label overlay at the bottom
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              color: Colors.black87, 
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    fileName, 
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  const Row(
                                    children: [
                                      Icon(Icons.verified_user, color: Colors.greenAccent, size: 12),
                                      SizedBox(width: 4),
                                      Text('Protected Asset', style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}