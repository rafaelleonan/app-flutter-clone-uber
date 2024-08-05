class Usuario {

  String? _idUsuario;
  String? _nome;
  String? _email;
  String? _senha;
  String? _tipoUsuario;
  double? _latitude;
  double? _longitude;

  Usuario();

  double get latitude => _latitude ?? 0.0;

  set latitude(double value) {
    _latitude = value;
  }

  Map<String, dynamic> toMap(){

    Map<String, dynamic> map = {
      "idUsuario"   : idUsuario,
      "nome"        : nome,
      "email"       : email,
      "tipoUsuario" : tipoUsuario,
      "latitude"    : latitude,
      "longitude"   : longitude,
    };

    return map;
  }

  String verificaTipoUsuario(bool tipoUsuario){
    return tipoUsuario ? "motorista" : "passageiro";
  }

  String get tipoUsuario => _tipoUsuario ?? "";

  set tipoUsuario(String value) {
    _tipoUsuario = value;
  }

  String get senha => _senha ?? "";

  set senha(String value) {
    _senha = value;
  }

  String get email => _email ?? "";

  set email(String value) {
    _email = value;
  }

  String get nome => _nome ?? "";

  set nome(String value) {
    _nome = value;
  }

  String get idUsuario => _idUsuario ?? "";

  set idUsuario(String value) {
    _idUsuario = value;
  }

  double get longitude => _longitude ?? 0.0;

  set longitude(double value) {
    _longitude = value;
  }
}