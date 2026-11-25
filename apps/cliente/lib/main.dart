import 'package:chef_core/chef_core.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';

/// Endereço da API. Troque ao rodar:
///   flutter run --dart-define=API_URL=http://192.168.0.10:8080
/// O padrão 10.0.2.2 é o "localhost" do PC visto de dentro do emulador Android.
const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');

void main() {
  runApp(ClienteApp(api: ChefApi(baseUrl: apiUrl)));
}
