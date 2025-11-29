import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'service.dart';

class EntregaPage extends StatefulWidget {
  final int agenteId;
  final int paqueteId;
  final String direccion;
  const EntregaPage({
    super.key,
    required this.agenteId,
    required this.paqueteId,
    required this.direccion,
  });

  @override
  State<EntregaPage> createState() => _EntregaPageState();
}

class _EntregaPageState extends State<EntregaPage> {
  final picker = ImagePicker();
  File? fotoFile;
  Uint8List? webBytes;
  XFile? pickedFile;
  double? lat, lon;
  bool sending = false;
  GoogleMapController? mapController;
  LatLng? marker;
  final api = ApiService();

  pickImage() async {
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
    );
    if (picked == null) return;
    pickedFile = picked;
    if (kIsWeb) {
      webBytes = await picked.readAsBytes();
    } else {
      fotoFile = File(picked.path);
    }
    setState(() {});
  }

  getLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Activa el GPS')));
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de ubicación denegado')),
      );
      return;
    }

    final p = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    lat = p.latitude;
    lon = p.longitude;
    marker = LatLng(lat!, lon!);
    mapController?.animateCamera(CameraUpdate.newLatLngZoom(marker!, 17));
    setState(() {});
  }

  send() async {
    if ((fotoFile == null && webBytes == null) || lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto y ubicación requeridas')),
      );
      return;
    }

    setState(() => sending = true);

    try {
      Map<String, dynamic> resp;

      if (kIsWeb) {
        resp = await api.enviarEntregaWeb(
          paqueteId: widget.paqueteId,
          agenteId: widget.agenteId,
          lat: lat!,
          lon: lon!,
          fotoBytes: webBytes!,
          filename: pickedFile!.name,
        );
      } else {
        resp = await api.enviarEntrega(
          paqueteId: widget.paqueteId,
          agenteId: widget.agenteId,
          lat: lat!,
          lon: lon!,
          foto: fotoFile!,
        );
      }

      if (resp['statusCode'] == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Entrega registrada ✔️')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${resp['body']}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => sending = false);
    }
  }

  Widget fotoPreview() {
    if (webBytes != null)
      return Image.memory(webBytes!, height: 200, fit: BoxFit.cover);
    if (fotoFile != null)
      return Image.file(fotoFile!, height: 200, fit: BoxFit.cover);
    return const SizedBox(height: 200, child: Center(child: Text('Sin foto')));
  }

  @override
  Widget build(BuildContext context) {
    final initial = marker ?? const LatLng(19.432608, -99.133209);

    return Scaffold(
      appBar: AppBar(title: Text('Entrega #${widget.paqueteId}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(widget.direccion, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            fotoPreview(),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Foto'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: getLocation,
                  icon: const Icon(Icons.gps_fixed),
                  label: const Text('Obtener GPS'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initial,
                  zoom: 12,
                ),
                onMapCreated: (c) => mapController = c,
                markers: marker == null
                    ? {}
                    : {
                        Marker(
                          markerId: const MarkerId('m1'),
                          position: marker!,
                        ),
                      },
                onTap: (p) {
                  setState(() {
                    marker = p;
                    lat = p.latitude;
                    lon = p.longitude;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(lat == null ? 'Lat: -' : 'Lat: ${lat!.toStringAsFixed(6)}'),
            Text(lon == null ? 'Lon: -' : 'Lon: ${lon!.toStringAsFixed(6)}'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: sending ? null : send,
              icon: sending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.send),
              label: const Text('Paquete entregado'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
