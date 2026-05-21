import 'core/flavor/bootstrap.dart';
import 'core/flavor/flavor.dart';

void main() => bootstrap(
      flavor: Flavor.prod,
      baseUrl: 'https://api.example.com',
      alipayAppId: 'YOUR_ALIPAY_APP_ID',
    );
