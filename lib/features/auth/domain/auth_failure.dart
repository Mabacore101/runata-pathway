/// A single, generic-bucket failure.
///
/// Per the QA'd behavioral spec, the Student Login Form never distinguishes
/// "wrong Student ID" from "wrong password" from "no such account" — every
/// failure surfaces the exact same message. Do not add more specific
/// exception subtypes for this form without re-checking the spec; a more
/// granular type here would tempt the UI layer into showing field-specific
/// errors, which is the one thing this form explicitly does not do.
class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException([
    this.message = 'Incorrect Student ID or password.',
  ]);

  final String message;

  @override
  String toString() => message;
}
