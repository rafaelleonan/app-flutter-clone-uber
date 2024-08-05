import 'package:flutter/material.dart';
import 'package:app_uber/views/Cadastro.dart';
import 'package:app_uber/views/Corrida.dart';
import 'package:app_uber/views/Home.dart';
import 'package:app_uber/views/PainelMotorista.dart';
import 'package:app_uber/views/PainelPassageiro.dart';

class Rotas {

  static Route<dynamic> gerarRotas(RouteSettings settings){

    final args = settings.arguments;

    switch( settings.name ){
      case "/" :
        return MaterialPageRoute(
            builder: (_) => Home()
        );
      case "/cadastro" :
        return MaterialPageRoute(
            builder: (_) => Cadastro()
        );
      case "/painel-motorista" :
        return MaterialPageRoute(
            builder: (_) => PainelMotorista()
        );
      case "/painel-passageiro" :
        return MaterialPageRoute(
            builder: (_) => PainelPassageiro()
        );
      case "/corrida" :
        String arg = args as String;
        return MaterialPageRoute(
            builder: (_) => Corrida(
                arg
            )
        );
      default:
       return _erroRota();
    }

  }

  static Route<dynamic> _erroRota(){

    return MaterialPageRoute(
        builder: (_){
          return Scaffold(
            appBar: AppBar(title: const Text("Tela não encontrada!"),),
            body: const Center(
              child: Text("Tela não encontrada!"),
            ),
          );
        }
    );
  }
}