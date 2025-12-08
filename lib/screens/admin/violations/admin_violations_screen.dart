// lib/screens/admin/violations/admin_violations_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'models/violation.dart';
import 'admin_violation_service.dart';
import 'admin_violation_card.dart';
import 'admin_violation_detail.dart';
import 'admin_violations_create.dart';

class AdminViolationsScreen extends StatefulWidget {
  final Dio dio;
  final String? bearerToken;

  const AdminViolationsScreen({super.key, required this.dio, this.bearerToken});

  @override
  State<AdminViolationsScreen> createState() => _AdminViolationsScreenState();
}

class _AdminViolationsScreenState extends State<AdminViolationsScreen> {
  late AdminViolationService _service;

  List<Violation> _items = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  final int _perPage = 50;

  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _service = AdminViolationService(
      widget.dio,
      bearerToken: widget.bearerToken,
    );
    _fetch(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetch({bool reset = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      if (reset) {
        _page = 1;
        _items = [];
      }
      final res = await _service.fetchViolations(
        page: _page,
        perPage: _perPage,
        q: _searchCtrl.text.trim(),
        type: _typeFilter,
      );
      setState(() {
        _items.addAll(res.items);
        _hasMore = res.hasMore;
        if (_hasMore) _page += 1;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load violations: $e')));
      setState(() {
        _hasMore = false;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _fetch(reset: true),
    );
  }

  Future<void> _openCreate() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminViolationCreateScreen(
          dio: widget.dio,
          bearerToken: widget.bearerToken,
        ),
      ),
    );
    if (ok == true) _fetch(reset: true);
  }

  void _openDetail(Violation v) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminViolationDetailScreen(
          dio: widget.dio,
          bearerToken: widget.bearerToken,
          initial: v,
        ),
      ),
    ).then((_) => _fetch(reset: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Violations'),
        actions: [
          IconButton(onPressed: _openCreate, icon: const Icon(Icons.add)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetch(reset: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search violations...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            if (_items.isEmpty && _loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (_items.isEmpty && !_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No violations found'),
                ),
              ),
            for (final v in _items)
              AdminViolationCard(
                violation: v,
                onTap: () => _openDetail(v),
                onEdit: () => _openDetail(v),
              ),
            if (_hasMore && !_loading)
              TextButton(onPressed: _fetch, child: const Text('Load more')),
            if (_loading && _items.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
