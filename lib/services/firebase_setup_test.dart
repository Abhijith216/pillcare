import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Quick test to verify Firebase is working
class FirebaseSetupTest {
  static Future<void> testConnection() async {
    print('=== Testing Firebase Connection ===');
    
    try {
      // Test Auth
      print('✓ Firebase Auth available: ${FirebaseAuth.instance != null}');
      
      // Test Firestore
      print('✓ Firestore available: ${FirebaseFirestore.instance != null}');
      
      // Test write permission
      print('Testing Firestore write permission...');
      await FirebaseFirestore.instance.collection('_test').doc('test').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'test',
      });
      print('✓ Firestore write successful!');
      
      // Clean up
      await FirebaseFirestore.instance.collection('_test').doc('test').delete();
      print('✓ Firestore delete successful!');
      
      print('=== All tests passed! ===');
    } catch (e) {
      print('✗ Error: $e');
      print('✗ Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('✗ Firebase code: ${e.code}');
        print('✗ Firebase message: ${e.message}');
      }
    }
  }
}
