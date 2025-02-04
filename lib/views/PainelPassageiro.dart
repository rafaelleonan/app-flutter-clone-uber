import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';
import 'package:app_uber/model/Destino.dart';
import 'package:app_uber/model/Marcador.dart';
import 'package:app_uber/model/Requisicao.dart';
import 'package:app_uber/model/Usuario.dart';
import 'package:app_uber/util/StatusRequisicao.dart';
import 'package:app_uber/util/UsuarioFirebase.dart';

class PainelPassageiro extends StatefulWidget {
  @override
  _PainelPassageiroState createState() => _PainelPassageiroState();
}

class _PainelPassageiroState extends State<PainelPassageiro> {
  final TextEditingController _controllerDestino =
      TextEditingController(text: "R. Heitor Penteado, 800");
  List<String> itensMenu = ["Configurações", "Deslogar"];
  final Completer<GoogleMapController> _controller = Completer();
  late CameraPosition _posicaoCamera = const CameraPosition(target: LatLng(-23.563999, -46.653256));
  Set<Marker> _marcadores = {};
  String? _idRequisicao;
  Position? _localPassageiro;
  late Map<String, dynamic> _dadosRequisicao;
  StreamSubscription<DocumentSnapshot>? _streamSubscriptionRequisicoes;

  //Controles para exibição na tela
  bool _exibirCaixaEnderecoDestino = true;
  String _textoBotao = "Chamar uber";
  Color _corBotao = const Color(0xff1ebbd8);
  Function? _funcaoBotao;

  _deslogarUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();
    Navigator.pushReplacementNamed(context, "/");
  }

  _escolhaMenuItem(String escolha) {
    switch (escolha) {
      case "Deslogar":
        _deslogarUsuario();
        break;
      case "Configurações":
        break;
    }
  }

  _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  _adicionarListenerLocalizacao() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se os serviços de localização estão habilitados.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Os serviços de localização estão desabilitados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permissão de localização negada.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permissões de localização são permanentemente negadas.');
    }

    var locationSettings = const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);

    Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      print("[Geolocator.getPositionStream] ${_idRequisicao}");
      if( _idRequisicao != null && _idRequisicao!.isNotEmpty ){
        print("[IF] ${_idRequisicao}");
        //Atualiza local do passageiro
        UsuarioFirebase.atualizarDadosLocalizacao(
            _idRequisicao!,
            position.latitude,
            position.longitude,
            "passageiro"
        );
      } else {
        print("[ELSE] $position");
        setState(() {
          _localPassageiro = position;
        });
        _statusUberNaoChamado();
      }
    });
  }

  _recuperaUltimaLocalizacaoConhecida() async {
    Position? position = await Geolocator.getLastKnownPosition();

    setState(() {
      if (position != null) {
        _exibirMarcadorPassageiro(position);

        _posicaoCamera = CameraPosition(
            target: LatLng(position.latitude, position.longitude), zoom: 19);
        _localPassageiro = position;
        _movimentarCamera(_posicaoCamera);
      }
    });
  }

  _movimentarCamera(CameraPosition cameraPosition) async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  _exibirMarcadorPassageiro(Position local) async {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    BitmapDescriptor.asset(
            ImageConfiguration(devicePixelRatio: pixelRatio),
            "assets/images/passageiro.png")
        .then((BitmapDescriptor icone) {
      Marker marcadorPassageiro = Marker(
          markerId: const MarkerId("marcador-passageiro"),
          position: LatLng(local.latitude, local.longitude),
          infoWindow: const InfoWindow(title: "Meu local"), // -3.7172444730914567, -38,606354826646665
          icon: icone);

      setState(() {
        _marcadores.add(marcadorPassageiro);
      });
    });
  }

  _chamarUber() async {
    String enderecoDestino = _controllerDestino.text;

    if (enderecoDestino.isNotEmpty) {
      List<Location> locations = await locationFromAddress(enderecoDestino);
      if (locations.isNotEmpty) {
        Location location = locations[0];
        List<Placemark> placemarks =
        await placemarkFromCoordinates(location.latitude, location.longitude);

        if (placemarks.isNotEmpty) {
          Placemark endereco = placemarks[0];
          Destino destino = Destino();
          destino.cidade = endereco.administrativeArea!;
          destino.cep = endereco.postalCode!;
          destino.bairro = endereco.subLocality!;
          destino.rua = endereco.thoroughfare!;
          destino.numero = endereco.subThoroughfare!;
          destino.latitude = location.latitude;
          destino.longitude = location.longitude;

          String enderecoConfirmacao;
          enderecoConfirmacao = "\n Cidade: " + (destino.cidade ?? '');
          enderecoConfirmacao += "\n Rua: " + (destino.rua ?? '') + ", " + (destino.numero ?? '');
          enderecoConfirmacao += "\n Bairro: " + (destino.bairro ?? '');
          enderecoConfirmacao += "\n Cep: " + (destino.cep ?? '');

          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("Confirmação do endereço"),
                content: Text(enderecoConfirmacao),
                contentPadding: const EdgeInsets.all(16),
                actions: <Widget>[
                  TextButton(
                    child: const Text(
                      "Cancelar",
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: const Text(
                      "Confirmar",
                      style: TextStyle(color: Colors.green),
                    ),
                    onPressed: () {
                      //salvar requisicao
                      _salvarRequisicao(destino);
                      Navigator.pop(context);
                    },
                  )
                ],
              );
            },
          );
        }
      }
    }
  }

  _salvarRequisicao(Destino destino) async {
    /*

    + requisicao
      + ID_REQUISICAO
        + destino (rua, endereco, latitude...)
        + passageiro (nome, email...)
        + motorista (nome, email..)
        + status (aguardando, a_caminho...finalizada)

    * */

    Usuario passageiro = await UsuarioFirebase.getDadosUsuarioLogado();
    print(_localPassageiro);// -3,7179355410763697, -38,60468403628509
    passageiro.latitude = _localPassageiro!.latitude;
    passageiro.longitude = _localPassageiro!.longitude; // -3,719591348865714, -38,60299715633572

    Requisicao requisicao = Requisicao();
    requisicao.destino = destino;
    requisicao.passageiro = passageiro;
    requisicao.status = StatusRequisicao.AGUARDANDO;

    FirebaseFirestore db = FirebaseFirestore.instance;

    //salvar requisição
    db
    .collection("requisicoes")
    .doc(requisicao.id)
    .set( requisicao.toMap() );

    //Salvar requisição ativa
    Map<String, dynamic> dadosRequisicaoAtiva = {};
    dadosRequisicaoAtiva["id_requisicao"] = requisicao.id;
    dadosRequisicaoAtiva["id_usuario"] = passageiro.idUsuario;
    dadosRequisicaoAtiva["status"] = StatusRequisicao.AGUARDANDO;

    db
    .collection("requisicao_ativa")
    .doc(passageiro.idUsuario)
    .set(dadosRequisicaoAtiva);

    //Adicionar listener requisicao
    if( _streamSubscriptionRequisicoes == null ){
      _adicionarListenerRequisicao( requisicao.id );
    }
  }

  _alterarBotaoPrincipal(String texto, Color cor, Function funcao) {
    setState(() {
      _textoBotao = texto;
      _corBotao = cor;
      _funcaoBotao = funcao;
    });
  }

  _statusUberNaoChamado() {
    _exibirCaixaEnderecoDestino = true;

    _alterarBotaoPrincipal("Chamar uber", const Color(0xff1ebbd8), () {
      _chamarUber();
    });

    if( _localPassageiro != null ){
      Position position = Position(
          latitude: _localPassageiro!.latitude,
          longitude: _localPassageiro!.longitude,
          timestamp: _localPassageiro!.timestamp,
          accuracy: _localPassageiro!.accuracy,
          altitude: _localPassageiro!.altitude,
          altitudeAccuracy: _localPassageiro!.altitudeAccuracy,
          heading: _localPassageiro!.heading,
          headingAccuracy: _localPassageiro!.headingAccuracy,
          speed: _localPassageiro!.speed,
          speedAccuracy: _localPassageiro!.speedAccuracy
      );
      _exibirMarcadorPassageiro(position);
      CameraPosition cameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude), zoom: 19);
      _movimentarCamera( cameraPosition );
    }
  }

  _statusAguardando() {
    _exibirCaixaEnderecoDestino = false;

    _alterarBotaoPrincipal("Cancelar", Colors.red, () {
      _cancelarUber();
    });

    double passageiroLat = _dadosRequisicao["passageiro"]["latitude"];
    double passageiroLon = _dadosRequisicao["passageiro"]["longitude"];
    Position position = Position(
        latitude: passageiroLat,
        longitude: passageiroLon,
        timestamp: DateTime.now(), // TODO: VERIFICAR
        accuracy: 0, // TODO: VERIFICAR
        altitude: 0, // TODO: VERIFICAR
        altitudeAccuracy: 0, // TODO: VERIFICAR
        heading: 0, // TODO: VERIFICAR
        headingAccuracy: 0, // TODO: VERIFICAR
        speed: 0, // TODO: VERIFICAR
        speedAccuracy: 0 // TODO: VERIFICAR
    );
    _exibirMarcadorPassageiro(position);
    CameraPosition cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude), zoom: 19);
    _movimentarCamera( cameraPosition );
  }

  _statusACaminho() {
    _exibirCaixaEnderecoDestino = false;
    _alterarBotaoPrincipal(
        "Motorista a caminho",
        Colors.grey,
        () {
    });

    double latitudeDestino = _dadosRequisicao["passageiro"]["latitude"];
    double longitudeDestino = _dadosRequisicao["passageiro"]["longitude"];

    double latitudeOrigem = _dadosRequisicao["motorista"]["latitude"];
    double longitudeOrigem = _dadosRequisicao["motorista"]["longitude"];

    Marcador marcadorOrigem = Marcador(
        LatLng(latitudeOrigem, longitudeOrigem),
        "assets/images/motorista.png",
        "Local motorista"
    );

    Marcador marcadorDestino = Marcador(
        LatLng(latitudeDestino, longitudeDestino),
        "assets/images/passageiro.png",
        "Local destino"
    );

    _exibirCentralizarDoisMarcadores(marcadorOrigem, marcadorDestino);
  }

  _statusEmViagem() {
    _exibirCaixaEnderecoDestino = false;
    _alterarBotaoPrincipal(
        "Em viagem",
        Colors.grey,
        (){}
    );


    double latitudeDestino = _dadosRequisicao["destino"]["latitude"];
    double longitudeDestino = _dadosRequisicao["destino"]["longitude"];

    double latitudeOrigem = _dadosRequisicao["motorista"]["latitude"];
    double longitudeOrigem = _dadosRequisicao["motorista"]["longitude"];

    Marcador marcadorOrigem = Marcador(
        LatLng(latitudeOrigem, longitudeOrigem),
        "assets/images/motorista.png",
        "Local motorista"
    );

    Marcador marcadorDestino = Marcador(
        LatLng(latitudeDestino, longitudeDestino),
        "assets/images/destino.png",
        "Local destino"
    );

    _exibirCentralizarDoisMarcadores(marcadorOrigem, marcadorDestino);

  }

  _exibirCentralizarDoisMarcadores( Marcador marcadorOrigem, Marcador marcadorDestino ){

    double latitudeOrigem = marcadorOrigem.local.latitude;
    double longitudeOrigem = marcadorOrigem.local.longitude;

    double latitudeDestino = marcadorDestino.local.latitude;
    double longitudeDestino = marcadorDestino.local.longitude;

    //Exibir dois marcadores
    _exibirDoisMarcadores(
        marcadorOrigem,
        marcadorDestino
    );

    //'southwest.latitude <= northeast.latitude': is not true
    var nLat, nLon, sLat, sLon;

    if( latitudeOrigem <=  latitudeDestino ){
      sLat = latitudeOrigem;
      nLat = latitudeDestino;
    }else{
      sLat = latitudeDestino;
      nLat = latitudeOrigem;
    }

    if( longitudeOrigem <=  longitudeDestino ){
      sLon = longitudeOrigem;
      nLon = longitudeDestino;
    }else{
      sLon = longitudeDestino;
      nLon = longitudeOrigem;
    }
    //-23.560925, -46.650623
    _movimentarCameraBounds(
        LatLngBounds(
            northeast: LatLng(nLat, nLon), //nordeste
            southwest: LatLng(sLat, sLon) //sudoeste
        )
    );

  }

  _statusFinalizada() {

    //Calcula valor da corrida
    double latitudeDestino = _dadosRequisicao["destino"]["latitude"];
    double longitudeDestino = _dadosRequisicao["destino"]["longitude"];
    double latitudeOrigem = _dadosRequisicao["origem"]["latitude"];
    double longitudeOrigem = _dadosRequisicao["origem"]["longitude"];

    double distanciaEmMetros = Geolocator.distanceBetween(
        latitudeOrigem,
        longitudeOrigem,
        latitudeDestino,
        longitudeDestino
    );

    //Converte para KM
    double distanciaKm = distanciaEmMetros / 1000;

    //8 é o valor cobrado por KM
    double valorViagem = distanciaKm * 8;

    //Formatar valor viagem
    var f = new NumberFormat("#,##0.00", "pt_BR");
    var valorViagemFormatado = f.format( valorViagem );

    _alterarBotaoPrincipal(
        "Total - R\$ ${valorViagemFormatado}",
        Colors.green,
        (){}
    );

    _marcadores = {};

    Position position = Position(
        latitude: latitudeDestino,
        longitude: longitudeDestino,
        timestamp: DateTime.now(), // TODO: VERIFICAR
        accuracy: 0, // TODO: VERIFICAR
        altitude: 0, // TODO: VERIFICAR
        altitudeAccuracy: 0, // TODO: VERIFICAR
        heading: 0, // TODO: VERIFICAR
        headingAccuracy: 0, // TODO: VERIFICAR
        speed: 0, // TODO: VERIFICAR
        speedAccuracy: 0 // TODO: VERIFICAR
    );
    _exibirMarcador(
        position,
        "assets/images/destino.png",
        "Destino"
    );

    CameraPosition cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude), zoom: 19);

    _movimentarCamera( cameraPosition );

  }

  _statusConfirmada(){
    if( _streamSubscriptionRequisicoes != null ) {
      _streamSubscriptionRequisicoes?.cancel();
      _streamSubscriptionRequisicoes = null;
    }

    _exibirCaixaEnderecoDestino = true;
    _alterarBotaoPrincipal(
        "Chamar uber",
        const Color(0xff1ebbd8), () {
      _chamarUber();
    });

    //Exibe local do passageiro
    double passageiroLat = _dadosRequisicao["passageiro"]["latitude"];
    double passageiroLon = _dadosRequisicao["passageiro"]["longitude"];
    Position position = Position(
        latitude: passageiroLat,
        longitude: passageiroLon,
        timestamp: DateTime.now(), // TODO: VERIFICAR
        accuracy: 0, // TODO: VERIFICAR
        altitude: 0, // TODO: VERIFICAR
        altitudeAccuracy: 0, // TODO: VERIFICAR
        heading: 0, // TODO: VERIFICAR
        headingAccuracy: 0, // TODO: VERIFICAR
        speed: 0, // TODO: VERIFICAR
        speedAccuracy: 0 // TODO: VERIFICAR
    );
    _exibirMarcadorPassageiro(position);
    CameraPosition cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude), zoom: 19);
    _movimentarCamera( cameraPosition );

    _dadosRequisicao = {};
  }

  _exibirMarcador(Position local, String icone, String infoWindow) async {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: pixelRatio),
        icone)
        .then((BitmapDescriptor bitmapDescriptor) {
      Marker marcador = Marker(
          markerId: MarkerId(icone),
          position: LatLng(local.latitude, local.longitude),
          infoWindow: InfoWindow(title: infoWindow),
          icon: bitmapDescriptor);

      setState(() {
        _marcadores.add(marcador);
      });
    });
  }

  _movimentarCameraBounds(LatLngBounds latLngBounds) async {

    GoogleMapController googleMapController = await _controller.future;
    googleMapController
        .animateCamera(
        CameraUpdate.newLatLngBounds(
            latLngBounds,
            100
        )
    );
  }

  _exibirDoisMarcadores( Marcador marcadorOrigem, Marcador marcadorDestino ){

    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    LatLng latLngOrigem = marcadorOrigem.local;
    LatLng latLngDestino = marcadorDestino.local;

    Set<Marker> _listaMarcadores = {};
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: pixelRatio),
        marcadorOrigem.caminhoImagem)
        .then((BitmapDescriptor icone) {
      Marker mOrigem = Marker(
          markerId: MarkerId(marcadorOrigem.caminhoImagem),
          position: LatLng(latLngOrigem.latitude, latLngOrigem.longitude),
          infoWindow: InfoWindow(title: marcadorOrigem.titulo),
          icon: icone);
      _listaMarcadores.add( mOrigem );
    });

    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: pixelRatio),
        marcadorDestino.caminhoImagem)
        .then((BitmapDescriptor icone) {
      Marker mDestino = Marker(
          markerId: MarkerId(marcadorDestino.caminhoImagem),
          position: LatLng(latLngDestino.latitude, latLngDestino.longitude),
          infoWindow: InfoWindow(title: marcadorDestino.titulo),
          icon: icone);
      _listaMarcadores.add( mDestino );
    });

    setState(() {
      _marcadores = _listaMarcadores;
    });
  }

  _cancelarUber() async {

    User? firebaseUser = await UsuarioFirebase.getUsuarioAtual();

    FirebaseFirestore db = FirebaseFirestore.instance;
    db.collection("requisicoes")
    .doc( _idRequisicao ).update({
      "status" : StatusRequisicao.CANCELADA
    }).then((_){

      db.collection("requisicao_ativa")
      .doc( firebaseUser!.uid )
      .delete();
      _statusUberNaoChamado();

      if( _streamSubscriptionRequisicoes != null ){
        _streamSubscriptionRequisicoes?.cancel();
        _streamSubscriptionRequisicoes = null;
      }
    });
  }

  _recuperaRequisicaoAtiva() async {
    User? firebaseUser = await UsuarioFirebase.getUsuarioAtual();

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot documentSnapshot = await db
    .collection("requisicao_ativa")
    .doc(firebaseUser!.uid)
    .get();

    if( documentSnapshot.data() != null ){
      Map<String, dynamic> dados = documentSnapshot.data() as Map<String, dynamic>;
      _idRequisicao = dados["id_requisicao"];
      _adicionarListenerRequisicao( _idRequisicao! );
    } else {
      _statusUberNaoChamado();
    }
  }

  _adicionarListenerRequisicao(String idRequisicao) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    _streamSubscriptionRequisicoes = await db.collection("requisicoes")
    .doc( idRequisicao ).snapshots().listen((snapshot){
      if( snapshot.data() != null ){

        Map<String, dynamic> dados = snapshot.data() as Map<String, dynamic>;
        _dadosRequisicao = dados;
        String status = dados["status"];
        _idRequisicao = dados["id"];

        switch( status ){
          case StatusRequisicao.AGUARDANDO :
            _statusAguardando();
            break;
          case StatusRequisicao.A_CAMINHO :
            _statusACaminho();
            break;
          case StatusRequisicao.VIAGEM :
            _statusEmViagem();
            break;
          case StatusRequisicao.FINALIZADA :
            _statusFinalizada();
            break;
          case StatusRequisicao.CONFIRMADA :
            _statusConfirmada();
            break;
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();

    //adicionar listener para requisicao ativa
    _recuperaRequisicaoAtiva();

    //_recuperaUltimaLocalizacaoConhecida();
    _adicionarListenerLocalizacao();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel passageiro"),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: _escolhaMenuItem,
            itemBuilder: (context) {
              return itensMenu.map((String item) {
                return PopupMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList();
            },
          )
        ],
      ),
      body: SizedBox(
        child: Stack(
          children: <Widget>[
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _posicaoCamera,
              onMapCreated: _onMapCreated,
              //myLocationEnabled: true,
              myLocationButtonEnabled: false,
              markers: _marcadores,
              //-23,559200, -46,658878
            ),
            Visibility(
              visible: _exibirCaixaEnderecoDestino,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        alignment: Alignment.centerLeft,
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(3),
                            color: Colors.white
                        ),
                        child: TextField(
                          readOnly: true,
                          textAlign: TextAlign.left,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                              prefixIcon: Container(
                                margin: const EdgeInsets.only(left: 20, right: 20),
                                width: 10,
                                height: 10,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.green,
                                ),
                              ),
                              hintText: "Meu local",
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.only(left: 10)
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 55,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        alignment: Alignment.centerLeft,
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(3),
                            color: Colors.white),
                        child: TextField(
                          controller: _controllerDestino,
                          textAlign: TextAlign.left,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            prefixIcon: Container(
                              margin: const EdgeInsets.only(left: 20, right: 20),
                              width: 10,
                              height: 10,
                              child: const Icon(
                                Icons.local_taxi,
                                color: Colors.black,
                              ),
                            ),
                            hintText: "Digite o destino",
                            border: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.transparent,
                                width: 0
                              )
                            ),
                            focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.transparent,
                                    width: 0
                                )
                            ),
                            contentPadding: const EdgeInsets.only(left: 15,),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: Padding(
                padding: Platform.isIOS
                    ? const EdgeInsets.fromLTRB(20, 10, 20, 25)
                    : const EdgeInsets.all(10),
                child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(_corBotao),
                      padding: const WidgetStatePropertyAll(EdgeInsets.fromLTRB(32, 16, 32, 16)),
                    ),
                    onPressed: () {
                      _funcaoBotao!();
                    },
                    child: Text(
                      _textoBotao,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscriptionRequisicoes?.cancel();
    _streamSubscriptionRequisicoes = null;
  }
}
