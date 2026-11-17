# JobBoard - Flutter

Applicazione mobile Flutter per la pubblicazione di annunci di lavoro e la gestione delle candidature.

## Avvio dell'applicazione

Avviare prima il server Dart (`jobboard_backend`).

Dalla cartella `jobboard_flutter` eseguire:

```bash
flutter pub get
flutter run
```

## Collegamento al server

Il Mac e l'iPhone devono essere collegati alla stessa rete Wi-Fi.

Per ottenere l'indirizzo IP locale del Mac, eseguire nel terminale:

```bash
ipconfig getifaddr en0
```

Aprire il file `lib/job_api.dart` e aggiornare la variabile `baseUrl` con l'indirizzo ottenuto, aggiungendo la porta `8080`.

Esempio:

```dart
static const String baseUrl = 'http://192.168.1.10:8080';
```

L'indirizzo IP potrebbe cambiare quando si utilizza una rete Wi-Fi diversa.
