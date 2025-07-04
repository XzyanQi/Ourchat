import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  final supabase = Supabase.instance.client;

  Future<Uint8List> _getFileBytes(PlatformFile file) async {
    if (file.bytes != null) {
      return file.bytes!;
    } else if (file.readStream != null) {
      final chunks = <int>[];
      await for (final chunk in file.readStream!) {
        chunks.addAll(chunk);
      }
      return Uint8List.fromList(chunks);
    } else {
      throw Exception('File tidak memiliki bytes ataupun stream.');
    }
  }

  Future<String?> uploadUserAvatar({
    required String userId,
    required PlatformFile file,
  }) async {
    try {
      final fileExt = (file.extension ?? 'jpg').toLowerCase();
      final filePath = 'avatars/$userId.$fileExt';
      final uint8list = await _getFileBytes(file);
      final response = await supabase.storage
          .from('images')
          .uploadBinary(
            filePath,
            uint8list,
            fileOptions: const FileOptions(upsert: true),
          );
      if (response != null && response.isNotEmpty) {
        final publicUrl = supabase.storage
            .from('images')
            .getPublicUrl(filePath);
        return publicUrl;
      } else {
        print('[uploadUserAvatar] Upload gagal: response kosong');
        return null;
      }
    } catch (e) {
      print('[uploadUserAvatar] Upload error: $e');
      return null;
    }
  }

  Future<String?> uploadChatImage({
    required String chatId,
    required String userId,
    required PlatformFile file,
  }) async {
    try {
      final fileExt = (file.extension ?? 'jpg').toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'chats/$chatId/${userId}_$timestamp.$fileExt';
      final uint8list = await _getFileBytes(file);
      final response = await supabase.storage
          .from('images')
          .uploadBinary(
            filePath,
            uint8list,
            fileOptions: const FileOptions(upsert: true),
          );
      if (response != null && response.isNotEmpty) {
        final publicUrl = supabase.storage
            .from('images')
            .getPublicUrl(filePath);
        return publicUrl;
      } else {
        print('[uploadChatImage] Upload gagal: response kosong');
        return null;
      }
    } catch (e) {
      print('[uploadChatImage] Upload error: $e');
      return null;
    }
  }
}
