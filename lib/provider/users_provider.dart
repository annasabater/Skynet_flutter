// lib/provider/users_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../services/UserService.dart';
import '../services/auth_service.dart';

class UserProvider with ChangeNotifier {
  // ------------------ Estado ---------------------------------------------
  final List<User> _users = [];
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // ------------------ Getters --------------------------------------------
  List<User> get users => List.unmodifiable(_users);
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ------------------ Conversaciones activas ----------------------------
  final Set<String> _conversationUserIds = {};
  List<String> get conversationUserIds => _conversationUserIds.toList();

  /// Carga los IDs de conversación desde el historial de mensajes
  void loadConversationsFromHistory(List<dynamic> history) {
    if (_currentUser == null) return;
    for (var msg in history) {
      final senderId = msg.senderId as String;
      final receiverId = msg.receiverId as String;
      final partnerId = senderId == _currentUser!.id ? receiverId : senderId;
      _conversationUserIds.add(partnerId);
    }
    notifyListeners();
  }

  /// Inicializa datos: usuarios y conversaciones
  Future<void> initData() async {
    await loadUsers();
    await loadConversations();
  }

  /// Carga desde la API todos los usuarios (sin paginación)
  Future<void> loadUsers() async {
    _setLoading(true);
    _setError(null);
    try {
      final fetched = await UserService.getUsers();
      _users
        ..clear()
        ..addAll(fetched);
      notifyListeners();
    } catch (e) {
      _setError('Error loading users: $e');
      _users.clear();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Carga desde la API la lista de partnerIds con los que ya has chateado
  Future<void> loadConversations() async {
    if (_currentUser == null) return;
    _setLoading(true);
    _setError(null);
    try {
      final token = await AuthService().token;
      final url = Uri.parse(
        '${AuthService().baseApiUrl}/conversations/${_currentUser!.id}',
      );
      final resp = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        _conversationUserIds
          ..clear()
          ..addAll(data.map((conv) => conv['partnerId'] as String));
        notifyListeners();
      } else {
        throw Exception('Error cargando conversaciones (${resp.statusCode})');
      }
    } catch (e) {
      _setError('No se pudieron cargar las conversaciones: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Añade una conversación nueva (cuando se inicia o recibe un mensaje)
  void addConversation(String userId) {
    if (_conversationUserIds.add(userId)) {
      notifyListeners();
    }
  }

  // ------------------ Restricciones de correo ---------------------------
  static const _restrictedEmails = {
    'dron_azul1@upc.edu',
    'dron_verde1@upc.edu',
    'dron_rojo1@upc.edu',
    'dron_amarillo1@upc.edu',
    'invitado_1@upc.edu',
  };

  bool get isRestricted {
    final mail = _currentUser?.email.trim().toLowerCase();
    return mail != null && _restrictedEmails.contains(mail);
  }

  // ------------------ Competidor ----------------------------------------
  static const _competitorEmails = {
    'dron_azul1@upc.edu',
    'dron_verde1@upc.edu',
    'dron_rojo1@upc.edu',
    'dron_amarillo1@upc.edu',
  };

  bool get isCompetitor {
    final mail = _currentUser?.email.trim().toLowerCase();
    return mail != null && _competitorEmails.contains(mail);
  }

  /// Administrador ↔ rol = 'Administrador' **y** correo *@upc.edu*
  bool get isAdmin {
    final u = _currentUser;
    if (u == null) return false;
    return u.role.toLowerCase() == 'administrador' &&
        u.email.trim().toLowerCase().endsWith('@upc.edu');
  }

  // ------------------ Helpers de sesión ---------------------------------
  /// Establece el usuario actual (p. ej. tras login)
  void setCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Elimina el usuario actual
  void clearCurrentUser() {
    _currentUser = null;
    notifyListeners();
  }

  // ------------------ Internos ------------------------------------------
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  // ------------------ CRUD backend (opcional) ---------------------------
  Future<bool> crearUsuari(
    String userName,
    String email,
    String password,
    String role,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      final nouUsuari = User(
        userName: userName,
        email: email,
        password: password,
        role: role,
      );
      final created = await UserService.createUser(nouUsuari);
      _users.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error creating user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> eliminarUsuariPerId(String id) async {
    _setLoading(true);
    _setError(null);
    try {
      final ok = await UserService.deleteUser(id);
      if (ok) _users.removeWhere((u) => u.id == id);
      notifyListeners();
      return ok;
    } catch (e) {
      _setError('Error deleting user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> eliminarUsuari(String userName) async {
    _setLoading(true);
    _setError(null);
    try {
      final u = _users.firstWhere((e) => e.userName == userName);
      final ok = await UserService.deleteUser(u.id!);
      if (ok) _users.remove(u);
      notifyListeners();
      return ok;
    } catch (e) {
      _setError('Error deleting user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ------------------ Historial de compras/ventas ----------------------
  List<Map<String, dynamic>> _purchaseHistory = [];
  List<Map<String, dynamic>> _salesHistory = [];
  bool _historyLoading = false;
  String? _historyError;

  List<Map<String, dynamic>> get purchaseHistory =>
      List.unmodifiable(_purchaseHistory);
  List<Map<String, dynamic>> get salesHistory =>
      List.unmodifiable(_salesHistory);
  bool get isHistoryLoading => _historyLoading;
  String? get historyError => _historyError;

  Future<void> fetchPurchaseHistory() async {
    if (_currentUser == null) return;
    _historyLoading = true;
    _historyError = null;
    notifyListeners();
    try {
      final data = await UserService.getPurchaseHistory(_currentUser!.id!);
      _purchaseHistory = data;
    } catch (e) {
      _historyError = 'Error cargando historial de compras: $e';
      _purchaseHistory = [];
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSalesHistory() async {
    if (_currentUser == null) return;
    _historyLoading = true;
    _historyError = null;
    notifyListeners();
    try {
      final data = await UserService.getSalesHistory(_currentUser!.id!);
      _salesHistory = data;
    } catch (e) {
      _historyError = 'Error cargando historial de ventas: $e';
      _salesHistory = [];
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }
}
