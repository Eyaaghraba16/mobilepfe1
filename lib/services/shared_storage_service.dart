import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/request.dart';
import '../utils/constants.dart';
import 'database_service.dart';

/// Service pour partager les données entre les applications web et mobile
/// Utilise SharedPreferences pour stocker les données localement
class SharedStorageService {
  static const String REQUESTS_STORAGE_KEY = 'shared_requests';
  static const String LAST_SYNC_KEY = 'last_sync_timestamp';
  
  // Stream pour notifier les changements de demandes
  static final StreamController<List<Request>> _requestsStreamController = 
      StreamController<List<Request>>.broadcast();
  
  // Stream pour écouter les changements
  Stream<List<Request>> get requestsStream => _requestsStreamController.stream;
  
  // Constructeur
  SharedStorageService() {
    // Initialiser le service
    print('SharedStorageService initialisé');
  }
  
  // Libérer les ressources
  void dispose() {
    // Rien à libérer pour l'instant
  }
  
  // Charger les données depuis l'API
  Future<void> loadDataFromApi() async {
    try {
      print('Chargement des données depuis l\'API...');
      
      // Utiliser le DatabaseService pour récupérer les données directement depuis l'API
      final databaseService = DatabaseService();
      final requests = await databaseService.fetchRequests();
      
      if (requests.isNotEmpty) {
        print('${requests.length} demandes chargées depuis l\'API');
        
        // Sauvegarder les demandes dans le stockage local
        await _saveRequests(requests);
        
        // Notifier les écouteurs
        _requestsStreamController.add(requests);
        
        // Déboguer les demandes chargées
        for (var request in requests) {
          print('Demande: ${request.id}, Type: ${request.type}, Status: ${request.status}');
        }
      } else {
        print('Aucune demande récupérée depuis l\'API, utilisation des données locales');
        final localRequests = await getRequests();
        _requestsStreamController.add(localRequests);
      }
      
      // Mettre à jour le timestamp de la dernière synchronisation
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(LAST_SYNC_KEY, DateTime.now().toString());
      print('Chargement des données terminé avec succès');
    } catch (e) {
      print('Erreur lors du chargement des données depuis l\'API: $e');
      // En cas d'erreur, essayer de charger les données locales
      try {
        final localRequests = await getRequests();
        _requestsStreamController.add(localRequests);
      } catch (e) {
        print('Erreur lors du chargement des données locales: $e');
      }
    }
  }

  /// Récupérer toutes les demandes du stockage local
  Future<List<Request>> getRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? requestsJson = prefs.getString(REQUESTS_STORAGE_KEY);
      
      if (requestsJson == null || requestsJson.isEmpty) {
        // Si aucune donnée n'existe, initialiser avec des données par défaut
        final defaultRequests = _createDefaultRequests();
        await _saveRequests(defaultRequests);
        return defaultRequests;
      }
      
      final List<dynamic> requestsData = jsonDecode(requestsJson);
      return requestsData.map((item) => _convertToRequest(item)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des demandes du stockage local: $e');
      // En cas d'erreur, retourner des données par défaut
      return _createDefaultRequests();
    }
  }

  /// Récupérer une demande par son ID
  Future<Request?> getRequestById(String id) async {
    try {
      final requests = await getRequests();
      return requests.firstWhere((request) => request.id == id);
    } catch (e) {
      print('Erreur lors de la récupération de la demande $id: $e');
      return null;
    }
  }

  /// Ajouter une nouvelle demande
  Future<Request> addRequest({
    required String type,
    required String startDate,
    required String endDate,
    required String description,
    Map<String, dynamic>? details,
  }) async {
    try {
      // Générer un ID unique pour la demande
      final id = _generateRandomString(9);
      
      // Créer la nouvelle demande
      final newRequest = Request(
        id: id,
        userId: 1, // Utilisateur connecté
        type: type,
        status: 'En attente',
        startDate: startDate,
        endDate: endDate,
        description: description,
        details: details ?? {
          'traitePar': 'Non traité',
          'reponse': 'Pas de réponse'
        },
        createdAt: DateFormat('dd/MM/yyyy').format(DateTime.now()),
      );
      
      // Récupérer les demandes actuelles
      final currentRequests = await getRequests();
      
      // Ajouter la nouvelle demande
      currentRequests.add(newRequest);
      
      // Sauvegarder les demandes mises à jour
      await _saveRequests(currentRequests);
      
      // Ajouter la demande dans la base de données MySQL
      final databaseService = DatabaseService();
      final requestId = await databaseService.addRequest(newRequest);
      
      if (requestId != null) {
        print('Demande ajoutée avec succès dans la base de données MySQL avec ID: $requestId');
      } else {
        print('Erreur lors de l\'ajout de la demande dans la base de données MySQL');
      }
      
      // Notifier les écouteurs du changement
      _requestsStreamController.add(currentRequests);
      
      return newRequest;
    } catch (e) {
      print('Erreur lors de l\'ajout de la demande: $e');
      rethrow;
    }
  }

  /// Mettre à jour une demande existante
  Future<void> updateRequest(Request request) async {
    try {
      print('Mise à jour de la demande ${request.id} dans le stockage partagé');
      
      // Récupérer les demandes existantes
      final requests = await getRequests();
      
      // Trouver l'index de la demande à mettre à jour
      final index = requests.indexWhere((r) => r.id == request.id);
      
      if (index != -1) {
        // Remplacer la demande existante
        requests[index] = request;
      } else {
        // Ajouter la nouvelle demande
        requests.add(request);
      }
      
      // Sauvegarder les demandes mises à jour
      await _saveRequests(requests);
      
      // Notifier les écouteurs
      _requestsStreamController.add(requests);
    } catch (e) {
      print('Erreur lors de la mise à jour de la demande: $e');
    }
  }

  /// Supprimer une demande
  Future<bool> deleteRequest(String requestId) async {
    try {
      print('Suppression de la demande $requestId dans le stockage partagé');
      
      // Récupérer les demandes existantes
      final requests = await getRequests();
      
      // Trouver l'index de la demande à supprimer
      final index = requests.indexWhere((r) => r.id == requestId);
      
      if (index == -1) {
        print('Demande $requestId non trouvée dans le stockage local');
        return false;
      }
      
      // Vérifier que la demande est en attente
      final request = requests[index];
      if (request.status.toLowerCase() != 'en attente') {
        print('La demande $requestId n\'est pas en attente et ne peut pas être supprimée');
        return false;
      }
      
      // Supprimer la demande
      requests.removeAt(index);
      
      // Sauvegarder les demandes mises à jour
      await _saveRequests(requests);
      
      // Notifier les écouteurs
      _requestsStreamController.add(requests);
      
      print('Demande $requestId supprimée avec succès du stockage local');
      return true;
    } catch (e) {
      print('Erreur lors de la suppression de la demande: $e');
      return false;
    }
  }

  /// Mettre à jour plusieurs demandes à la fois
  Future<void> updateRequests(List<Request> newRequests) async {
    try {
      print('Mise à jour de ${newRequests.length} demandes dans le stockage partagé');
      
      // Récupérer les demandes existantes
      final existingRequests = await getRequests();
      
      // Créer une map des demandes existantes pour faciliter la recherche
      final Map<String, Request> requestsMap = {};
      for (var request in existingRequests) {
        requestsMap[request.id] = request;
      }
      
      // Mettre à jour ou ajouter les nouvelles demandes
      for (var newRequest in newRequests) {
        requestsMap[newRequest.id] = newRequest;
      }
      
      // Convertir la map en liste
      final updatedRequests = requestsMap.values.toList();
      
      // Sauvegarder les demandes mises à jour
      await _saveRequests(updatedRequests);
      
      // Notifier les écouteurs
      _requestsStreamController.add(updatedRequests);
      
      print('${updatedRequests.length} demandes mises à jour dans le stockage partagé');
    } catch (e) {
      print('Erreur lors de la mise à jour des demandes: $e');
    }
  }

  /// Sauvegarder la liste des demandes dans le stockage local
  Future<void> _saveRequests(List<Request> requests) async {
    final prefs = await SharedPreferences.getInstance();
    final requestsJson = jsonEncode(requests.map((request) => request.toJson()).toList());
    await prefs.setString(REQUESTS_STORAGE_KEY, requestsJson);
    
    // Notifier les écouteurs des changements
    _requestsStreamController.add(requests);
    
    // Enregistrer le timestamp de la dernière mise à jour
    await prefs.setString(LAST_SYNC_KEY, DateTime.now().toIso8601String());
  }

  /// Convertir un objet JSON en objet Request
  Request _convertToRequest(Map<String, dynamic> json) {
    // Si le format est celui de l'application web, le convertir
    if (json.containsKey('details') && !json.containsKey('start_date')) {
      final details = json['details'] is String 
          ? jsonDecode(json['details']) 
          : json['details'];
      
      return Request(
        id: json['id'].toString(),
        userId: 1, // ID utilisateur par défaut
        type: json['type'],
        status: json['status'],
        startDate: details['startDate'] ?? '',
        endDate: details['endDate'] ?? '',
        description: json['description'],
        details: details,
        createdAt: json['date'],
      );
    }
    
    // Sinon, utiliser le format standard de l'application mobile
    return Request.fromJson(json);
  }

  /// Générer une chaîne aléatoire pour les ID
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      List.generate(length, (index) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }
  
  /// Méthode pour créer une liste vide de demandes - Pas de données de test
  /// Les données réelles seront récupérées depuis la base de données aya_db
  List<Request> _createDefaultRequests() {
    // Ne plus utiliser de données de test, utiliser uniquement les données réelles de la base aya_db
    return [];
  }
}
