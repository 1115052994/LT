import 'core/flavor/bootstrap.dart';
import 'core/flavor/flavor.dart';

void main() => bootstrap(
      flavor: Flavor.test,
      baseUrl: 'https://test-api.example.com',
    );
