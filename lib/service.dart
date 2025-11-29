import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

// URL base del backend
const String backendBase = 'http://127.0.0.1:51499';

class ApiService {
  String get baseUrl => backendBase;

  // LOGIN
  Future<Map<String, dynamic>> login(String usuario, String password) async {
    final uri = Uri.parse('$baseUrl/login/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'usuario': usuario, 'password': password},
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  // LISTAR PAQUETES
  Future<http.Response> getPaquetes(int agenteId) async {
    final uri = Uri.parse('$baseUrl/paquetes/$agenteId');
    return await http.get(uri);
  }

  // ENVIAR ENTREGA (Mobile)
  Future<Map<String, dynamic>> enviarEntrega({
    required int paqueteId,
    required int agenteId,
    required double lat,
    required double lon,
    required File foto,
  }) async {
    final uri = Uri.parse('$baseUrl/entregar/');
    var request = http.MultipartRequest('POST', uri);
    request.fields['paquete_id'] = paqueteId.toString();
    request.fields['agente_id'] = agenteId.toString();
    request.fields['lat'] = lat.toString();
    request.fields['lon'] = lon.toString();
    request.files.add(await http.MultipartFile.fromPath('file', foto.path));
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    return {'statusCode': streamed.statusCode, 'body': body};
  }

  // ENVIAR ENTREGA (Web)
  Future<Map<String, dynamic>> enviarEntregaWeb({
    required int paqueteId,
    required int agenteId,
    required double lat,
    required double lon,
    required Uint8List fotoBytes,
    required String filename,
  }) async {
    final uri = Uri.parse('$baseUrl/entregar/');
    var request = http.MultipartRequest('POST', uri);
    request.fields['paquete_id'] = paqueteId.toString();
    request.fields['agente_id'] = agenteId.toString();
    request.fields['lat'] = lat.toString();
    request.fields['lon'] = lon.toString();
    request.files.add(
      http.MultipartFile.fromBytes('file', fotoBytes, filename: filename),
    );
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    return {'statusCode': streamed.statusCode, 'body': body};
  }

  // CREAR AGENTE
  Future<Map<String, dynamic>> crearAgente(
    String usuario,
    String password,
  ) async {
    final uri = Uri.parse('$baseUrl/crear_agente/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'usuario': usuario, 'password': password},
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  // CREAR PAQUETE
  Future<Map<String, dynamic>> crearPaquete(
    String destinatario,
    String direccion,
    int agenteId,
  ) async {
    final uri = Uri.parse('$baseUrl/crear_paquete/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'destinatario': destinatario,
        'direccion': direccion,
        'agente_id': agenteId.toString(),
      },
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }
}
