class RoleSlug {
  // MUST match DB slugs
  static const admin = 'admin';
  static const enforcer = 'enforcer';
  static const cashier = 'cashier';

  static String normalize(String s) {
    final v = s.trim().toLowerCase();
    if (v == 'clerk') return cashier; // alias -> cashier
    return v;
  }

  /// True if any allowed role is present in the user's roles.
  static bool any(Iterable<String> userRoles, List<String> allow) {
    final user = userRoles.map(normalize).toSet();
    final wanted = allow.map(normalize);
    return wanted.any(user.contains);
  }
}

class RoleLabel {
  static const admin = 'Admin';
  static const enforcer = 'Enforcer';
  static const cashier = 'Cashier';
}
