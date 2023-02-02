import 'package:fetch_client/fetch_client.dart';
import 'package:http/http.dart';


void main() async {
  final client = FetchClient(
    mode: RequestMode.cors,
    redirectPolicy: RedirectPolicy.probeHead, // or RedirectPolicy.probe
  );
  final uri = Uri.https('jsonplaceholder.typicode.com', 'guide');
  final response = await client.send(
    Request('GET', uri)..followRedirects = false,
  );

  print(response.headers['location']);
}
