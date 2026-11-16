import 'package:flutter/material.dart';

import 'job_api.dart';
import 'candidate_screens.dart';
import 'company_screens.dart';

void main() {
  runApp(const MyApp());
}

// Mostra un errore temporaneo nella schermata corrente
void mostraErrore(BuildContext context, Object errore) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(errore.toString().replaceFirst('Exception: ', ''))),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JobBoard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --------------------------------------------------
// BACHECA PUBBLICA
// --------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> annunci;

  @override
  void initState() {
    super.initState();
    annunci = JobApi.elencoAnnunci();
  }

  void aggiornaAnnunci() {
    setState(() {
      annunci = JobApi.elencoAnnunci();
    });
  }

  // Apre il login e successivamente l'area aziendale
  Future<void> apriAreaAziendale() async {
    final login = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    if (!mounted || login == null) return;

    final pubblicato = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AreaAziendaleScreen(
          token: login['token'] as String,
          nomeAzienda: login['nome'] as String,
        ),
      ),
    );

    if (!mounted) return;

    if (pubblicato == true) {
      aggiornaAnnunci();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annuncio pubblicato con successo!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JobBoard'),
        actions: [
          IconButton(
            onPressed: aggiornaAnnunci,
            tooltip: 'Aggiorna bacheca',
            icon: const Icon(Icons.refresh),
          ),
          TextButton(
            onPressed: apriAreaAziendale,
            child: const Text('Aziende'),
          ),
        ],
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: annunci,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Impossibile caricare gli annunci.\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final lista = snapshot.data ?? [];

          if (lista.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work_outline, size: 70),
                  SizedBox(height: 16),
                  Text(
                    'Nessun annuncio disponibile',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final annuncio = lista[index];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.work_outline),

                  title: Text(annuncio['titolo'] as String),

                  subtitle: Text(
                    '${annuncio['aziendaNome']}\n'
                    '${annuncio['descrizione']}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  isThreeLine: true,

                  // Apre il dettaglio dell'annuncio selezionato
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DettaglioAnnuncioScreen(annuncio: annuncio),
                      ),
                    );
                  },

                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --------------------------------------------------
// LOGIN AZIENDALE
// --------------------------------------------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool caricamento = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> apriRegistrazione() async {
    final registrato = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RegistrazioneScreen()),
    );

    if (!mounted) return;

    if (registrato == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrazione completata! Ora accedi.')),
      );
    }
  }

  Future<void> accedi() async {
    setState(() {
      caricamento = true;
    });

    try {
      final dati = await JobApi.login(email.text, password.text);

      if (!mounted) return;

      Navigator.pop(context, dati);
    } catch (e) {
      if (!mounted) return;
      mostraErrore(context, e);
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
      appBar: AppBar(title: const Text('Accesso aziende')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.business, size: 70),
          const SizedBox(height: 24),

          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: caricamento ? null : accedi,
            child: const Text('Accedi'),
          ),

          TextButton(
            onPressed: caricamento ? null : apriRegistrazione,
            child: const Text('Non hai un account? Registrati'),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// REGISTRAZIONE AZIENDA
// --------------------------------------------------

class RegistrazioneScreen extends StatefulWidget {
  const RegistrazioneScreen({super.key});

  @override
  State<RegistrazioneScreen> createState() => _RegistrazioneScreenState();
}

class _RegistrazioneScreenState extends State<RegistrazioneScreen> {
  final nome = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  bool caricamento = false;

  @override
  void dispose() {
    nome.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> registrati() async {
    setState(() {
      caricamento = true;
    });

    try {
      await JobApi.registraAzienda(nome.text, email.text, password.text);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      mostraErrore(context, e);
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
      appBar: AppBar(title: const Text('Registrazione azienda')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: nome,
            decoration: const InputDecoration(
              labelText: 'Nome azienda',
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

          const SizedBox(height: 16),

          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password (almeno 8 caratteri)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: caricamento ? null : registrati,
            child: const Text('Crea account'),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// AREA RISERVATA AZIENDALE
// --------------------------------------------------

class AreaAziendaleScreen extends StatefulWidget {
  final String token;
  final String nomeAzienda;

  const AreaAziendaleScreen({
    super.key,
    required this.token,
    required this.nomeAzienda,
  });

  @override
  State<AreaAziendaleScreen> createState() => _AreaAziendaleScreenState();
}

class _AreaAziendaleScreenState extends State<AreaAziendaleScreen> {
  late Future<List<Map<String, dynamic>>> annunci;

  bool haPubblicato = false;
  bool logoutInCorso = false;
  bool uscitaConsentita = false;

  @override
  void initState() {
    super.initState();
    aggiornaAnnunci();
  }

  // Recupera gli annunci dell'azienda autenticata
  void aggiornaAnnunci() {
    setState(() {
      annunci = JobApi.annunciAzienda(widget.token);
    });
  }

  // Apre il form per pubblicare un nuovo annuncio
  Future<void> apriNuovoAnnuncio() async {
    final pubblicato = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NuovoAnnuncioScreen(token: widget.token),
      ),
    );

    if (!mounted) return;

    if (pubblicato == true) {
      haPubblicato = true;

      aggiornaAnnunci();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annuncio pubblicato con successo!')),
      );
    }
  }

  // Apre le candidature dell'annuncio selezionato
  void apriCandidature(Map<String, dynamic> annuncio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CandidatureScreen(token: widget.token, annuncio: annuncio),
      ),
    );
  }

  // Chiude la sessione e torna alla bacheca pubblica
  Future<void> esci() async {
    if (logoutInCorso) return;

    setState(() {
      logoutInCorso = true;
    });

    try {
      await JobApi.logout(widget.token);

      if (!mounted) return;

      // Permettiamo l'uscita solo dopo il logout
      setState(() {
        uscitaConsentita = true;
      });

      // Attendiamo che PopScope aggiorni lo stato
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context, haPubblicato);
        }
      });
    } catch (e) {
      if (!mounted) return;
      mostraErrore(context, e);
    } finally {
      if (mounted) {
        setState(() {
          logoutInCorso = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: uscitaConsentita,

      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Area aziendale'),

          actions: [
            IconButton(
              tooltip: 'Logout',
              onPressed: logoutInCorso ? null : esci,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),

        body: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Benvenuta, ${widget.nomeAzienda}!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: logoutInCorso ? null : apriNuovoAnnuncio,
                icon: const Icon(Icons.add),
                label: const Text('Pubblica un annuncio'),
              ),

              const SizedBox(height: 28),

              const Text(
                'I tuoi annunci',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: annunci,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Errore nel caricamento:\n'
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final lista = snapshot.data ?? [];

                    if (lista.isEmpty) {
                      return const Center(
                        child: Text('Non hai ancora pubblicato annunci'),
                      );
                    }

                    return ListView.builder(
                      itemCount: lista.length,
                      itemBuilder: (context, index) {
                        final annuncio = lista[index];

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.work_outline),

                            title: Text(annuncio['titolo'] as String),

                            subtitle: Text(
                              annuncio['descrizione'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            trailing: const Icon(Icons.chevron_right),

                            onTap: () {
                              apriCandidature(annuncio);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// CREAZIONE NUOVO ANNUNCIO
// --------------------------------------------------

class NuovoAnnuncioScreen extends StatefulWidget {
  final String token;

  const NuovoAnnuncioScreen({super.key, required this.token});

  @override
  State<NuovoAnnuncioScreen> createState() => _NuovoAnnuncioScreenState();
}

class _NuovoAnnuncioScreenState extends State<NuovoAnnuncioScreen> {
  final titolo = TextEditingController();
  final descrizione = TextEditingController();

  bool caricamento = false;

  @override
  void dispose() {
    titolo.dispose();
    descrizione.dispose();
    super.dispose();
  }

  Future<void> pubblica() async {
    if (titolo.text.trim().isEmpty || descrizione.text.trim().isEmpty) {
      mostraErrore(context, 'Titolo e descrizione sono obbligatori');
      return;
    }

    setState(() {
      caricamento = true;
    });

    try {
      await JobApi.pubblicaAnnuncio(
        widget.token,
        titolo.text,
        descrizione.text,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      mostraErrore(context, e);
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
      appBar: AppBar(title: const Text('Nuovo annuncio')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: titolo,
            decoration: const InputDecoration(
              labelText: 'Titolo annuncio',
              hintText: 'Es. Sviluppatore Flutter',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: descrizione,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Descrizione',
              hintText: 'Descrivi la posizione lavorativa...',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: caricamento ? null : pubblica,
            child: const Text('Pubblica annuncio'),
          ),
        ],
      ),
    );
  }
}
