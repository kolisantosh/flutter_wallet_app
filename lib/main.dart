import 'views.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbPath = await getApplicationDocumentsDirectory();
  final database = AppDatabase(join(dbPath.path, 'wallet.db'));
  await database.initDatabase();

  final userRepository = UserRepository(database);
  final walletRepository = WalletRepository(database);
  final transactionRepository = TransactionRepository(database);

  runApp(MyApp(userRepository: userRepository, walletRepository: walletRepository, transactionRepository: transactionRepository));
}

class MyApp extends StatelessWidget {
  final UserRepository userRepository;
  final WalletRepository walletRepository;
  final TransactionRepository transactionRepository;

  const MyApp({Key? key, required this.userRepository, required this.walletRepository, required this.transactionRepository})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: userRepository),
        RepositoryProvider.value(value: walletRepository),
        RepositoryProvider.value(value: transactionRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AuthBloc(userRepository: userRepository, walletRepository: walletRepository)),
          BlocProvider(create: (context) => WalletBloc(walletRepository: walletRepository, transactionRepository: transactionRepository)),
          BlocProvider(create: (context) => TransactionBloc(transactionRepository: transactionRepository)),
        ],
        child: MaterialApp(
          title: 'FinTech Wallet',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(primarySwatch: Colors.blue, visualDensity: VisualDensity.adaptivePlatformDensity),
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return const DashboardScreen();
              }
              return const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}
