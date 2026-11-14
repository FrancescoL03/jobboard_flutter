import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'job_api.dart';

// --------------------------------------------------
// DETTAGLIO ANNUNCIO
// --------------------------------------------------

class DettaglioAnnuncioScreen extends StatefulWidget {
  final Map<String, dynamic> annuncio;

  const DettaglioAnnuncioScreen({super.key, required this.annuncio});

  @override
  State<DettaglioAnnuncioScreen> createState() =>
      _DettaglioAnnuncioScreenState();
}

class _DettaglioAnnuncioScreenState extends State<DettaglioAnnuncioScreen> {
  Future<void> apriCandidatura() async {
    final inviata = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CandidaturaScreen(annuncioId: widget.annuncio['id'] as int),
      ),
    );

    if (!mounted) return;

    if (inviata == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Candidatura inviata con successo!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final annuncio = widget.annuncio;

    return Scaffold(
      appBar: AppBar(title: const Text('Dettaglio annuncio')),

      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.work_outline, size: 64, color: Colors.blue),

          const SizedBox(height: 20),

          Text(
            annuncio['titolo'] as String,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Text(
            'Azienda: ${annuncio['aziendaNome']}',
            style: const TextStyle(fontSize: 17),
          ),

          const SizedBox(height: 24),

          const Text(
            'Descrizione',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Text(
            annuncio['descrizione'] as String,
            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: apriCandidatura,
            icon: const Icon(Icons.send),
            label: const Text('Candidati'),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// FORM DI CANDIDATURA
// --------------------------------------------------

class CandidaturaScreen extends StatefulWidget {
  final int annuncioId;

  const CandidaturaScreen({super.key, required this.annuncioId});

  @override
  State<CandidaturaScreen> createState() => _CandidaturaScreenState();
}

class _CandidaturaScreenState extends State<CandidaturaScreen> {
  final nome = TextEditingController();
  final cognome = TextEditingController();
  final email = TextEditingController();

  PlatformFile? curriculum;
  bool caricamento = false;

  @override
  void dispose() {
    nome.dispose();
    cognome.dispose();
    email.dispose();
    super.dispose();
  }

  void mostraErrore(Object errore) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errore.toString().replaceFirst('Exception: ', '')),
      ),
    );
  }

  // Permette di scegliere il curriculum dall'iPhone
  Future<void> scegliCurriculum() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (!mounted || file == null) return;

      final dimensione = await file.length();

      if (!mounted) return;

      if (dimensione == null ||
          dimensione == 0 ||
          dimensione > 5 * 1024 * 1024) {
        mostraErrore('Il PDF deve essere valido e non superare 5 MB');
        return;
      }

      setState(() {
        curriculum = file;
      });
    } catch (e) {
      if (!mounted) return;
      mostraErrore(e);
    }
  }

  // Invia la candidatura al server
  Future<void> invia() async {
    if (nome.text.trim().isEmpty ||
        cognome.text.trim().isEmpty ||
        email.text.trim().isEmpty) {
      mostraErrore('Compila tutti i campi obbligatori');
      return;
    }

    if (curriculum == null) {
      mostraErrore('Seleziona un curriculum PDF');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      caricamento = true;
    });

    try {
      await JobApi.inviaCandidatura(
        widget.annuncioId,
        nome.text.trim(),
        cognome.text.trim(),
        email.text.trim(),
        curriculum!,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      mostraErrore(e);
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
      appBar: AppBar(title: const Text('Invia candidatura')),

      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'I tuoi dati',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: nome,
            decoration: const InputDecoration(
              labelText: 'Nome',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: cognome,
            decoration: const InputDecoration(
              labelText: 'Cognome',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Curriculum',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: caricamento ? null : scegliCurriculum,
            icon: const Icon(Icons.attach_file),
            label: const Text('Seleziona PDF'),
          ),

          if (curriculum != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('File selezionato: ${curriculum!.name}'),
            ),

          const SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: caricamento ? null : invia,
            icon: const Icon(Icons.send),
            label: Text(
              caricamento ? 'Invio in corso...' : 'Invia candidatura',
            ),
          ),
        ],
      ),
    );
  }
}
