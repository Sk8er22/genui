// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// A login form widget (UI + validation only — no real network auth).
/// The model can supply a demo username/password pair for the "sign in"
/// flow; validation is deterministic client-side.
final class LogicLogin {
  static final catalogItem = CatalogItem(
    name: 'LogicLogin',
    dataSchema: S.object(
      description: 'A login form with validation (demo scope).',
      properties: {
        'title': S.string(),
        'hintUsername': S.string(description: 'Placeholder for username.'),
        'hintPassword': S.string(description: 'Placeholder for password.'),
        'demoPassword': S.string(
            description: 'Optional password that will be accepted as correct.'),
      },
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final m = (ctx.data as Map);
      return LogicLoginWidget(
        title: m['title'] is String ? m['title'] as String : 'Sign in',
        hintUsername: m['hintUsername'] is String
            ? m['hintUsername'] as String
            : 'Username',
        hintPassword: m['hintPassword'] is String
            ? m['hintPassword'] as String
            : 'Password',
        demoPassword: m['demoPassword'] is String
            ? m['demoPassword'] as String
            : null,
      );
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicLogin","title":"Sign in",
  "hintUsername":"user@example.com","hintPassword":"••••••","demoPassword":"demo123"}
]''',
    ],
  );
}

class LogicLoginWidget extends StatefulWidget {
  const LogicLoginWidget({
    super.key,
    this.title = 'Sign in',
    this.hintUsername = 'Username',
    this.hintPassword = 'Password',
    this.demoPassword,
  });
  final String title;
  final String hintUsername;
  final String hintPassword;
  final String? demoPassword;
  @override
  State<LogicLoginWidget> createState() => _LogicLoginWidgetState();
}

class _LogicLoginWidgetState extends State<LogicLoginWidget> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _obscure = true;
  String? _status;

  @override
  void dispose() {
    _u.dispose();
    _p.dispose();
    super.dispose();
  }

  String? _validateUser(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Username required' : null;

  String? _validatePass(String? v) =>
      (v == null || v.length < 4) ? 'Password too short' : null;

  void _submit() {
    final bool userOk = _validateUser(_u.text) == null;
    final bool passOk = _validatePass(_p.text) == null;
    final bool match = widget.demoPassword == null ||
        _p.text == widget.demoPassword;
    setState(() {
      if (!userOk || !passOk) {
        _status = 'Check the fields';
      } else if (widget.demoPassword != null && !match) {
        _status = 'Wrong password';
      } else {
        _status = 'Signed in ✓';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
              controller: _u,
              decoration: InputDecoration(
                  labelText: widget.hintUsername,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder()),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _p,
              obscureText: _obscure,
              onChanged: (v) => _validatePass(v),
              decoration: InputDecoration(
                labelText: widget.hintPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Sign in'),
            ),
            if (widget.demoPassword != null) ...[
              const SizedBox(height: 8),
              Text('Demo password: ${widget.demoPassword}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            if (_status != null) ...[
              const SizedBox(height: 8),
              Text(
                _status!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _status == 'Signed in ✓'
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
