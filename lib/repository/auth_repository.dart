import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:docs/constants/constants.dart';
import 'package:docs/models/error_model.dart';
import 'package:docs/models/user_model.dart';
import 'package:docs/repository/local_storage_repo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(
    client: Client(),
    googleSignIn: GoogleSignIn(),
    localStorageRepository: LocalStorageRepository(),
  ),
);

final userProvider = StateProvider<UserModel?>((ref) => null);

class AuthRepository {
  final GoogleSignIn _googleSignIn;
  final Client _client;
  final LocalStorageRepository _localStorageRepository;
  AuthRepository(
      {required LocalStorageRepository localStorageRepository,
      required Client client,
      required GoogleSignIn googleSignIn})
      : _googleSignIn = googleSignIn,
        _client = client,
        _localStorageRepository = localStorageRepository;

  Future<ErrorModel> signInWithGoogle() async {
    ErrorModel error = ErrorModel(error: 'Some error', data: null);
    try {
      final user = await _googleSignIn.signIn();
      if (user != null) {
        final userAccount = UserModel(
            email: user.email,
            name: user.displayName!,
            profilePic: user.photoUrl!,
            token: '',
            uid: '');
        var res = await _client.post(
          Uri.parse(
            '$host/api/signup',
          ),
          body: userAccount.toJson(),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        );

        switch (res.statusCode) {
          case 200:
            final newUser = userAccount.copyWith(
              uid: jsonDecode(res.body)['user']['_id'],
              token: jsonDecode(res.body)['token'],
            );
            error = ErrorModel(error: null, data: newUser);
            _localStorageRepository.setToken(newUser.token);
            break;
        }
      }
    } catch (e) {
      error = ErrorModel(error: e.toString(), data: null);
    }
    return error;
  }

  Future<ErrorModel> getUserData() async {
    ErrorModel error = ErrorModel(error: 'Something went wrong', data: null);

    try {
      String? token = await _localStorageRepository.getToken();
      if (token != null) {
        var res = await _client.get(Uri.parse('$host/'), headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        });

        switch (res.statusCode) {
          case 200:
            final newUser = UserModel.fromJson(
              jsonEncode(
                jsonDecode(res.body)['user'],
              ),
            ).copyWith(token: token);
            error = ErrorModel(error: null, data: newUser);
            _localStorageRepository.setToken(newUser.token);
            break;
        }
      }
    } catch (e) {
      error = ErrorModel(
        error: e.toString(),
        data: null,
      );
    }

    return error;
  }

  void signOut() async {
    await _googleSignIn.signOut();
    _localStorageRepository.setToken('');
  }
}
