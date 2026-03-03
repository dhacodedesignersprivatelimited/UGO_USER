import 'package:http/http.dart';

import 'http_client.dart';

Future<StreamedResponse> getStreamedResponse(Request request) =>
    TimeoutHttpClient.instance.send(request);
