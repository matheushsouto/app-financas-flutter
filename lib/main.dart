import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'firebase_options.dart';

/// Ponto de entrada do app.
///
/// Tudo o que precisa acontecer **antes** da primeira tela aparecer mora aqui:
/// inicialização de locale, Firebase, orientação de tela, etc. A árvore de
/// widgets em si fica em `app.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega os símbolos de data em português — sem isso, `DateFormat(..., 'pt_BR')`
  // lança exceção em tempo de execução.
  await initializeDateFormatting('pt_BR');

  await Firebase.initializeApp(options: firebaseOptions);

  runApp(const GuiaFinanceiroApp());
}

