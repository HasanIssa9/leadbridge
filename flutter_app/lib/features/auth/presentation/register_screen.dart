import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form    = GlobalKey<FormState>();
  final _org     = TextEditingController();
  final _name    = TextEditingController();
  final _email   = TextEditingController();
  final _pass    = TextEditingController();

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).register(
      orgName: _org.text.trim(), fullName: _name.text.trim(),
      email: _email.text.trim(), password: _pass.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, s) {
      if (s.hasError) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.error.toString()), backgroundColor: Colors.red));
    });
    final loading = ref.watch(authStateProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('حساب جديد')),
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400),
          child: Form(key: _form, child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('إنشاء حساب', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextFormField(controller: _org,
                decoration: const InputDecoration(labelText: 'اسم الشركة / المتجر *', prefixIcon: Icon(Icons.business)),
                validator: (v) => (v?.length ?? 0) < 2 ? 'مطلوب' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _name,
                decoration: const InputDecoration(labelText: 'اسمك الكامل *', prefixIcon: Icon(Icons.person)),
                validator: (v) => (v?.length ?? 0) < 2 ? 'مطلوب' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني *', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => v?.contains('@') != true ? 'بريد غير صحيح' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور *', prefixIcon: Icon(Icons.lock_outlined)),
                validator: (v) => (v?.length ?? 0) < 8 ? '8 أحرف على الأقل' : null),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: loading ? null : _submit,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: loading ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('إنشاء الحساب', style: TextStyle(fontSize: 16)),
              ),
              TextButton(onPressed: () => context.go('/auth/login'), child: const Text('لديك حساب؟ سجّل دخولك')),
            ],
          )),
        ),
      ))),
    );
  }
}
