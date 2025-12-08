import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/admin_user.dart';
import 'providers/admin_users_provider.dart';

// widgets
import 'widgets/role_filter_bar.dart';
import 'widgets/user_card.dart';

// import the detail screen ONCE and alias it
import 'user_detail_screen.dart' as details;

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();

  // <--- the anchor key used by RoleFilterBar to measure alignment
  final GlobalKey _firstTileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminUsersProvider>().reload();
    });
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final p = context.read<AdminUsersProvider>();
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      p.loadMore();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AdminUsersProvider>();

    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: p.setQuery,
            decoration: InputDecoration(
              hintText: 'Search users by name or email…',
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        // Role filters — pass the anchor key so RoleFilterBar can measure alignment
        RoleFilterBar(value: p.role, onChanged: p.setRole),
        const SizedBox(height: 8),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: p.refresh,
            child: Builder(
              builder: (_) {
                if (p.loading && p.users.isEmpty) {
                  return const _Loading();
                }
                if (p.error != null && p.users.isEmpty) {
                  return _ErrorView(message: p.error!);
                }
                if (p.users.isEmpty) {
                  return const _EmptyState();
                }
                return ListView.separated(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: p.users.length + (p.canLoadMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    if (i >= p.users.length) {
                      // loader row
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final u = p.users[i];

                    // Build the row normally with your existing card widget (UserCard)
                    final row = UserCard(
                      user: u,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => details.UserDetailScreen(user: u),
                        ),
                      ),
                    );

                    // attach key only to the first item — no change to the card itself
                    if (i == 0) {
                      return Container(key: _firstTileKey, child: row);
                    }
                    return row;
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40),
            const SizedBox(height: 10),
            const Text('Something went wrong'),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(padding: EdgeInsets.all(24), child: Text('No users found')),
  );
}
