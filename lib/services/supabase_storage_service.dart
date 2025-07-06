import 'dart:io';
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
    } else if (file.path != null) {
      final f = File(file.path!);
      return await f.readAsBytes();
    } else {
      throw Exception('File tidak memiliki bytes, stream, atau path.');
    }
  }

  Future<Uint8List> _getFileBytesFromFile(File file) async {
    return await file.readAsBytes();
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
        return supabase.storage.from('images').getPublicUrl(filePath);
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
        return supabase.storage.from('images').getPublicUrl(filePath);
      } else {
        print('[uploadChatImage] Upload gagal: response kosong');
        return null;
      }
    } catch (e) {
      print('[uploadChatImage] Upload error: $e');
      return null;
    }
  }

  Future<String?> uploadChatVoiceNote({
    required String chatId,
    required String userId,
    required PlatformFile file,
  }) async {
    try {
      final fileExt = (file.extension ?? 'm4a').toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'chats/$chatId/voice_${userId}_$timestamp.$fileExt';
      final uint8list = await _getFileBytes(file);
      final response = await supabase.storage
          .from('images')
          .uploadBinary(
            filePath,
            uint8list,
            fileOptions: const FileOptions(upsert: true),
          );
      if (response != null && response.isNotEmpty) {
        return supabase.storage.from('images').getPublicUrl(filePath);
      } else {
        print('[uploadChatVoiceNote] Upload gagal: response kosong');
        return null;
      }
    } catch (e) {
      print('[uploadChatVoiceNote] Upload error: $e');
      return null;
    }
  }

  Future<String?> uploadChatVoiceNoteFile({
    required String chatId,
    required String userId,
    required File file,
  }) async {
    try {
      final fileExt = file.path.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'chats/$chatId/voice_${userId}_$timestamp.$fileExt';
      final uint8list = await _getFileBytesFromFile(file);
      final response = await supabase.storage
          .from('images')
          .uploadBinary(
            filePath,
            uint8list,
            fileOptions: const FileOptions(upsert: true),
          );
      if (response != null && response.isNotEmpty) {
        return supabase.storage.from('images').getPublicUrl(filePath);
      } else {
        print('[uploadChatVoiceNoteFile] Upload gagal: response kosong');
        return null;
      }
    } catch (e) {
      print('[uploadChatVoiceNoteFile] Upload error: $e');
      return null;
    }
  }
}
