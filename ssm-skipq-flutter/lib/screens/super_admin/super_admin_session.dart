class SuperAdminSession {
  SuperAdminSession._();

  static bool _authenticated = false;

  static bool get isAuthenticated => _authenticated;

  static void start() => _authenticated = true;

  static void clear() => _authenticated = false;
}
