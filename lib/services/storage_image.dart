import 'package:flutter/painting.dart';

import '../supabase_config.dart';

NetworkImage? storageImage(String? value) {
  if (value == null) return null;
  final uri = Uri.tryParse(value);
  final project = Uri.parse(SupabaseConfig.url);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.userInfo.isNotEmpty ||
      uri.host != project.host ||
      uri.port != project.port ||
      !(uri.path.startsWith('/storage/v1/object/sign/') ||
          uri.path.startsWith('/storage/v1/object/public/'))) {
    return null;
  }
  return NetworkImage(value);
}
