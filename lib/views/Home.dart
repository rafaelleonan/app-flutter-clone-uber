import 'package:flutter/material.dart';
import 'package:app_uber/model/Usuario.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final TextEditingController _controllerEmail = TextEditingController(text: "faelleonan@gmail.com");
  final TextEditingController _controllerSenha = TextEditingController(text: "1234567");
  bool _carregando = false;

  _validarCampos(){
    //Recuperar dados dos campos
    String email = _controllerEmail.text;
    String senha = _controllerSenha.text;

    //validar campos
    if( email.isNotEmpty && email.contains("@") ){
      if( senha.isNotEmpty && senha.length > 6 ){
        Usuario usuario = Usuario();
        usuario.email = email;
        usuario.senha = senha;

        _logarUsuario( usuario );
      } else {
        _showSnackbar("Preencha a senha! digite mais de 6 caracteres");
      }
    }else{
      _showSnackbar("Preencha o E-mail válido");
    }
  }

  _toggleSpinner(bool toggle) {
    setState(() {
      _carregando = toggle;
    });
  }

  _logarUsuario( Usuario usuario ){
    _toggleSpinner(true);

    FirebaseAuth auth = FirebaseAuth.instance;

    auth.signInWithEmailAndPassword(
        email: usuario.email,
        password: usuario.senha
    ).then((firebaseUser){

      _redirecionaPainelPorTipoUsuario( firebaseUser.user!.uid );
      _toggleSpinner(false);
    }).catchError((error){
      _showSnackbar("Erro ao autenticar usuário, verifique e-mail e senha e tente novamente!");
      _toggleSpinner(false);
    });
  }

  _redirecionaPainelPorTipoUsuario(String idUsuario) async {

    FirebaseFirestore db = FirebaseFirestore.instance;

    DocumentSnapshot snapshot = await db.collection("usuarios")
    .doc( idUsuario )
    .get();

    if (snapshot.data() != null) {
      Map<String, dynamic> dados = snapshot.data() as Map<String, dynamic>;
      String tipoUsuario = dados["tipoUsuario"];

      _toggleSpinner(false);

      switch( tipoUsuario ){
        case "motorista" :
          Navigator.pushReplacementNamed(context, "/painel-motorista");
          break;
        case "passageiro" :
          Navigator.pushReplacementNamed(context, "/painel-passageiro");
          break;
      }
    } else {
      _showSnackbar("Ocorreu um erro!");
    }
  }

  _verificarUsuarioLogado() {
    FirebaseAuth auth = FirebaseAuth.instance;

    User? usuarioLogado = auth.currentUser;
    if( usuarioLogado != null ){
      String idUsuario = usuarioLogado.uid;
      _redirecionaPainelPorTipoUsuario(idUsuario);
    }
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
  void initState() {
    super.initState();
    _verificarUsuarioLogado();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage("assets/images/fundo.png"),
              fit: BoxFit.cover
          )
        ),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Image.asset(
                      "assets/images/logo.png",
                    width: 200,
                    height: 150,
                  ),
                ),
                TextField(
                  controller: _controllerEmail,
                  autofocus: true,
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
                  padding: const EdgeInsets.only(top: 16, bottom: 10),
                  child: ElevatedButton(
                    style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Color(0xff1ebbd8)),
                      padding: WidgetStatePropertyAll(EdgeInsets.fromLTRB(32, 16, 32, 16)),
                    ),
                    onPressed: (){
                      _validarCampos();
                    },
                    child: _carregando
                        ? const Center(
                            child: CircularProgressIndicator(
                              backgroundColor: Colors.white,
                              value: 2,
                            ),
                          )
                        : const Text(
                      "Entrar",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
                Center(
                  child: GestureDetector(
                    child: const Text(
                        "Não tem conta? cadastre-se!",
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: (){
                      Navigator.pushNamed(context, "/cadastro");
                    },
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
