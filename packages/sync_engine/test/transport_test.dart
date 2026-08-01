import 'package:core/core.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

void main() {
  test('CriticalPayload SMS encoding fits compact format', () {
    final payload = CriticalPayload(
      clientReportId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      latitude: -12.0464,
      longitude: -77.0428,
      priority: 1,
      disasterType: DisasterType.landslide,
      evidenceHash: 'deadbeefcafebabe',
    );
    final sms = payload.toSmsMessage();
    expect(sms.startsWith('AYNI|v1|'), isTrue);
    expect(sms.split('|').length, 8);
    expect(sms.length, lessThan(140));
  });

  test('TransportRouter prefers full-capable transport', () async {
    final http = _FakeTransport(
      SyncChannel.http,
      const TransportCapability(
        canSendCritical: true,
        canSendFull: true,
        channel: SyncChannel.http,
      ),
    );
    final sms = _FakeTransport(
      SyncChannel.sms,
      const TransportCapability(
        canSendCritical: true,
        canSendFull: false,
        channel: SyncChannel.sms,
      ),
    );
    final router = TransportRouter([http, sms]);
    final cap = await router.probeBest();
    expect(cap.channel, SyncChannel.http);
    expect(cap.canSendFull, isTrue);
  });
}

class _FakeTransport implements SyncTransport {
  _FakeTransport(this.channel, this._cap);

  @override
  final SyncChannel channel;
  final TransportCapability _cap;

  @override
  Future<TransportCapability> probe() async => _cap;

  @override
  Future<SyncResult> sendCriticalPayload(CriticalPayload payload) async =>
      SyncResult(success: true, channel: channel);

  @override
  Future<SyncResult> sendFullPayload(FullPayload payload) async =>
      SyncResult(success: true, channel: channel);
}
