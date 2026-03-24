class AuthService {
  // Para acceder desde cualquier lugar
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Simulación de base de datos en memoria
  final Map<String, String> _users = {}; 

  // Usuario actualmente logueado
  String? _currentUser;

  bool register(String email, String password) {
    if (email.isEmpty || password.isEmpty) return false;
    if (_users.containsKey(email)) return false;
    
    _users[email] = password;
    return true;
  }

  bool login(String email, String password) {
    if (_users.containsKey(email) && _users[email] == password) {
      _currentUser = email;
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
  }

  String? get currentUser => _currentUser;
}
