library default_connector;

import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'dart:convert';

class DefaultConnector {
  static final DefaultConnector _instance = DefaultConnector._internal();

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-central1',
    'default',
    'flut_test',
  );

  final FirebaseDataConnect dataConnect;

  factory DefaultConnector() {
    return _instance;
  }

  DefaultConnector._internal()
      : dataConnect = FirebaseDataConnect.instanceFor(
      connectorConfig: connectorConfig,
      sdkType: CallerSDKType.generated);

  static DefaultConnector get instance => _instance;
}
