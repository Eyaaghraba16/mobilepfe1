import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/request.dart';
import 'shared_storage_service.dart';
import 'request_service.dart';

// Structure pour stocker les statistiques du tableau de bord
class DashboardStats {
  final int enAttente;
  final int approuvees;
  final int refusees;
  final int total;
  final List<Request> recentRequests;

  DashboardStats({
    required this.enAttente,
    required this.approuvees,
    required this.refusees,
    required this.total,
    required this.recentRequests,
  });
}

class DashboardService {
  final SharedStorageService _sharedStorage = SharedStorageService();
  final RequestService _requestService = RequestService();
  
  // Stream controller pour les statistiques du tableau de bord
  final _dashboardStatsController = StreamController<DashboardStats>.broadcast();
  
  // Stream pour écouter les changements de statistiques
  Stream<DashboardStats> get dashboardStatsStream => _dashboardStatsController.stream;
  
  // Abonnement au stream de demandes
  StreamSubscription<List<Request>>? _requestsSubscription;
  
  // Constructeur
  DashboardService() {
    // Écouter les changements dans le stockage partagé
    _requestsSubscription = _sharedStorage.requestsStream.listen((requests) {
      // Calculer les nouvelles statistiques
      final stats = _calculateStats(requests);
      
      // Notifier les écouteurs
      _dashboardStatsController.add(stats);
    });
  }
  
  // Libérer les ressources
  void dispose() {
    _requestsSubscription?.cancel();
    _dashboardStatsController.close();
  }
  
  // Méthode pour charger les données locales
  Future<void> loadLocalData() async {
    try {
      print('DashboardService: Chargement des données locales...');
      // Charger les données depuis le stockage local
      final requests = await _sharedStorage.getRequests();
      // Calculer les statistiques
      final stats = _calculateStats(requests);
      // Notifier les écouteurs
      _dashboardStatsController.add(stats);
      print('DashboardService: Chargement des données locales terminé');
    } catch (e) {
      print('DashboardService: Erreur lors du chargement des données locales: $e');
      rethrow;
    }
  }

  // Récupérer les statistiques du tableau de bord
  Future<DashboardStats> getDashboardStats() async {
    try {
      // Essayer d'abord de récupérer les données depuis l'API
      List<Request> requests = await _requestService.getUserRequests();
      
      // Calculer les statistiques
      return _calculateStats(requests);
    } catch (e) {
      print('Erreur lors de la récupération des statistiques depuis l\'API: $e');
      
      // En cas d'erreur, utiliser les données du stockage partagé
      try {
        List<Request> requests = await _sharedStorage.getRequests();
        return _calculateStats(requests);
      } catch (e) {
        print('Erreur lors de la récupération des statistiques depuis le stockage partagé: $e');
        // Retourner des statistiques vides en cas d'erreur
        return DashboardStats(
          enAttente: 0,
          approuvees: 0,
          refusees: 0,
          total: 0,
          recentRequests: [],
        );
      }
    }
  }

  // Calculer les statistiques à partir des demandes
  DashboardStats _calculateStats(List<Request> requests) {
    int enAttente = 0;
    int approuvees = 0;
    int refusees = 0;
    
    // Déboguer les demandes pour vérifier les statuts
    print('Nombre total de demandes: ${requests.length}');
    for (var request in requests) {
      String status = request.status.toLowerCase();
      print('Demande ${request.id}: Type=${request.type}, Status=${request.status}');
      
      if (status == 'en attente' || status.contains('attente')) {
        enAttente++;
      } else if (status == 'approuvée' || status == 'approuvee' || status.contains('approuv')) {
        approuvees++;
      } else if (status == 'refusée' || status == 'refusee' || status.contains('refus') || status == 'rejetée' || status.contains('rejet')) {
        refusees++;
      }
    }
    
    // Afficher les statistiques calculées
    print('Statistiques calculées - En attente: $enAttente, Approuvées: $approuvees, Refusées: $refusees, Total: ${requests.length}');
    
    // Trier les demandes par date (les plus récentes d'abord)
    requests.sort((a, b) { 
      try {
        final dateA = a.createdAt ?? '';
        final dateB = b.createdAt ?? '';
        // Si les dates sont au format dd/MM/yyyy
        if (dateA.contains('/') && dateB.contains('/')) {
          var partsA = dateA.split('/');
          var partsB = dateB.split('/');
          if (partsA.length == 3 && partsB.length == 3) {
            var dateObjA = DateTime(int.parse(partsA[2]), int.parse(partsA[1]), int.parse(partsA[0]));
            var dateObjB = DateTime(int.parse(partsB[2]), int.parse(partsB[1]), int.parse(partsB[0]));
            return dateObjB.compareTo(dateObjA);
          }
        }
        // Sinon essayer le format ISO
        return DateTime.parse(dateB).compareTo(DateTime.parse(dateA));
      } catch (e) {
        // En cas d'erreur, ne pas changer l'ordre
        return 0;
      }
    });
    
    // Prendre les 5 demandes les plus récentes
    List<Request> recentRequests = requests.take(5).toList();
    
    return DashboardStats(
      enAttente: enAttente,
      approuvees: approuvees,
      refusees: refusees,
      total: requests.length,
      recentRequests: recentRequests,
    );
  }

  // Charger les données directement depuis l'API
  Future<void> loadDataFromApi() async {
    try {
      // Récupérer les données directement depuis l'API
      final requests = await _requestService.getUserRequests();
      print('Chargement des données depuis l\'API réussi: ${requests.length} demandes récupérées');
      
      // Calculer les statistiques
      final stats = _calculateStats(requests);
      
      // Notifier les écouteurs
      _dashboardStatsController.add(stats);
    } catch (e) {
      print('Erreur lors du chargement des données depuis l\'API: $e');
      // En cas d'erreur, essayer de charger les données locales
      await loadLocalData();
    }
  }
}
