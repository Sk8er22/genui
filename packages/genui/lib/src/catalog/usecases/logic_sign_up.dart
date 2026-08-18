// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';

/// Sign-up form with validation (username/email/password + confirm).
/// Demo only — no real account created.
final class LogicSignUp {
  static final catalogItem = CatalogItem(
    name: 'LogicSignUp',
    dataSchema: S.object(
      description: 'A registration form with validation (demo).',
      properties: {'title': S.string()},
      required: ['title'],
    ),
    widgetBuilder: (ctx) {
      final Object? title = (ctx.data as Map)['title'];
      return LogicSignUpWidget(
          title: title is String ? title : 'Create account');
    },
    exampleData: [
      () => '''
[
 {"id":"root","component":"LogicSignUp","title":"Create account"}
]''',
    ],
  );
}

class LogicSignUpWidget extends StatefulWidget {
  const LogicSignUpWidget({super.key, this.title = 'Create account'});
  final String title;
  @override
  State<LogicSignUpWidget> createState() => _LogicSignUpWidgetState();
}

class _LogicSignUpWidgetState extends State<LogicSignUpWidget> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _status;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _reqEmail(String? v) =>
      (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()))
          ? 'Enter a valid email'
          : null;

  String? _required(String? v, [String msg = 'Required field']) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  void _submit() {
    final bool ok = _formKey.currentState?.validate() ?? false;
    if (ok) {
      setState(() => _status = 'Account created ✓ (demo)');
    } else {
      setState(() => _status = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Full name', prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder()),
                textInputAction: TextInputAction.next,
                validator: (v) => _required(v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(
                    labelText: 'Email', prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => _reqEmail(v),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Password', prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 characters' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Confirm password', prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder()),
                validator: (v) =>
                    v != _pass.text ? 'Passwords do not match' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Create account'),
              ),
              if (_status != null) ...[
                const SizedBox(height: 8),
                Text(
                  _status!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
