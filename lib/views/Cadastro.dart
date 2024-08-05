import 'package:flutter/material.dart';
import 'package:app_uber/model/Usuario.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Cadastro extends StatefulWidget {
  @override
  _CadastroState createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {

  final TextEditingController _controllerNome = TextEditingController(text: "Rafael Leonan");
  final TextEditingController _controllerEmail = TextEditingController(text: "faelleonan@gmail.com");
  final TextEditingController _controllerSenha = TextEditingController(text: "1234567");
  bool _tipoUsuario = false;

  _validarCampos(){
    //Recuperar dados dos campos
    String nome = _controllerNome.text;
    String email = _controllerEmail.text;
    String senha = _controllerSenha.text;

    //validar campos
    if( nome.isNotEmpty ){
      if( email.isNotEmpty && email.contains("@") ){
        if( senha.isNotEmpty && senha.length > 6 ){

          Usuario usuario = Usuario();
          usuario.nome = nome;
          usuario.email = email;
          usuario.senha = senha;
          usuario.tipoUsuario = usuario.verificaTipoUsuario(_tipoUsuario);

          _cadastrarUsuario( usuario );

        } else {
          _showSnackbar("Preencha a senha! digite mais de 6 caracteres");
        }

      } else {
        _showSnackbar("Preencha o E-mail válido");
      }

    } else {
      _showSnackbar("Preencha o Nome");
    }
  }

  _cadastrarUsuario( Usuario usuario ){

    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db = FirebaseFirestore.instance;

    auth.createUserWithEmailAndPassword(
        email: usuario.email,
        password: usuario.senha
    ).then((firebaseUser){
      print("CADASTRO DE USUÁRIO......");
      db.collection("usuarios")
      .doc(firebaseUser.user!.uid )
      .set(usuario.toMap()).catchError((error) {
        print(error);
      });
      print("FINALIZANDO CADASTRO DE USUÁRIO......");
      //redireciona para o painel, de acordo com o tipoUsuario
      switch( usuario.tipoUsuario ){
        case "motorista" :
          Navigator.pushNamedAndRemoveUntil(
              context,
              "/painel-motorista",
              (_) => false
          );
          break;
        case "passageiro" :
          Navigator.pushNamedAndRemoveUntil(
              context,
              "/painel-passageiro",
                  (_) => false
          );
          break;
      }

    }).catchError((error){
      print(error);
      _showSnackbar("Erro ao cadastrar usuário, verifique os campos e tente novamente!");
    });
  }

  _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w700),),
        backgroundColor: Colors.white60,
        showCloseIcon: true,
        duration: const Duration(seconds: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastro"),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _controllerNome,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                      contentPadding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: "Nome completo",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6)
                      )
                  ),
                ),
                TextField(
                  controller: _controllerEmail,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                      contentPadding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: "e-mail",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6)
                      )
                  ),
                ),
                TextField(
                  controller: _controllerSenha,
                  obscureText: true,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                      contentPadding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: "senha",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6)
                      )
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: <Widget>[
                      const Text("Passageiro"),
                      Switch(
                          value: _tipoUsuario,
                          onChanged: (bool valor){
                            setState(() {
                              _tipoUsuario = valor;
                            });
                          }
                      ),
                      const Text("Motorista"),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 10),
                  child: ElevatedButton(
                      style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Color(0xff1ebbd8)),
                        padding: WidgetStatePropertyAll(EdgeInsets.fromLTRB(32, 16, 32, 16)),
                      ),
                      child: const Text(
                        "Cadastrar",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      onPressed: (){
                        _validarCampos();
                      }
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
