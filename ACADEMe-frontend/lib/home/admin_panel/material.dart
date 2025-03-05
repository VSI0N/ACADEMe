import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class MaterialManager {
  final BuildContext context;
  final Function onMaterialAdded;
  final List<Map<String, String>> materials;

  MaterialManager({required this.context, required this.onMaterialAdded, required this.materials});

  void addMaterial() {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedType;
        String? category;
        String? filePath;
        final TextEditingController categoryController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Add Material"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: "Type"),
                    items: ["Notes", "Video", "Image", "Audio"]
                        .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                        .toList(),
                    onChanged: (value) {
                      selectedType = value ?? "";
                    },
                  ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: "Category"),
                    items: ["Notes", "Reference Links", "Image", "Audio"]
                        .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                        .toList(),
                    onChanged: (value) {
                      category = value ?? "";
                    },
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles();
                      if (result != null && result.files.single.path != null) {
                        setDialogState(() {
                          filePath = result.files.single.path!;
                        });
                        print("✅ File picked: $filePath"); // Debugging log
                      }
                    },
                    icon: Icon(Icons.attach_file),
                    label: Text("Attach File"),
                  ),
                  if (filePath != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text("Selected: ${filePath!.split('/').last}"),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedType != null && category != null && filePath != null) {
                      materials.add({
                        "type": selectedType ?? "",
                        "category": category ?? "",
                        "file": filePath!,
                      });
                      print("📂 Material added with file path: $filePath"); // Debug log
                      onMaterialAdded(); // Notify UI to refresh
                      Navigator.pop(context);
                    }
                  },
                  child: Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildMaterialList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final material = materials[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            title: Text(material["type"] ?? "Unknown"),
            subtitle: Text(material["category"] ?? "No category"),
            trailing: Icon(Icons.open_in_new),
            onTap: () {
              if (material["file"] != null && material["file"]!.isNotEmpty) {
                _handleFileClick(material["file"]!, material["type"]!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("No file available for this material!")),
                );
              }
            },
          ),
        );
      },
    );
  }

  void _handleFileClick(String filePath, String fileType) {
    File file = File(filePath);

    if (file.existsSync()) {
      if (fileType == "Image") {
        _showImagePreview(filePath);
      } else {
        print("📂 Opening file: $filePath"); // Debugging log
      }
    } else {
      print("❌ File not found: $filePath");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File not found! Path: $filePath")),
      );
    }
  }

  void _showImagePreview(String filePath) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.file(File(filePath)),
                SizedBox(height: 10),
                Text(
                  filePath.split('/').last,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
