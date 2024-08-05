# App "Clone Uber"

## Descrição

Um aplicativo desenvolvido durante o curso de Desenvolvimento Flutter Mobile, com o objetivo de entender e aplicar conceitos fundamentais na criação de um aplicativo similar ao UBER. O projeto utiliza Firebase para gerenciamento de cadastro, autenticação de usuários, banco de dados em tempo real, proporcionando uma experiência prática e completa de desenvolvimento mobile.

## Curso

**Desenvolvimento Android e IOS com Flutter - Crie 15 Apps**

[Link para o curso na Udemy](https://www.udemy.com/course/desenvolvimento-android-e-ios-com-flutter/?couponCode=MCLARENT71824)

## Status do Projeto

- **Concluído:** 12/10/2021
- **Atualizado:** 30/07/2024

## Tecnologias Utilizadas

![Flutter](https://img.shields.io/badge/Flutter-3.22.2-blue)
![Dart](https://img.shields.io/badge/Dart-3.4.3-blue)
![Firebase Core](https://img.shields.io/badge/Firebase_Core-^3.2.0-orange)
![Firebase Firestore](https://img.shields.io/badge/Firebase_Firestore-^5.1.0-orange)
![Firebase Auth](https://img.shields.io/badge/Firebase_Auth-^5.1.2-orange)
![Google Maps Flutter](https://img.shields.io/badge/google_maps_flutter-^2.7.0-green?logo=google-maps)
![Geolocator](https://img.shields.io/badge/geolocator-^12.0.0-green)
![Geocoding](https://img.shields.io/badge/geocoding-^2.0.0-green)

## Funcionalidades

- Tela de login
- Tela de cadastro (Passageiro/Motorista)
- Tela de solicitar viagem (Passageiro)
- Tela de confirmar solicitação de viagem (Passageiro)
- Tela visualizar solicitações de viagens (Motorista)
- Tela aceitar viagem (Motorista)
- Tela de mapa com localização atual (Passageiro)

## Instalação

Siga os passos abaixo para rodar o projeto localmente:

1. Clone o repositório:
    ```sh
    git clone https://github.com/rafaelleonan/app-flutter-clone-uber.git
    ```
2. Navegue até o diretório do projeto:
    ```sh
    cd app-flutter-clone-uber
    ```
3. Instale as dependências:
    ```sh
    flutter pub get
    ```
4. Configure o Firebase para o seu projeto:
    - Siga as instruções no [Firebase Console](https://console.firebase.google.com/)
    - Adicione os arquivos de configuração `google-services.json` (Android) e `GoogleService-Info.plist` (iOS)

5. Execute o aplicativo:
    ```sh
    flutter run
    ```

## Telas
<p>
  <img src="assets/images/simulator_screenshot_iphone13_ios16_4_tela_login.png" alt="Tela Login" width="200"/>
  <img src="assets/images/simulator_screenshot_iphone13_ios16_4_tela_permissao_localizacao.png" alt="Tela de permissão localização" width="200"/>
  <img src="assets/images/simulator_screenshot_iphone13_ios16_4_tela_cadastro.png" alt="Tela Cadastro" width="200"/>
  <img src="assets/images/simulator_screenshot_iphone13_ios16_4_tela_botao_sair.png" alt="Botão de sair" width="200"/>
  <img src="assets/images/simulator_screenshot_iphone13_ios16_4_tela_chamar_uber.png" alt="Tela chamar uber" width="200"/>
  <img src="assets/images/simulator_screenshot_iphone13_ios16_4_tela_aceitar_corrida.png" alt="Tela aceitar corrida" width="200"/>
  <img src="assets/images/simulator_screenshot_iphone13_ios16_4_tela_painel_motorista.png" alt="Tela painel motorista" width="200"/>
  <img src="assets/images/simulator_screenshot_iphone13_ios16_4_tela_solicitacoes_de_viagens.png" alt="Tela solicitações de viagens" width="200"/>
  <img src="assets/images/simulator_screenshot_iphone13_ios16_4_tela_confirmar_corrida.png" alt="Tela painel motorista" width="200"/>
  <img src="assets/images/simulator_screenshot_iphone13_ios16_4_tela_cancelar_solicitacao.png" alt="Tela painel motorista" width="200"/>
 </p>