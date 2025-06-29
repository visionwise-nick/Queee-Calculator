import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';

class ImageUploadWidget extends StatefulWidget {
  final String title;
  final String? currentImageUrl;
  final Function(String imageUrl) onImageSelected;
  final bool showAIGeneration;

  const ImageUploadWidget({
    Key? key,
    required this.title,
    this.currentImageUrl,
    required this.onImageSelected,
    this.showAIGeneration = false,
  }) : super(key: key);

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isGenerating = false;

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      final File imageFile = File(image.path);
      final result = await AIService.uploadImage(imageFile);

      if (result['success'] == true) {
        widget.onImageSelected(result['image_url']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('图片上传成功！')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('图片上传失败: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _generateAIBackground() async {
    final TextEditingController promptController = TextEditingController();
    
    final String? prompt = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI生成背景'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: promptController,
              decoration: const InputDecoration(
                labelText: '描述您想要的背景',
                hintText: '例如：现代简约风格，蓝色渐变背景',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(promptController.text),
            child: const Text('生成'),
          ),
        ],
      ),
    );

    if (prompt == null || prompt.isEmpty) return;

    try {
      setState(() {
        _isGenerating = true;
      });

      final result = await AIService.generateBackground(
        prompt: prompt,
        style: 'modern',
        size: '1024x1024',
      );

      if (result['success'] == true) {
        // 目前使用占位符URL，后续集成真正的AI生成
        widget.onImageSelected(result['placeholder_url']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'AI背景生成成功！')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI背景生成失败: $e')),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            if (widget.showAIGeneration)
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('AI生成背景'),
                onTap: () {
                  Navigator.pop(context);
                  _generateAIBackground();
                },
              ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('清除图片'),
              onTap: () {
                Navigator.pop(context);
                widget.onImageSelected('');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: widget.currentImageUrl!.startsWith('data:')
                        ? MemoryImage(
                            Uri.parse(widget.currentImageUrl!).data!.contentAsBytes(),
                          )
                        : NetworkImage(widget.currentImageUrl!) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('未选择图片', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading || _isGenerating ? null : _showImageSourceDialog,
                icon: _isUploading || _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate),
                label: Text(_isUploading
                    ? '上传中...'
                    : _isGenerating
                        ? 'AI生成中...'
                        : '选择图片'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 