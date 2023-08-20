import 'dart:convert';
import 'dart:io';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:socketio_native/socketio_native.dart';
import 'package:workmanager/workmanager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  dev.log('Initializing Workmanager', name: 'Main Log');
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  runApp(const MyApp());
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  dev.log('Calling work manager task handler', name: 'customlog');
  Workmanager().executeTask((taskName, inputData) async {
    dev.log('Instancing FLNP', name: 'customlog');
    FlutterLocalNotificationsPlugin flip = FlutterLocalNotificationsPlugin();
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      dev.log('Checking device sdk', name: 'customlog');
      if (androidInfo.version.sdkInt > 32) {
        dev.log('Requesting permissions', name: 'customlog');
        flip
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestPermission();
      }
    }

    dev.log('Initializing Android settings', name: 'customlog');
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    dev.log('initializing plugin settigs', name: 'customlog');
    const settings = InitializationSettings(android: android);
    dev.log('Initializing FLNP plugin', name: 'customlog');
    await flip.initialize(settings);

    Option option = Option();
    option.setTransport([SocketIoTransport.websocket]);

    SocketIO socket =
        await IO.create('http://192.168.1.10:3000', option: option);

    socket.onConnect(
        (p0) => socket.emit('join', jsonEncode({"mensagem": "Me conectei"})));

    socket.on('join', (data) {
      Random rdn = Random();

      Map<Object?, Object?> work = data;
      dev.log('${work.values.toList().toString()}');

      work.values.forEach((element) {
        dev.log(element.toString(), name: "Foreach log");
        _showNotificationWithDefaultSound(
            flip, rdn.nextInt(1000), jsonDecode(element.toString()));
      });
      // _showNotificationWithDefaultSound(flip, rdn.nextInt(1000), data);
    });
    return Future.delayed(const Duration(minutes: 15),() => true);
  });
}

Future _showNotificationWithDefaultSound(flip, id, data) async {
  const apcs = AndroidNotificationDetails(
    'push',
    'Push Notifications',
    importance: Importance.max,
    priority: Priority.high,
  );

  const pcs = NotificationDetails(android: apcs);

  await flip.show(id, data["mensagem"], data["mensagem"], pcs,
      payload: 'Ulala');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter notification app'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('a'),
      ),
      body: Center(
        child: TextButton(
          onPressed: () {
            Workmanager()
                .registerOneOffTask('Background Socket', 'Background Socket',
                    existingWorkPolicy: ExistingWorkPolicy.replace,
                    constraints: Constraints(
                      networkType: NetworkType.connected,
                      requiresBatteryNotLow: false,
                      requiresCharging: false,
                      requiresDeviceIdle: false,
                      requiresStorageNotLow: false,
                    ),);
          },
          child: Text('Start Socket Notification Background Handler'),
        ),
      ),
    );
  }
}
