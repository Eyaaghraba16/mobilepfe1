import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/request.dart';
import '../services/request_service.dart';
import '../services/shared_storage_service.dart';

class RequestProvider with ChangeNotifier {
  final RequestService _requestService = RequestService();
  final SharedStorageService _sharedStorage = SharedStorageService();
  
  List<Request> _requests = [];
  Request? _selectedRequest;
  bool _isLoading = false;
  String? _error;
  
  // Abonnement au stream de demandes
  StreamSubscription<List<Request>>? _requestsSubscription;
  Timer? _syncTimer;
  
  RequestProvider() {
    // Écouter les changements dans le stockage partagé
    _requestsSubscription = _sharedStorage.requestsStream.listen((requests) {
      _requests = requests;
      notifyListeners();
    });
    
    // Charger les données depuis l'API au démarrage
    _sharedStorage.loadDataFromApi();
    
    // IMPORTANT: Forcer la synchronisation avec le serveur au démarrage
    _forceSyncWithServer();
    
    // NOUVEAU: Configurer une synchronisation périodique toutes les 30 secondes
    _syncTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _forceSyncWithServer();
    });
  }
  
  // Méthode pour forcer la synchronisation avec le serveur
  Future<void> _forceSyncWithServer() async {
    try {
      print('===== SYNCHRONISATION FORCÉE AVEC LE SERVEUR =====');
      final fetchedRequests = await _requestService.fetchRequests();
      if (fetchedRequests.isNotEmpty) {
        print('${fetchedRequests.length} demandes récupérées du serveur');
        await _sharedStorage.updateRequests(fetchedRequests);
        print('Synchronisation terminée avec succès!');
      } else {
        print('Aucune demande récupérée du serveur');
      }
    } catch (e) {
      print('Erreur lors de la synchronisation forcée: $e');
    }
  }
  
  @override
  void dispose() {
    _requestsSubscription?.cancel();
    _syncTimer?.cancel(); // Annuler le timer de synchronisation
    super.dispose();
  }
  
  List<Request> get requests => _requests;
  Request? get selectedRequest => _selectedRequest;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Récupérer toutes les demandes de l'utilisateur
  Future<void> fetchUserRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Forcer la synchronisation avec le serveur
      print('Synchronisation des demandes avec le serveur...');
      final fetchedRequests = await _requestService.fetchRequests();
      
      if (fetchedRequests != null && fetchedRequests.isNotEmpty) {
        print('${fetchedRequests.length} demandes récupérées du serveur');
        // Mettre à jour le stockage partagé avec les demandes du serveur
        await _sharedStorage.updateRequests(fetchedRequests);
      } else {
        print('Aucune demande récupérée du serveur ou erreur de connexion');
      }
      
      // Charger les données depuis l'API
      await _sharedStorage.loadDataFromApi();
      
      // Récupérer les demandes depuis le stockage partagé
      _requests = await _sharedStorage.getRequests();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Créer une nouvelle demande
  Future<bool> createRequest({
    required String type,
    required String startDate,
    required String endDate,
    required String description,
    Map<String, dynamic>? details,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Utiliser le service de stockage partagé pour créer la demande
      final newRequest = await _sharedStorage.addRequest(
        type: type,
        startDate: startDate,
        endDate: endDate,
        description: description,
        details: details,
      );
      
      // La liste sera automatiquement mise à jour grâce au stream
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Récupérer les détails d'une demande
  Future<void> fetchRequestDetails(String requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _selectedRequest = await _requestService.getRequestDetails(requestId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Supprimer une demande
  Future<bool> deleteRequest(String requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Vérifier que la demande existe et qu'elle est en attente
      final request = _requests.firstWhere(
        (req) => req.id == requestId,
        orElse: () => throw Exception('Demande non trouvée'),
      );
      
      if (request.status.toLowerCase() != 'en attente') {
        throw Exception('Seules les demandes en attente peuvent être supprimées');
      }
      
      // Utiliser le service de requêtes pour supprimer la demande
      final success = await _requestService.deleteRequest(requestId);
      
      if (success) {
        // Supprimer la demande du stockage local
        await _sharedStorage.deleteRequest(requestId);
        
        // Forcer une synchronisation avec le serveur
        _forceSyncWithServer();
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Erreur lors de la suppression de la demande');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Sélectionner une demande existante
  void selectRequest(Request request) {
    _selectedRequest = request;
    notifyListeners();
  }
  
  // Effacer la demande sélectionnée
  void clearSelectedRequest() {
    _selectedRequest = null;
    notifyListeners();
  }
  
  // Effacer l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
