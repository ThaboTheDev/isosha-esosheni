import '../backend/backend.dart';
import '../models/safety.dart';

class SafetyRepository {
  SafetyRepository(this._b);
  final Backend _b;

  Future<Standing> standing() async {
    final res = await _b.rpc('my_standing');
    return Standing.fromJson((res as Map?)?.cast<String, dynamic>());
  }

  Future<String> submitAppeal(String sanction, String statement) async =>
      (await _b.rpc('submit_appeal', params: {
        'sanction': sanction,
        'statement': statement,
      }))
          .toString();

  Future<void> expireSanctions() => _b.rpc('expire_my_sanctions');
}
