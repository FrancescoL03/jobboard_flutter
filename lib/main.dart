
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JobBoard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String messaggio = 'Premi il pulsante per contattare il server';
  bool caricamento = false;

  Future<void> contattaServer() async {
    setState(() {
      caricamento = true;
      messaggio = 'Connessione in corso...';
    });

    try {
      final url = Uri.parse('http://192.168.1.10:8080');

      final risposta = await http.get(url);

      if (!mounted) return;

      setState(() {
        if (risposta.statusCode == 200) {
          messaggio = risposta.body;
        } else {
          messaggio = 'Errore HTTP: ${risposta.statusCode}';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        messaggio = 'Impossibile contattare il server: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          caricamento = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JobBoard'),
        centerTitle: true,
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_outlined,
                size: 70,
                color: Colors.blue,
              ),

              const SizedBox(height: 24),

              Text(
                messaggio,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: caricamento ? null : contattaServer,
                child: const Text('Contatta server'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
