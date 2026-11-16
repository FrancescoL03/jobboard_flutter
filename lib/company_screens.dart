import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'job_api.dart';

// SCHERMATA CANDIDATURE RICEVUTE
class CandidatureScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> annuncio;

  const CandidatureScreen({
    super.key,
    required this.token,
    required this.annuncio,
  });

  @override
  State<CandidatureScreen> createState() => _CandidatureScreenState();
}

class _CandidatureScreenState extends State<CandidatureScreen> {
  late Future<List<Map<String, dynamic>>> candidature;

  bool aperturaPdf = false;

  @override
  void initState() {
    super.initState();

    candidature = JobApi.candidatureAnnuncio(
      widget.token,
      widget.annuncio['id'] as int,
    );
  }

  void mostraErrore(Object errore) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errore.toString().replaceFirst('Exception: ', '')),
      ),
    );
  }

  // Scarica e apre il curriculum selezionato
  Future<void> apriCurriculum(Map<String, dynamic> candidato) async {
    if (aperturaPdf) return;

    setState(() {
      aperturaPdf = true;
    });

    try {
      // Il server controlla che il token sia autorizzato
      final bytes = await JobApi.scaricaCurriculum(
        widget.token,
        candidato['id'] as int,
      );

      // Salviamo temporaneamente il PDF sull'iPhone
      final cartella = await getTemporaryDirectory();

      final file = File('${cartella.path}/jobboard_cv_${candidato['id']}.pdf');

      await file.writeAsBytes(bytes, flush: true);

      // Apriamo il PDF tramite iOS
      final risultato = await OpenFilex.open(file.path);

      if (risultato.type != ResultType.done) {
        throw Exception(risultato.message);
      }
    } catch (e) {
      if (!mounted) return;
      mostraErrore(e);
    } finally {
      if (mounted) {
        setState(() {
          aperturaPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Candidature ricevute')),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: candidature,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Errore nel caricamento:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final lista = snapshot.data ?? [];

          if (lista.isEmpty) {
            return const Center(
              child: Text(
                'Nessuna candidatura ricevuta',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final candidato = lista[index];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),

                        title: Text(
                          '${candidato['nome']} '
                          '${candidato['cognome']}',
                        ),

                        subtitle: Text(candidato['email'] as String),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Curriculum: '
                          '${candidato['curriculumNome']}',
                        ),
                      ),

                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: aperturaPdf
                              ? null
                              : () => apriCurriculum(candidato),

                          icon: const Icon(Icons.picture_as_pdf),

                          label: const Text('Apri curriculum'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
