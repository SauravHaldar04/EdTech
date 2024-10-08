// ignore_for_file: public_member_api_docs, sort_constructors_first
class User {
  final String uid;
  final String email;
  final String firstName;
  final String middleName;
  final String lastName;

  User({
    required this.uid,
    required this.middleName,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  User.empty()
      : uid = '',
        email = '',
        firstName = '',
        middleName = '',
        lastName = '';
}
