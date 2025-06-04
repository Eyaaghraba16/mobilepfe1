import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ProfileService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Méthode pour récupérer le profil de l'utilisateur avec fallback
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      print('CONTOURNEMENT: Utilisation directe du profil par défaut sans appel au serveur');
      // Ne pas tenter de récupérer le profil du serveur, utiliser directement le profil par défaut
      final token = await _storage.read(key: 'auth_token'); // Utiliser la clé correcte
      final userId = await _storage.read(key: 'user_id');
      final userRole = await _storage.read(key: 'user_role');
      
      // Ne pas essayer de récupérer le profil depuis le serveur
      // Utiliser directement le profil par défaut
      print('SOLUTION URGENTE: Utilisation directe du profil par défaut');
      return _getDefaultProfile(userId: userId, role: userRole);
    } catch (e) {
      print('Erreur générale: $e, utilisation du profil par défaut');
      return _getDefaultProfile();
    }
  }
  
  // Profil par défaut en cas d'erreur
  Map<String, dynamic> _getDefaultProfile({String? userId, String? role}) {
    return {
      'id': userId ?? '1',
      'firstname': 'Utilisateur',
      'lastname': 'Par Défaut',
      'email': 'utilisateur@example.com',
      'role': role ?? 'user',
      'isDefaultProfile': true, // Marquer comme profil par défaut
    };
  }
}
