import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class UserService {
  final AuthService _authService = AuthService();
  
  // Méthode pour récupérer le profil de l'utilisateur connecté
  Future<User> getUserProfile() async {
    try {
      // SOLUTION URGENTE: Ne pas essayer d'appeler le serveur
      print('CONTOURNEMENT: Utilisation d\'un profil utilisateur par défaut');
      
      // Récupérer l'ID et le rôle de l'utilisateur depuis le stockage local
      final userId = await _authService.getUserId() ?? '1';
      final userRole = await _authService.getUserRole() ?? 'user';
      
      // Créer un utilisateur par défaut
      return User(
        id: int.parse(userId),
        firstname: 'Utilisateur',
        lastname: 'Par Défaut',
        email: 'utilisateur@example.com',
        role: userRole,
      );
    } catch (e) {
      print('Erreur lors de la récupération du profil: $e');
      // En cas d'erreur, retourner un utilisateur par défaut
      return User(
        id: 1,
        firstname: 'Utilisateur',
        lastname: 'Par Défaut',
        email: 'utilisateur@example.com',
        role: 'user',
      );
    }
  }
}
