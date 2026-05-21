import 'core/flavor/bootstrap.dart';
import 'core/flavor/flavor.dart';

void main() => bootstrap(
      flavor: Flavor.dev,
      baseUrl: 'https://dev-api.example.com',
    );
