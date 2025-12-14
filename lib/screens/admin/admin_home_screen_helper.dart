
  Widget _buildBody() {
    switch (_index) {
      case 0:
        return AdminUsersScreen();
      case 1:
        return AdminViolationsScreen(
          dio: widget.dio,
          bearerToken: widget.bearerToken,
        );
      case 2:
        return AdminDashboardScreen();
      case 3:
        return AdminPaymentsScreen();
      case 4:
        return AdminReportsScreen();
      default:
        return AdminDashboardScreen();
    }
  }
