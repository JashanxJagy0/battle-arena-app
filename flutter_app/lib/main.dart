import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'core/network/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();

  final storageService = StorageService(
    prefs: prefs,
    secureStorage: secureStorage,
  );

  final notificationService = NotificationService();
  await notificationService.initialize();

  final apiClient = ApiClient(storageService: storageService);

  final authRemoteDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
  final authLocalDataSource = AuthLocalDataSourceImpl(storageService: storageService);
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    localDataSource: authLocalDataSource,
    storageService: storageService,
  );

  final authBloc = AuthBloc(authRepository: authRepository);

  runApp(
    BattleArenaApp(authBloc: authBloc, apiClient: apiClient, storageService: storageService),
  );
}
