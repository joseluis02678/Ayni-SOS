import 'package:ai_engine/ai_engine.dart';
import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:geo_service/geo_service.dart';
import 'package:get_it/get_it.dart';
import 'package:mesh_transport/mesh_transport.dart';
import 'package:sync_engine/sync_engine.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies({required String apiBaseUrl}) async {
  final db = AppDatabase();
  final api = ApiClient(baseUrl: apiBaseUrl);
  final mesh = InMemoryMeshNetwork();
  await mesh.start(nodeId: 'citizen-device');

  final http = HttpTransport(api.dio);
  final sms = SmsTransport(api.dio);
  final meshTransport = MeshTransportAdapter(mesh);
  final router = TransportRouter([http, sms, meshTransport]);

  final authRepo = AuthRepositoryImpl(api, db);
  final reportRepo = ReportRepositoryImpl(db);
  final syncRepo = SyncRepositoryImpl(db, api, router, reportRepo);

  final runtime = HeuristicRuntime();
  final agent = EmergencyAgent(runtime);
  await agent.warmUp();

  getIt
    ..registerSingleton<AppDatabase>(db)
    ..registerSingleton<ApiClient>(api)
    ..registerSingleton<MeshNetworkService>(mesh)
    ..registerSingleton<TransportRouter>(router)
    ..registerSingleton<AuthRepository>(authRepo)
    ..registerSingleton<ReportRepository>(reportRepo)
    ..registerSingleton<SyncRepository>(syncRepo)
    ..registerSingleton<EmergencyAgent>(agent)
    ..registerSingleton<LocationService>(LocationService())
    ..registerSingleton(LoginUser(authRepo))
    ..registerSingleton(RegisterUser(authRepo))
    ..registerSingleton(CreateEmergencyReport(reportRepo, syncRepo));
}
