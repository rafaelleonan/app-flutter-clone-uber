import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:app_uber/views/Home.dart';
import 'firebase_options.dart';
import 'Rotas.dart';

final ThemeData temaPadrao = ThemeData(
  primaryColor: const Color(0xff37474f),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    secondary: const Color(0xff546e7a),
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MaterialApp(
    title: "Uber",
    home: Home(),
    theme: temaPadrao,
    initialRoute: "/",
    onGenerateRoute: Rotas.gerarRotas,
    debugShowCheckedModeBanner: false,
  ));
}
