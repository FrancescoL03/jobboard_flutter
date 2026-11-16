import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import 'dart:typed_data';

class JobApi {
  // Indirizzo del server Dart sul Mac
  static const String baseUrl = 'http://172.20.10.14:8080';

  static const Map<String, String> headersJson = {
    'Content-Type': 'application/json; charset=utf-8',
  };

  // Controlla la risposta del server
  static dynamic controllaRisposta(http.Response risposta) {
    final dati = jsonDecode(utf8.decode(risposta.bodyBytes));

    if (risposta.statusCode >= 400) {
      if (dati is Map && dati['errore'] is String) {
        throw Exception(dati['errore']);
      }

      throw Exception('Errore del server');
    }

    return dati;
  }

  // Recupera la bacheca pubblica
  static Future<List<Map<String, dynamic>>> elencoAnnunci() async {
    final risposta = await http.get(Uri.parse('$baseUrl/api/annunci'));

    final dati = controllaRisposta(risposta) as List;

    return dati
        .map((elemento) => Map<String, dynamic>.from(elemento as Map))
        .toList();
  }

  // Registra una nuova azienda
  static Future<void> registraAzienda(
    String nome,
    String email,
    String password,
  ) async {
    final risposta = await http.post(
      Uri.parse('$baseUrl/api/aziende'),
      headers: headersJson,
      body: jsonEncode({'nome': nome, 'email': email, 'password': password}),
    );

    controllaRisposta(risposta);
  }

  // Effettua il login aziendale
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final risposta = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: headersJson,
      body: jsonEncode({'email': email, 'password': password}),
    );

    return Map<String, dynamic>.from(controllaRisposta(risposta) as Map);
  }

  // Pubblica un annuncio
  static Future<void> pubblicaAnnuncio(
    String token,
    String titolo,
    String descrizione,
  ) async {
    final risposta = await http.post(
      Uri.parse('$baseUrl/api/annunci'),
      headers: {...headersJson, 'Authorization': 'Bearer $token'},
      body: jsonEncode({'titolo': titolo, 'descrizione': descrizione}),
    );

    controllaRisposta(risposta);
  }

  // R6: invio di una candidatura con curriculum
  static Future<void> inviaCandidatura(
    int annuncioId,
    String nome,
    String cognome,
    String email,
    PlatformFile pdf,
  ) async {
    final url = Uri.parse('$baseUrl/api/annunci/$annuncioId/candidature');

    // Richiesta che contiene sia campi testuali sia un file
    final richiesta = http.MultipartRequest('POST', url);

    richiesta.fields['nome'] = nome;
    richiesta.fields['cognome'] = cognome;
    richiesta.fields['email'] = email;

    // Leggiamo il PDF selezionato dall'iPhone
    final bytes = await pdf.readAsBytes();

    richiesta.files.add(
      http.MultipartFile.fromBytes('curriculum', bytes, filename: pdf.name),
    );

    // Inviamo i dati e controlliamo la risposta
    final risposta = await http.Response.fromStream(await richiesta.send());

    controllaRisposta(risposta);
  }

  // S3: recupera gli annunci della propria azienda
  static Future<List<Map<String, dynamic>>> annunciAzienda(String token) async {
    final risposta = await http.get(
      Uri.parse('$baseUrl/api/me/annunci'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final dati = controllaRisposta(risposta) as List;

    return dati.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // S3: recupera le candidature di un annuncio
  static Future<List<Map<String, dynamic>>> candidatureAnnuncio(
    String token,
    int annuncioId,
  ) async {
    final risposta = await http.get(
      Uri.parse('$baseUrl/api/annunci/$annuncioId/candidature'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final dati = controllaRisposta(risposta) as List;

    return dati.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // S3: scarica un PDF con autorizzazione
  static Future<Uint8List> scaricaCurriculum(
    String token,
    int candidaturaId,
  ) async {
    final risposta = await http.get(
      Uri.parse('$baseUrl/api/candidature/$candidaturaId/curriculum'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (risposta.statusCode != 200) {
      controllaRisposta(risposta);
      throw Exception('Impossibile scaricare il curriculum');
    }

    return risposta.bodyBytes;
  }

  // S3: effettua il logout
  static Future<void> logout(String token) async {
    final risposta = await http.post(
      Uri.parse('$baseUrl/api/logout'),
      headers: {'Authorization': 'Bearer $token'},
    );

    controllaRisposta(risposta);
  }
}
