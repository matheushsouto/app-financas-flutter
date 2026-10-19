/// Textos fixos da interface.
///
/// Centralizar as strings aqui evita texto duplicado nas telas e deixa o app
/// pronto para internacionalização mais tarde, se a turma quiser avançar
/// nesse tema.
abstract final class AppStrings {
  static const String appName = 'Guia Financeiro';
  static const String appTagline =
      'Organize suas receitas e contas em um só lugar.';
  static const String appFooter = 'Projeto didático · Engenharia de Software';

  // Navegação
  static const String tabHome = 'Início';
  static const String tabIncomes = 'Receitas';
  static const String tabBills = 'Contas';

  // Autenticação
  static const String signIn = 'Entrar';
  static const String signUp = 'Criar conta';
  static const String email = 'E-mail';
  static const String password = 'Senha';
  static const String forgotPassword = 'Esqueci minha senha';

  // Receitas
  static const String incomesTotal = 'Total recebido no mês';
  static const String incomesEntries = 'Lançamentos';
  static const String incomesEmpty =
      'Toque em + para registrar uma nova receita';

  // Mensagens genéricas
  static const String genericError =
      'Algo deu errado. Tente novamente em instantes.';
  static const String emptyList = 'Nada por aqui ainda.';
}
