import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'imagekit_models.dart';
import 'imagekit_exceptions.dart';
import 'imagekit_constants.dart';
import 'image_storage_type.dart';

/// Base service for interacting with ImageKit.io API via the Vercel Backend.
/// Matches legacy API surface but routes securely through backend without private keys.
class ImageKitBaseService {
  final String publicKey;
  final String urlEndpoint;
  final ImageStorageType storageType; // Used for routing in backend

  const ImageKitBaseService({
    required this.publicKey,
    required this.urlEndpoint,
    required this.storageType,
  });

  /// Maximum allowed file size: 10 MB.
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Allowed image file extensions.
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  /// Uploads [imageBytes] to the Backend which proxies it to ImageKit under [folder].
  ///
  /// Returns [ImageKitUploadResult] containing imageUrl, fileId, and providerId.
  /// Throws [ImageKitUploadException] on any failure.
  Future<ImageKitUploadResult> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
    required String folder,
    void Function(double progress)? onProgress,
  }) async {
    if (imageBytes.lengthInBytes > maxFileSizeBytes) {
      throw ImageKitUploadException(
        'Image exceeds 10 MB limit '
        '(${(imageBytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(2)} MB).',
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const ImageKitUploadException('User not authenticated');
    }

    final idToken = await user.getIdToken();
    final uri = Uri.parse(ImageKitConstants.uploadEndpoint);
    
    // Ensure folder starts with /
    final formattedFolder = folder.startsWith('/') ? folder : '/$folder';

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $idToken'
      ..fields['fileName'] = fileName
      ..fields['folder'] = formattedFolder
      ..fields['storageType'] = storageType.name
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
        ),
      );

    onProgress?.call(0.05);

    try {
      final streamedResponse = await request.send();

      int received = 0;
      final total = streamedResponse.contentLength ?? 1;
      final chunks = <int>[];

      await for (final chunk in streamedResponse.stream) {
        chunks.addAll(chunk);
        received += chunk.length;
        onProgress?.call((received / total).clamp(0.0, 0.90));
      }

      onProgress?.call(1.0);

      final responseBody = utf8.decode(chunks);

      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(responseBody);
        
        if (data['success'] == true) {
          final result = ImageKitUploadResult.fromJson(data);
          if (result.imageUrl.isNotEmpty && result.imageFileId.isNotEmpty) {
            return result;
          }
        }
        throw ImageKitUploadException(
          'Upload succeeded but missing URL or fileId in response.',
        );
      } else {
        String errorMessage = 'HTTP ${streamedResponse.statusCode}';
        try {
          final Map<String, dynamic> errData = json.decode(responseBody);
          errorMessage = errData['message'] ?? errData['error'] ?? errorMessage;
        } catch (_) {
          errorMessage = '$errorMessage — $responseBody';
        }
        throw ImageKitUploadException('ImageKit upload failed: $errorMessage');
      }
    } catch (e) {
      if (e is ImageKitException) rethrow;
      throw ImageKitUploadException('Network error during upload: $e');
    }
  }

  /// Deletes an image from ImageKit via Backend using its [imageFileId].
  ///
  /// Throws [ImageKitDeleteException] on failure.
  Future<void> deleteImage(String imageFileId, {String? providerId}) async {
    if (imageFileId.isEmpty) {
      throw const ImageKitDeleteException('File ID cannot be empty');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const ImageKitDeleteException('User not authenticated');
    }

    final idToken = await user.getIdToken();
    final uri = Uri.parse(ImageKitConstants.deleteEndpoint);

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'fileId': imageFileId,
          'storageType': storageType.name,
          // Send providerId if we have it (from newer images), else backend falls back to storageType mapping
          if (providerId != null && providerId.isNotEmpty) 'providerId': providerId, 
        }),
      );

      if (response.statusCode != 200) {
        String errorMessage = 'HTTP ${response.statusCode}';
        try {
          final Map<String, dynamic> errData = json.decode(response.body);
          errorMessage = errData['message'] ?? errData['error'] ?? errorMessage;
        } catch (_) {
          errorMessage = '$errorMessage — ${response.body}';
        }
        throw ImageKitDeleteException('ImageKit delete failed: $errorMessage');
      }
    } catch (e) {
      if (e is ImageKitException) rethrow;
      throw ImageKitDeleteException('Network error during delete: $e');
    }
  }

  /// Builds a full CDN URL for a given relative file path.
  String getUrl(String filePath) {
    final base = urlEndpoint.endsWith('/') ? urlEndpoint : '$urlEndpoint/';
    final path = filePath.startsWith('/') ? filePath.substring(1) : filePath;
    return '$base$path';
  }

  /// Generates a safe, timestamped filename preserving the original extension.
  String generateFileName(String originalName, String prefix) {
    final ext = originalName.split('.').last.toLowerCase();
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
  }

  /// Returns true if the file extension is allowed.
  static bool isAllowedExtension(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return allowedExtensions.contains(ext);
  }
}
