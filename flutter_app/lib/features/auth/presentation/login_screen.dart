import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool _hide   = true;

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).login(_email.text.trim(), _pass.text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, s) {
      if (s.hasError) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.error.toString()), backgroundColor: Colors.red));
    });
    final loading = ref.watch(authStateProvider).isLoading;

    return Scaffold(
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400),
          child: Form(key: _form, child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.local_shipping, size: 72, color: Color(0xFF1565C0)),
              const SizedBox(height: 8),
              Text('LeadBridge', textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text('إدارة العملاء والتوصيل', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 32),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => v?.contains('@') != true ? 'بريد غير صحيح' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pass,
                obscureText: _hide,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _hide = !_hide)),
                ),
                validator: (v) => (v?.length ?? 0) < 6 ? 'كلمة المرور قصيرة' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: loading ? null : _submit,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: loading ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('دخول', style: TextStyle(fontSize: 16)),
              ),
              TextButton(
                onPressed: () => context.go('/auth/register'),
                child: const Text('ليس لديك حساب؟ سجّل الآن'),
              ),
            ],
          )),
        ),
      ))),
    );
  }
}
