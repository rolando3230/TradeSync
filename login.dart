import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tradesync/adminPage.dart';
import 'package:tradesync/homescreen.dart';
import 'package:tradesync/register.dart';
import 'package:tradesync/register2.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late TextEditingController usernameController;
  late TextEditingController passwordController;
  late TextEditingController forgotPasswordEmailController;
  late String error;
  bool _isObscure = true;
  late FlutterSecureStorage _secureStorage;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    forgotPasswordEmailController = TextEditingController();
    error = "";
    _secureStorage = FlutterSecureStorage();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final email = await _secureStorage.read(key: 'email');
    final password = await _secureStorage.read(key: 'password');

    if (email != null && password != null) {
      setState(() {
        usernameController.text = email;
        passwordController.text = password;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      await _secureStorage.write(key: 'email', value: usernameController.text);
      await _secureStorage.write(
          key: 'password', value: passwordController.text);
    } else {
      await _secureStorage.delete(key: 'email');
      await _secureStorage.delete(key: 'password');
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    forgotPasswordEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0D1C26),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 1300),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: isWeb
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 10, 10, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: 30),
                                Image.asset(
                                  'assets/images/tradesync.jpg',
                                  height: 300,
                                  width: 600,
                                ),
                                const Text(
                                  'VetInspect',
                                  style: TextStyle(
                                    color: Color(0xFF0D47A1),
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 100, 30, 50),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.0),
                              child: Card(
                                elevation: 3,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(40, 40, 20, 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      TextField(
                                        controller: usernameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Email Address',
                                        ),
                                        style:
                                            TextStyle(color: Color(0xB88635ff)),
                                      ),
                                      const SizedBox(height: 20),
                                      TextField(
                                        controller: passwordController,
                                        obscureText: _isObscure,
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isObscure
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isObscure = !_isObscure;
                                              });
                                            },
                                          ),
                                        ),
                                        style:
                                            TextStyle(color: Color(0xB88635ff)),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        error,
                                        style: const TextStyle(
                                          color: Color(0xB88635ff),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      CheckboxListTile(
                                        title: const Text('Remember Me'),
                                        contentPadding: const EdgeInsets.only(
                                            left: 0, top: 0),
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value!;
                                            _saveCredentials();
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: () async {
                                          bool isConnected =
                                              await _checkConnectivity();
                                          if (!isConnected) {
                                            setState(() {
                                              error = 'No internet connection';
                                            });
                                            return;
                                          }

                                          loginUser(
                                            context,
                                            usernameController.text,
                                            passwordController.text,
                                            (errorMsg) {
                                              setState(() {
                                                error = errorMsg;
                                              });
                                            },
                                          );
                                          await _saveCredentials();
                                        },
                                        style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  Colors.blue),
                                          padding: MaterialStateProperty.all<
                                              EdgeInsetsGeometry>(
                                            EdgeInsets.symmetric(
                                                vertical: 20, horizontal: 1),
                                          ),
                                          textStyle: MaterialStateProperty.all<
                                              TextStyle>(
                                            TextStyle(
                                                fontSize: 20,
                                                color: Colors.white),
                                          ),
                                        ),
                                        child: const Text('Login'),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        error,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          _showForgotPasswordDialog(context);
                                        },
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Image.asset(
                            'assets/images/tradesync.jpg',
                            height: isWeb ? 200 : 250,
                            width: isWeb ? 100 : 200,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors
                                  .white70, // Set the background color here
                              borderRadius: BorderRadius.circular(
                                  10.0), // Set the border radius here
                            ),
                            child: TextField(
                              controller: usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                              ),
                              style: TextStyle(
                                  color: Colors.white), // Change color to white
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors
                                  .white70, // Set the background color here
                              borderRadius: BorderRadius.circular(
                                  10.0), // Set the border radius here
                            ),
                            child: TextField(
                              controller: passwordController,
                              obscureText: _isObscure,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscure
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Color(
                                        0xFF0D1C26), // Set the icon color here
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isObscure = !_isObscure;
                                    });
                                  },
                                ),
                              ),
                              style: TextStyle(
                                  color: Colors
                                      .white), // Change text color to white
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            error,
                            style: const TextStyle(
                              color: Color(0xFFF3A734),
                            ),
                          ),
                          const SizedBox(height: 20),
                          CheckboxListTile(
                            title: Text(
                              'Remember Me',
                              style: TextStyle(
                                  color: Color(
                                      0xFFF3A734)), // Change text color to Color(0xFFF3A734)
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value!;
                              });
                            },
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              bool isConnected = await _checkConnectivity();
                              if (!isConnected) {
                                setState(() {
                                  error = 'No internet connection';
                                });
                                return;
                              }

                              loginUser(
                                context,
                                usernameController.text,
                                passwordController.text,
                                (errorMsg) {
                                  setState(() {
                                    error = errorMsg;
                                  });
                                },
                              );
                              await _saveCredentials();
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Color(
                                      0xFFF3A734)), // Change background color to Color(0xFFF3A734)
                              padding:
                                  MaterialStateProperty.all<EdgeInsetsGeometry>(
                                EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 1),
                              ),
                              textStyle: MaterialStateProperty.all<TextStyle>(
                                TextStyle(fontSize: 20, color: Colors.white),
                              ),
                            ),
                            child: const Text('Login'),
                          ),
                          TextButton(
                            onPressed: () {
                              _showForgotPasswordDialog(context);
                            },
                            style: ButtonStyle(
                              foregroundColor:
                                  MaterialStateProperty.all<Color>(Colors.blue),
                              padding:
                                  MaterialStateProperty.all<EdgeInsetsGeometry>(
                                EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 1),
                              ),
                              textStyle: MaterialStateProperty.all<TextStyle>(
                                TextStyle(fontSize: 20, color: Colors.blue),
                              ),
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(
                                    0xFFF3A734), // Change text color to Color(0xFFF3A734)
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            error,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 201, 55, 44),
                            ),
                          ),
                          const SizedBox(height: 15),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Register2()),
                              );
                            },
                            child: Text(
                              'Not yet registered?',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: isWeb ? 20 : 20,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          )
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> loginUser(BuildContext context, String username, String password,
      Function(String) setError) async {
    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: username.trim(),
        password: password.trim(),
      );

      final User? user = userCredential.user;

      if (user != null) {
        final userSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (userSnapshot.exists) {
          final userData = userSnapshot.data() as Map<String, dynamic>;
          final role = userData['role'];
          final isActive =
              userData['isActive'] ?? false; // Default to false if not present

          if (!isActive) {
            setError('Please wait for the admin to activate your account.');
            return;
          }

          if (role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminPage()),
            );
            return; // Exit the method after successful navigation
          } else if (role == 'user') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
            return; // Exit the method after successful navigation
          } else {
            setError('Invalid role: $role');
          }
        } else {
          setError('Account is deactivated. Contact admin for assistance.');
        }
      } else {
        setError('User data not found');
      }
    } on FirebaseAuthException catch (e) {
      setError('FirebaseAuthException: ${e.message}');
    } catch (e) {
      setError('An error occurred: $e');
    }
  }

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    String email = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Forgot Password',
            style: TextStyle(
              color:
                  Color(0xFFF3A734), // Change text color to Color(0xFFF3A734)
            ),
          ),
          content: TextField(
            onChanged: (value) {
              email = value;
            },
            decoration: const InputDecoration(hintText: 'Enter your email'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                final snapshot = await FirebaseFirestore.instance
                    .collection('Users')
                    .where('email', isEqualTo: email)
                    .get();
                if (snapshot.docs.isNotEmpty) {
                  final userDoc = snapshot.docs.first;
                  final userId = userDoc.id;
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: email);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Password reset email sent to $email'),
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Email not found. Please try again.'),
                  ));
                }
              },
              child: const Text(
                'Submit',
                style: TextStyle(
                  color: Color(
                      0xFFF3A734), // Change text color to Color(0xFFF3A734)
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
