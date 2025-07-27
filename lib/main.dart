import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pexels/logic/photo_bloc.dart';
import 'package:pexels/presentation/home_page.dart';
import 'data/photo_repository.dart';

@pragma('vm:entry-point')
void callback(String id, int status, int progress) {
  debugPrint('cal ack----------id=$id--stauus=$status---progress=$progress');
  if (status == DownloadTaskStatus.complete.index) {
    final SendPort? send = IsolateNameServer.lookupPortByName(
      'downloader_send_port',
    );
    send?.send([id, status, progress]);
  } else {
    debugPrint('this is $status');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
    debug:
        true, 
  );
  FlutterDownloader.registerCallback(callback);
  bool granted = await requestStoragePermission();

  if (granted) {
    final repository = PhotoRepository();
    runApp(MyApp(repository: repository));
  } else {
    runApp(const PermissionDeniedApp());
  }
}

Future<bool> requestStoragePermission() async {
  if (Platform.isAndroid) {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();
        return photos.isGranted || videos.isGranted;
      } else if (sdkInt >= 29) {
        final storage = await Permission.storage.request();
        final mediaLocation = await Permission.accessMediaLocation.request();
        return storage.isGranted && mediaLocation.isGranted;
      } else {
        final storage = await Permission.storage.request();
        return storage.isGranted;
      }
    } catch (e) {
      debugPrint('Error getting Android version: $e');
      return false;
    }
  } else if (Platform.isIOS) {
    var photos = await Permission.photos.request();
    return photos.isGranted;
  }
  return false;
}

class MyApp extends StatelessWidget {
  final PhotoRepository repository;
  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pexels Gallery',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: BlocProvider(
        create: (_) => PhotoBloc(repository),
        child: const EnhancedHomePage(),
      ),
    );
  }
}

class PermissionDeniedApp extends StatelessWidget {
  const PermissionDeniedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Storage permission is required to download photos. Please grant permission and restart the app.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (Platform.isAndroid) {
                    SystemNavigator.pop();
                  } else if (Platform.isIOS) {
                    exit(0);
                  }
                },
                child: const Text('Exit'),
              ),
              TextButton(
                onPressed: () async {
                  bool granted = await requestStoragePermission();
                  if (granted) {
                    main();
                  }
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
