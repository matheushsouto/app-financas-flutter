# Guia Financeiro

Projeto didático de Desenvolvimento Mobile — Engenharia de Software, UniGuairacá.

Um app de controle financeiro pessoal: o usuário registra suas **receitas**,
cadastra suas **contas a pagar** e acompanha o saldo do mês. A estrutura deste
repositório já está pronta; as telas e as regras serão construídas em aula.

---

## Como rodar

Este repositório traz apenas o código Dart. As pastas de plataforma
(`android/`, `ios/`) são geradas pelo próprio Flutter — rode uma vez, dentro da
pasta do projeto:

```bash
flutter create --platforms=android,ios \
  --project-name guia_financeiro \
  --org br.edu.guairaca .
```

Depois:

```bash
flutter pub get
flutter run
```

O app sobe na tela de login com um marcador indicando o que falta construir.
A navegação entre as abas já funciona.

> Ainda não tem Flutter instalado? Use a versão **3.35.x** (Dart 3.9), que é a
> exigida em `pubspec.yaml` (`sdk: ^3.9.0`).

### Ativando o Firebase

O Firebase já está declarado nas dependências, mas a inicialização está
comentada — assim o projeto compila antes de configurarmos o backend. Como o
app é testado pelo Chrome (`flutter run -d chrome`), a configuração é feita
inteiramente pelo Console do Firebase, copiando e colando valores — sem
instalar CLI nem fazer login pelo terminal:

1. Acesse [console.firebase.google.com](https://console.firebase.google.com)
   e crie um projeto (pode desativar o Google Analytics).
2. Na tela inicial do projeto, clique no ícone `</>` ("Web") para registrar
   um app Web. Dê qualquer apelido; não marque Firebase Hosting.
3. O console mostra um bloco `firebaseConfig` com seis valores
   (`apiKey`, `authDomain`, `projectId`, `storageBucket`,
   `messagingSenderId`, `appId`).
4. Menu lateral → **Compilação → Authentication** → "Vamos começar" → ative
   o provedor **E-mail/senha**.
5. Menu lateral → **Compilação → Firestore Database** → "Criar banco de
   dados" (modo produção). Depois publique o conteúdo de `firestore.rules`
   em **Firestore Database → Regras**.
6. Copie `lib/firebase_options.example.dart` para `lib/firebase_options.dart`
   e cole os seis valores do passo 3.
7. Descomente o bloco marcado com `TODO(aula-firebase)` em `lib/main.dart`
   (o import de `firebase_core`, o de `firebase_options.dart` e a chamada de
   `Firebase.initializeApp`).

Cada aluno cria o **seu próprio** projeto Firebase — `firebase_options.dart`
está no `.gitignore` e nunca deve ser commitado.

---

## Estrutura de pastas

A organização segue uma **arquitetura em camadas** (layered): o código é
separado pelo *papel* que cada arquivo cumpre, não pela tela a que pertence.

```
lib/
├── main.dart                  # ponto de entrada: inicializações
├── app.dart                   # widget raiz: tema + rotas
│
├── core/                      # fundação do app — não conhece nenhuma feature
│   ├── constants/             # textos fixos da interface
│   ├── routes/                # nomes das rotas e configuração do go_router
│   ├── theme/                 # cores, espaçamentos, tipografia e ThemeData
│   └── utils/                 # formatação (R$, datas) e validações
│
├── models/                    # as entidades: Income, Bill, AppUser…
├── services/                  # acesso a dados: Firebase Auth e Firestore
│
├── screens/                   # uma pasta por área do app
│   ├── auth/                  # login e cadastro
│   ├── home/                  # resumo do mês
│   ├── incomes/               # receitas: lista e formulário
│   ├── bills/                 # contas a pagar: lista e formulário
│   └── shell/                 # casca com a barra de navegação inferior
│
└── widgets/                   # componentes reutilizáveis entre telas
```

### A regra que sustenta tudo

O fluxo de dependência é de mão única:

```
screens  →  services  →  models
   ↓                        ↑
widgets  ──────→  core  ────┘
```

Na prática, isso significa que:

- **`models/` não importa Flutter.** Um model só descreve dados.
- **`services/` não importa widgets.** Ele devolve models, nunca telas.
- **`screens/` nunca chama o Firebase direto.** Sempre por um service.
- **`core/` não importa nada de `screens/` ou `services/`.**

Quando alguém quebra uma dessas regras, o app continua funcionando — e é
justamente por isso que elas precisam ser combinadas desde o começo.

---

## O que já está pronto

| Área | O que existe |
|------|--------------|
| Tema | Paleta, tipografia, espaçamentos e `ThemeData` completo, tirados do wireframe |
| Navegação | `go_router` com todas as rotas do wireframe e barra inferior com estado por aba |
| Utilitários | `Formatters` (R$ e datas em pt-BR) e `Validators` (e-mail, senha, valor) |
| Componentes | `AppTextField`, `AppBadge`, `SectionHeader`, `EmptyState` |
| Telas | Sete telas criadas como marcadores, cada uma listando o que será construído |
| Qualidade | `analysis_options.yaml` com lints mais rígidos que o padrão |

## O que vamos construir juntos

1. Models de receita e conta a pagar
2. Autenticação com Firebase (login, cadastro, logout)
3. Redirecionamento de rotas conforme o usuário está logado ou não
4. CRUD de receitas no Firestore
5. CRUD de contas a pagar, com marcação de pago e contas recorrentes
6. Tela inicial: saldo do mês, próximos vencimentos e a "dica do guia"
7. Testes de widget e de unidade

---

## Rotas

| Caminho          | Nome constante            | Tela                      |
|------------------|---------------------------|---------------------------|
| `/login`         | `AppRoutes.signIn`        | `SignInScreen`            |
| `/cadastro`      | `AppRoutes.signUp`        | `SignUpScreen`            |
| `/inicio`        | `AppRoutes.home`          | `HomeScreen`              |
| `/receitas`      | `AppRoutes.incomes`       | `IncomesScreen`           |
| `/receitas/nova` | `AppRoutes.incomeForm`    | `IncomeFormScreen`        |
| `/contas`        | `AppRoutes.bills`         | `BillsScreen`             |
| `/contas/nova`   | `AppRoutes.billForm`      | `BillFormScreen`          |

Navegue sempre pelo nome, nunca pelo caminho escrito à mão:

```dart
context.goNamed(AppRoutes.incomeForm);
```

---

## Convenções de código

- Arquivos e pastas em `snake_case`; classes em `PascalCase`.
- Um widget público por arquivo, com o nome do arquivo.
- Widgets privados de uma tela ficam no mesmo arquivo, prefixados com `_`.
- Widget usado por mais de uma tela sobe para `lib/widgets/`.
- Nada de cor, tamanho ou texto "solto" dentro das telas: use `core/`.

Antes de cada entrega:

```bash
dart format .
flutter analyze
flutter test
```
