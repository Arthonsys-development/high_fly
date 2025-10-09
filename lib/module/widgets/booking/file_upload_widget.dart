import 'package:flutter/material.dart';
import '../../../config/constant/app_colors.dart';
import '../../../config/constant/const_assets.dart';
import '../../utils/app_fonts.dart';

class FileUploadWidget extends StatelessWidget {
  final String label;
  final String? fileName;
  final bool isRequired;
  final Function(String) onFileSelected;
  final String? acceptedFileTypes;
  final String? placeholderText;

  const FileUploadWidget({
    super.key,
    required this.label,
    this.fileName,
    this.isRequired = false,
    required this.onFileSelected,
    this.acceptedFileTypes,
    this.placeholderText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with required indicator
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppFonts.getFont(
                weight: AppFonts.medium,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: SizedBox(
                  width: 5,
                  height: 5,
                  child: Image.asset(IconsAssets.star, color: Colors.red),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        
        // File upload field
        GestureDetector(
          onTap: () => _pickFile(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.textFieldBGColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.black26,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    fileName ?? (placeholderText ?? 'Upload file'),
                    style: TextStyle(
                      fontSize: 14,
                      color: fileName != null 
                          ? const Color(0xFF475569) 
                          : const Color(0xFF6A6A6A),
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    // For now, simulate file selection
    // In a real implementation, you would use file_picker or image_picker
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Upload'),
        content: Text('File upload functionality will be implemented with file_picker package. For now, this is a placeholder.\n\nAccepted file types: ${acceptedFileTypes ?? 'All files'}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Simulate file selection with dynamic file name
              final fileExtension = acceptedFileTypes?.contains('pdf') == true ? 'pdf' : 'jpg';
              onFileSelected('sample_file.$fileExtension');
            },
            child: const Text('Select File'),
          ),
        ],
      ),
    );
  }
}
