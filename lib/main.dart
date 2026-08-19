import 'package:flutter/material.dart';

import 'app_services.dart';
import 'screens/guide_screen.dart';
import 'screens/main_shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.create();
  runApp(LastCheckApp(services: services));
}

class LastCheckApp extends StatelessWidget {
  final AppServices services;
  const LastCheckApp({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return ServicesScope(
      services: services,
      child: MaterialApp(
        title: 'LastCheck 出门别忘',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: _Home(),
      ),
    );
  }
}

class _Home extends StatefulWidget {
  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  bool? _guideSeen;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seen = ServicesScope.of(context).repo.getGuideSeen();
    setState(() => _guideSeen = seen);
  }

  @override
  Widget build(BuildContext context) {
    if (_guideSeen == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_guideSeen!) {
      return GuideScreen(onFinished: () {
        setState(() => _guideSeen = true);
      });
    }
    return const MainShell();
  }
}
