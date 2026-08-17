import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Provider<FlutterSecureStorage> secureStorageProvider =
    Provider<FlutterSecureStorage>((Ref ref) => const FlutterSecureStorage());

final Provider<SharedPreferencesAsync> sharedPreferencesProvider =
    Provider<SharedPreferencesAsync>((Ref ref) => SharedPreferencesAsync());
