import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _creatingAccount = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      final service = SupabaseService();
      if (_creatingAccount) {
        await service.signUp(_email.text.trim(), _password.text, _name.text.trim());
        if (mounted && service.currentUser == null) {
          setState(() => _error = 'Check your email to confirm your account, then sign in.');
        }
      } else {
        await service.signIn(_email.text.trim(), _password.text);
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Sign-in failed. Check your details and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_creatingAccount ? 'Create your Plano account' : 'Sign in to Plano',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 24),
                    if (_creatingAccount) ...[
                      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(controller: _email, keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email], decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _password, obscureText: true,
                        autofillHints: [_creatingAccount ? AutofillHints.newPassword : AutofillHints.password],
                        decoration: const InputDecoration(labelText: 'Password'),
                        validator: (v) => (v == null || v.length < 6) ? 'Use at least 6 characters' : null),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(width: double.infinity, child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy ? const CircularProgressIndicator() : Text(_creatingAccount ? 'Create account' : 'Sign in'),
                    )),
                    TextButton(
                      onPressed: _busy ? null : () => setState(() { _creatingAccount = !_creatingAccount; _error = null; }),
                      child: Text(_creatingAccount ? 'I already have an account' : 'Create an account'),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}
