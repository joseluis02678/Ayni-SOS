import 'package:ai_engine/ai_engine.dart';
import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:flutter/foundation.dart';
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

  final runtime = await _buildGemmaRuntime();
  final agent = EmergencyAgent(runtime);
  final modelPath = await resolveGemmaModelPath();
  await agent.warmUp(
    modelPath: modelPath ?? 'models/gemma-4-E2B-it.litertlm',
  );

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

Future<GemmaRuntime> _buildGemmaRuntime() async {
  final heuristic = HeuristicRuntime();
  final forceHeuristic = const bool.fromEnvironment(
    'FORCE_HEURISTIC_AI',
    defaultValue: false,
  );
  if (forceHeuristic || kIsWeb) {
    return heuristic;
  }

  final modelPath = await resolveGemmaModelPath();
  if (modelPath == null || defaultTargetPlatform != TargetPlatform.android) {
    return heuristic;
  }

  return FallbackGemmaRuntime(
    primary: LiteRtGemmaRuntime(),
    fallback: heuristic,
  );
}
