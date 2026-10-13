import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'BRIDGEFY_API_KEY', obfuscate: true)
  static final String bridgefyApiKey = _Env.bridgefyApiKey;
}
