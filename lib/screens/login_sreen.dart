import 'package:docs/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';

import '../repository/auth_repository.dart';
import '../utiils/colors.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({Key? key}) : super(key: key);

  void signInWithGoogle(WidgetRef ref, BuildContext context) async {
    final sMessange = ScaffoldMessenger.of(context);
    final navigator = Routemaster.of(context);
    final errorModel =
        await ref.read(authRepositoryProvider).signInWithGoogle();
    if (errorModel.error == null) {
      ref.read(userProvider.notifier).update((state) => errorModel.data);
      navigator.push('/');
    } else {
      sMessange.showSnackBar(SnackBar(
        content: Text(
          '${errorModel.error!}   Error',
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => signInWithGoogle(ref, context),
          icon: Image.asset(
            'assets/images/g-logo-2.png',
            height: 20,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: whiteColor,
            minimumSize: const Size(150, 50),
          ),
          label: const Text(
            "Sign in with Google",
            style: TextStyle(color: blackColor),
          ),
        ),
      ),
    );
  }
}
