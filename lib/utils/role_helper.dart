bool canAccess(String role, List<String> allowedRoles) {
  return allowedRoles.contains(role);
}
