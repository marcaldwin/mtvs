import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'providers/admin_notifications_provider.dart';
import '../users/models/admin_user.dart';
import '../users/user_detail_screen.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminNotificationsProvider>().fetchRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AdminNotificationsProvider>();
    final requests = p.requests; // List<dynamic>

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: p.isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No pending requests', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    final userJson = req['user'];
                    final date = DateTime.tryParse(req['created_at'] ?? '') ?? DateTime.now();

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.redAccent,
                          child: Icon(Icons.lock_reset, color: Colors.white),
                        ),
                        title: Text('Reset Request: ${userJson['full_name'] ?? 'Unknown'}'),
                        subtitle: Text('${userJson['email']}\n${timeago.format(date)}'),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navigate to user detail
                          // We need to construct AdminUser from json
                          if (userJson != null) {
                            // Ideally AdminUser.fromJson handles the structure
                            // ensure fields match what AdminUser expects (id, full_name, email, role etc)
                            // The controller returns User model, so it should match mostly.
                            // We might need to ensure 'role' format.
                            try {
                               final u = AdminUser.fromJson(userJson);
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(
                                   builder: (_) => UserDetailScreen(user: u),
                                 ),
                               ).then((_) {
                                 // Refresh list when coming back, in case resolved
                                 p.fetchRequests();
                               });
                            } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error parsing user: $e')),
                                );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
