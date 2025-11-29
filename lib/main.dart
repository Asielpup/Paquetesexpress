import 'package:flutter/material.dart';
import 'service.dart';
import 'entrega.dart';
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Paquexpress',
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final api = ApiService();
  bool _loading = false;

  login() async {
    final usuario = _userCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (usuario.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario y contraseña requeridos')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final resp = await api.login(usuario, password);
      final body = jsonDecode(resp['body']);
      if (resp['statusCode'] == 200 && body['status'] == 'ok') {
        final agenteId = body['agente_id'];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PaquetesPage(agenteId: agenteId)),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Credenciales inválidas')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paquexpress - Login')),
      body: Center(
        child: SizedBox(
          width: 420,
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(labelText: 'Usuario'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passCtrl,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loading ? null : login,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Entrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PaquetesPage extends StatefulWidget {
  final int agenteId;
  const PaquetesPage({super.key, required this.agenteId});
  @override
  State<PaquetesPage> createState() => _PaquetesPageState();
}

class _PaquetesPageState extends State<PaquetesPage> {
  final api = ApiService();
  List paquetes = [];
  bool loading = true;

  final _destCtrl = TextEditingController();
  final _dirCtrl = TextEditingController();
  bool creandoPaquete = false;

  @override
  void initState() {
    super.initState();
    loadPaquetes();
  }

  loadPaquetes() async {
    setState(() => loading = true);
    try {
      final resp = await api.getPaquetes(widget.agenteId);
      if (resp.statusCode == 200) {
        paquetes = List.from(jsonDecode(resp.body));
      } else {
        paquetes = [];
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${resp.statusCode}')));
      }
    } catch (e) {
      paquetes = [];
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  openEntrega(Map paquete) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EntregaPage(
          agenteId: widget.agenteId,
          paqueteId: paquete['id'],
          direccion: paquete['direccion'] ?? '',
        ),
      ),
    );

    if (resultado == true) {
      loadPaquetes();
    }
  }

  crearPaquete() async {
    final destinatario = _destCtrl.text.trim();
    final direccion = _dirCtrl.text.trim();

    if (destinatario.isEmpty || direccion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destinatario y dirección requeridos')),
      );
      return;
    }

    setState(() => creandoPaquete = true);
    try {
      final resp = await api.crearPaquete(
        destinatario,
        direccion,
        widget.agenteId,
      );
      final body = jsonDecode(resp['body']);
      if (resp['statusCode'] == 200 && body['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paquete creado correctamente')),
        );
        _destCtrl.clear();
        _dirCtrl.clear();
        loadPaquetes();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al crear paquete')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => creandoPaquete = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Paquetes - Agente ${widget.agenteId}')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const Text(
                        'Crear Paquete',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: _destCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Destinatario',
                        ),
                      ),
                      TextField(
                        controller: _dirCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: creandoPaquete ? null : crearPaquete,
                        child: creandoPaquete
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Crear Paquete'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              loading
                  ? const Center(child: CircularProgressIndicator())
                  : paquetes.isEmpty
                  ? const Center(child: Text('No hay paquetes pendientes'))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: paquetes.length,
                      itemBuilder: (_, i) {
                        final p = paquetes[i];
                        return Card(
                          child: ListTile(
                            title: Text(p['direccion'] ?? 'Sin dirección'),
                            subtitle: Text('ID: ${p['id']}'),
                            trailing: ElevatedButton(
                              onPressed: () => openEntrega(p),
                              child: const Text('Entregar'),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
