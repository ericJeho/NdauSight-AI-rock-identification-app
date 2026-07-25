import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'services/ai_service.dart';
import 'services/app_settings.dart';
import 'services/location_service.dart';
import 'services/scan_repository.dart';
import 'services/storage_service.dart';
import 'services/sync_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = AppSettings();
  await settings.load();

  final storage = StorageService();
  await storage.init();

  final location = LocationService();
  final ai = AiService(settings);
  final sync = SyncService(storage: storage, settings: settings);

  final repo = ScanRepository(
    ai: ai,
    storage: storage,
    location: location,
    sync: sync,
    settings: settings,
  );

  runApp(NdauSightApp(settings: settings, repo: repo));
}

class NdauSightApp extends StatelessWidget {
  final AppSettings settings;
  final ScanRepository repo;

  const NdauSightApp(
      {super.key, required this.settings, required this.repo});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: repo),
      ],
      child: MaterialApp(
        title: 'NdauSight AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeShell(),
      ),
    );
  }
}
