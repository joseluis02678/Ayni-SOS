import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:geo_service/geo_service.dart';
import 'package:get_it/get_it.dart';
import 'package:mesh_transport/mesh_transport.dart';
import 'package:rescuer_app/presentation/dashboard/incident_cubit.dart';
import 'package:rescuer_app/presentation/dashboard/ws_client.dart';
import 'package:sync_engine/sync_engine.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies({required String apiBaseUrl}) async {
  final db = AppDatabase();
  final api = ApiClient(baseUrl: apiBaseUrl);
  final mesh = InMemoryMeshNetwork();
  await mesh.start(nodeId: 'rescuer-device');

  final http = HttpTransport(api.dio);
  final router = TransportRouter([http]);

  final authRepo = AuthRepositoryImpl(api, db);
  final reportRepo = ReportRepositoryImpl(db);
  final syncRepo = SyncRepositoryImpl(db, api, router, reportRepo);

  getIt
    ..registerSingleton<AppDatabase>(db)
    ..registerSingleton<ApiClient>(api)
    ..registerSingleton<AuthRepository>(authRepo)
    ..registerSingleton<ReportRepository>(reportRepo)
    ..registerSingleton<SyncRepository>(syncRepo)
    ..registerSingleton<LocationService>(LocationService())
    ..registerSingleton(LoginUser(authRepo))
    ..registerSingleton(RegisterUser(authRepo))
    ..registerSingleton(OfflineMapConfig())
    ..registerFactory(() => IncidentCubit(api, syncRepo, db))
    ..registerFactory(() => RescuerWsClient(api));
}
