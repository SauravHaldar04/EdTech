import 'package:aparna_education/core/error/server_exception.dart';
import 'package:aparna_education/features/auth/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract interface class AuthRemoteDatasources {
  // Session? get session;
  FirebaseAuth get firebaseAuth;
  FirebaseFirestore get firestore;
  GoogleSignIn get googleSignIn;

  Future<UserModel> signInWithEmailAndPassword({
    required String firstName,
    required String lastName,
    required String middleName,
    required String email,
    required String password,
  });
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<UserModel> signInWithGoogle();
  Future<bool> verifyEmail();
  Future<UserModel?> getCurrentUser();
  Future<FirebaseAuth> getFirebaseAuth();
  Future<bool> isUserEmailVerified();
}

class AuthRemoteDatasourcesImpl implements AuthRemoteDatasources {
  @override
  final FirebaseAuth firebaseAuth;
  @override
  final FirebaseFirestore firestore;
  @override
  final GoogleSignIn googleSignIn;
  @override
  //Session? get session => supabaseClient.auth.currentSession;
  AuthRemoteDatasourcesImpl(
      this.firebaseAuth, this.firestore, this.googleSignIn);
  @override
  Future<UserModel> loginWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      final response = await firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      if (response.user == null) {
        throw ServerException(message: 'User is null');
      }
      return await firestore
          .collection('users')
          .doc(response.user!.uid)
          .get()
          .then((value) => UserModel.fromMap(value.data()!));
    } catch (e) {
      print(e.toString());
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String firstName,
    required String lastName,
    required String middleName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = UserModel(
          middleName: middleName,
          email: email,
          firstName: firstName,
          uid: response.user!.uid,
          lastName: lastName);
      await firestore
          .collection('users')
          .doc(response.user!.uid)
          .set(user.toMap());
      if (response.user == null) {
        throw ServerException(message: 'User is null');
      }
      return user;
    } catch (e) {
      print(e.toString());
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        return null;
      }
      return await firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .then((value) => UserModel.fromMap(value.data()!));
    } catch (e) {
      print(e.toString());
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw ServerException(message: 'User is null');
      }
      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final user = await FirebaseAuth.instance.signInWithCredential(credential);
      if (user.user == null) {
        throw ServerException(message: 'User is null');
      } else {
        String fullName = user.user!.displayName ?? '';
        List<String> nameParts = fullName.split(' ');
        await firestore.collection('users').doc(user.user!.uid).update(
            UserModel(
                    uid: user.user!.uid,
                    email: user.user!.email ?? '',
                    firstName: nameParts.isNotEmpty ? nameParts[0] : '',
                    lastName: nameParts.length > 1 ? nameParts[1] : '',
                    middleName: '')
                .toMap());
      }
      String firstName = '';
      String lastName = '';
      if (user.user!.displayName != null) {
        List<String> nameParts = user.user!.displayName!.split(' ');
        firstName = nameParts.isNotEmpty ? nameParts[0] : '';
        lastName = nameParts.length > 1 ? nameParts[1] : '';
      }
      return UserModel(
          uid: user.user!.uid,
          email: user.user!.email ?? '',
          firstName: firstName,
          lastName: lastName,
          middleName: '');
    } catch (e) {
      print(e.toString());
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> verifyEmail() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw ServerException(message: 'User is null');
      }
      await user.sendEmailVerification();
      return true;
    } catch (e) {
      print(e.toString());
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<FirebaseAuth> getFirebaseAuth() {
    return Future.value(firebaseAuth);
  }

  @override
  Future<bool> isUserEmailVerified() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw ServerException(message: 'User is null');
      }
      await user.reload();
      print(user.emailVerified);
      return user.emailVerified;
    } catch (e) {
      print(e.toString());
      throw ServerException(message: e.toString());
    }
  }
}
