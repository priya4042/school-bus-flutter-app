import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Avatar upload service - matches React app exactly
/// 1. Pick image from camera or gallery
/// 2. Upload to Supabase Storage 'avatars' bucket
/// 3. Get public URL
/// 4. Save to profiles.avatar_url (with fallback to preferences.avatar_url JSONB)
class AvatarService {
  static final _supabase = Supabase.instance.client;
  static final _picker = ImagePicker();

  /// Pick an image from gallery
  static Future<XFile?> pickImage() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('[AvatarService] Pick error: $e');
      return null;
    }
  }

  /// Upload avatar to Supabase Storage and persist URL to profile
  /// Returns the public URL on success, or null on failure
  static Future<String?> uploadAvatar(String userId, XFile file) async {
    try {
      // Read file as bytes (works on web + mobile)
      final Uint8List bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

      debugPrint('[AvatarService] Uploading $path (${bytes.length} bytes)');

      // Upload to Supabase Storage
      await _supabase.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$ext',
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      debugPrint('[AvatarService] Public URL: $publicUrl');

      // Persist to profiles table
      await persistAvatarUrl(userId, publicUrl);

      return publicUrl;
    } catch (e) {
      debugPrint('[AvatarService] Upload error: $e');
      // Fallback: use data URL (base64)
      try {
        final bytes = await file.readAsBytes();
        final ext = file.name.split('.').last.toLowerCase();
        final dataUrl = 'data:image/$ext;base64,${base64Encode(bytes)}';
        await persistAvatarUrl(userId, dataUrl);
        return dataUrl;
      } catch (e2) {
        debugPrint('[AvatarService] Fallback also failed: $e2');
        return null;
      }
    }
  }

  /// Persist avatar URL to profiles table
  /// Try direct column first, fallback to preferences JSONB
  static Future<void> persistAvatarUrl(String userId, String? url) async {
    try {
      // Try direct avatar_url column update
      await _supabase
          .from('profiles')
          .update({'avatar_url': url})
          .eq('id', userId);
      debugPrint('[AvatarService] Saved avatar_url for $userId');
    } catch (e) {
      debugPrint('[AvatarService] avatar_url column failed, trying preferences: $e');
      // Fallback: store in preferences JSONB
      try {
        final profile = await _supabase
            .from('profiles')
            .select('preferences')
            .eq('id', userId)
            .maybeSingle();
        final prefs = (profile?['preferences'] as Map?)?.cast<String, dynamic>() ?? {};
        prefs['avatar_url'] = url;
        await _supabase
            .from('profiles')
            .update({'preferences': prefs})
            .eq('id', userId);
        debugPrint('[AvatarService] Saved to preferences.avatar_url');
      } catch (e2) {
        debugPrint('[AvatarService] Fallback save also failed: $e2');
      }
    }
  }

  /// Remove avatar
  static Future<void> removeAvatar(String userId) async {
    await persistAvatarUrl(userId, null);
  }
}

