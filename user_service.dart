import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class UserService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://student-ehailing-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  // Get current user's role by checking both tables
  static Future<String?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Check if user exists in drivers table
      final driverSnapshot = await _database.ref('drivers/${user.uid}').get();
      if (driverSnapshot.exists) {
        return 'Driver';
      }

      // Check if user exists in passengers table
      final passengerSnapshot = await _database.ref('passengers/${user.uid}').get();
      if (passengerSnapshot.exists) {
        return 'Passenger';
      }

      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Get user data from appropriate table
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final role = await getCurrentUserRole();
      if (role == null) return null;

      final tableName = role == 'Driver' ? 'drivers' : 'passengers';
      final snapshot = await _database.ref('$tableName/${user.uid}').get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }

      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user data in appropriate table
  static Future<bool> updateUserData(Map<String, dynamic> updates) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final role = await getCurrentUserRole();
      if (role == null) return false;

      final tableName = role == 'Driver' ? 'drivers' : 'passengers';
      await _database.ref('$tableName/${user.uid}').update(updates);
      return true;
    } catch (e) {
      print('Error updating user data: $e');
      return false;
    }
  }

  // Get all drivers (for passenger app to find nearby drivers)
  static Future<List<Map<String, dynamic>>> getAllDrivers() async {
    try {
      final snapshot = await _database.ref('drivers').get();
      if (snapshot.exists) {
        final driversMap = Map<String, dynamic>.from(snapshot.value as Map);
        return driversMap.entries
            .map((entry) => {
          'uid': entry.key,
          ...Map<String, dynamic>.from(entry.value as Map),
        })
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting drivers: $e');
      return [];
    }
  }

  // Get all passengers (for admin purposes)
  static Future<List<Map<String, dynamic>>> getAllPassengers() async {
    try {
      final snapshot = await _database.ref('passengers').get();
      if (snapshot.exists) {
        final passengersMap = Map<String, dynamic>.from(snapshot.value as Map);
        return passengersMap.entries
            .map((entry) => {
          'uid': entry.key,
          ...Map<String, dynamic>.from(entry.value as Map),
        })
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting passengers: $e');
      return [];
    }
  }

  // Check if current user is a driver
  static Future<bool> isCurrentUserDriver() async {
    final role = await getCurrentUserRole();
    return role == 'Driver';
  }

  // Check if current user is a passenger
  static Future<bool> isCurrentUserPassenger() async {
    final role = await getCurrentUserRole();
    return role == 'Passenger';
  }

  // Delete user from appropriate table
  static Future<bool> deleteCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final role = await getCurrentUserRole();
      if (role == null) return false;

      final tableName = role == 'Driver' ? 'drivers' : 'passengers';
      await _database.ref('$tableName/${user.uid}').remove();
      await user.delete();
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Get user by email from both tables
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      // Check drivers table
      final driversSnapshot = await _database.ref('drivers').orderByChild('email').equalTo(email).get();
      if (driversSnapshot.exists) {
        final data = Map<String, dynamic>.from(driversSnapshot.value as Map);
        final userData = data.values.first;
        return Map<String, dynamic>.from(userData as Map);
      }

      // Check passengers table
      final passengersSnapshot = await _database.ref('passengers').orderByChild('email').equalTo(email).get();
      if (passengersSnapshot.exists) {
        final data = Map<String, dynamic>.from(passengersSnapshot.value as Map);
        final userData = data.values.first;
        return Map<String, dynamic>.from(userData as Map);
      }

      return null;
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }
}