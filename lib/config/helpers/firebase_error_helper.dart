import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseErrorHelper {
  static String translate(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Credenciales inválidas. Verifica tu correo y contraseña.';
        case 'invalid-email':
          return 'El correo electrónico ingresado no es válido.';
        case 'email-already-in-use':
          return 'El correo ya está registrado en otra cuenta.';
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 caracteres.';
        case 'user-disabled':
          return 'Esta cuenta ha sido deshabilitada.';
        case 'requires-recent-login':
          return 'Por seguridad, debes cerrar sesión e ingresar nuevamente antes de actualizar estos datos sensibles.';
        case 'network-request-failed':
          return 'Error de conexión. Verifica tu internet e inténtalo de nuevo.';
        case 'too-many-requests':
          return 'Demasiados intentos. Por favor, intenta más tarde.';
        default:
          return 'Error de autenticación: ${e.message ?? e.code}';
      }
    } else if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return 'No tienes permisos para realizar esta acción.';
        case 'unavailable':
          return 'El servicio no está disponible en este momento. Verifica tu conexión a internet.';
        case 'not-found':
          return 'El documento o recurso solicitado no fue encontrado.';
        default:
          return 'Error de base de datos: ${e.message ?? e.code}';
      }
    } else if (e is Exception) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      return msg;
    }
    return 'Ha ocurrido un error inesperado. Por favor, intenta nuevamente.';
  }
}
