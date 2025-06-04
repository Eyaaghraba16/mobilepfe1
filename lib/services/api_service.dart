import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../models/request.dart';
import '../models/user.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  
  // URL de base de l'API
  String get baseUrl => ApiConfig.baseUrl;
  final AuthService _authService = AuthService();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();
  
  // Récupérer toutes les demandes depuis l'API
  Future<List<Request>> getAllRequests() async {
    try {
      print('Tentative de récupération des demandes depuis l\'API...');
      final token = await _authService.getToken();
      final requestsEndpoint = ApiConfig.endpoints['requests']!;
      final response = await http.get(
        Uri.parse('$baseUrl$requestsEndpoint'),
        headers: ApiConfig.getDefaultHeaders(token),
      );
      
      if (response.statusCode == 200) {
        print('Réponse de l\'API reçue avec succès');
        final List<dynamic> data = json.decode(response.body);
        print('Nombre de demandes reçues: ${data.length}');
        
        // Convertir les données JSON en objets Request
        final requests = data.map((json) {
          // Convertir les champs pour correspondre à la structure de Request
          final Map<String, dynamic> requestJson = {
            'id': json['id'],
            'user_id': 1, // Valeur par défaut
            'type': json['type'],
            'status': json['status'],
            'start_date': json['startDate'],
            'end_date': json['endDate'],
            'description': json['description'],
            'details': {
              'traitePar': json['details']['traitePar'],
              'reponse': json['details']['reponse']
            },
            'created_at': json['createdAt']
          };
          
          return Request.fromJson(requestJson);
        }).toList();
        
        return requests;
      } else {
        print('Erreur lors de la récupération des demandes: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception lors de la récupération des demandes: $e');
      // En cas d'erreur, retourner une liste vide
      return [];
    }
  }
  
  // Ajouter une nouvelle demande via l'API
  Future<bool> addRequest(Request request) async {
    try {
      print('Tentative d\'ajout d\'une demande via l\'API...');
      
      // Convertir l'objet Request en JSON
      final requestData = request.toJson();
      
      // Envoyer la demande au serveur
      final response = await http.post(
        Uri.parse('$baseUrl/requests.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Demande ajoutée avec succès');
        return true;
      } else {
        print('Erreur lors de l\'ajout de la demande: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Exception lors de l\'ajout de la demande: $e');
      return false;
    }
  }
  
  // Télécharger une image de profil vers le serveur
  Future<String?> uploadProfileImage(File imageFile, int userId) async {
    try {
      print('Tentative de téléchargement de l\'image de profil...');
      
      // Créer une requête multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload_profile_image.php'),
      );
      
      // Ajouter l'ID de l'utilisateur
      request.fields['user_id'] = userId.toString();
      
      // Déterminer le type MIME de l'image
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = fileExtension == 'png' ? 'image/png' : 'image/jpeg';
      
      // Ajouter le fichier à la requête
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_image',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );
      
      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        print('Image de profil téléchargée avec succès');
        final responseData = json.decode(response.body);
        return responseData['image_url'];
      } else {
        print('Erreur lors du téléchargement de l\'image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception lors du téléchargement de l\'image: $e');
      return null;
    }
  }
  
  // Mettre à jour une demande existante via l'API
  Future<bool> updateRequest(Request request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_request.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toJson()),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Exception lors de la mise à jour d\'une demande: $e');
      return false;
    }
  }
  
  // Mettre à jour le statut d'une demande
  Future<bool> updateRequestStatus(String requestId, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/update_request_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': requestId,
          'status': newStatus,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Exception lors de la mise à jour du statut: $e');
      return false;
    }
  }
  
  // Mettre à jour les informations de l'utilisateur
  Future<bool> updateUser(User user) async {
    try {
      print('Tentative de mise à jour des informations de l\'utilisateur...');
      
      // Convertir l'objet User en JSON
      final userData = user.toJson();
      
      // Envoyer les données au serveur
      final response = await http.put(
        Uri.parse('$baseUrl/users.php/${user.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );
      
      if (response.statusCode == 200) {
        print('Informations de l\'utilisateur mises à jour avec succès');
        return true;
      } else {
        print('Erreur lors de la mise à jour des informations: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Exception lors de la mise à jour des informations: $e');
      return false;
    }
  }
}
