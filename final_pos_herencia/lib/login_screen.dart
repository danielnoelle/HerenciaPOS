import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'La Herencia',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A0DAD),
                    ),
                  ),
                  const SizedBox(height: 50),
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Email Address',
                      labelText: 'Email Address',
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: Colors.grey[300]!)
                      ),
                       focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: Colors.deepPurple[300]!)
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Password TextField
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            labelText: 'Password',
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                             enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide(color: Colors.grey[300]!)
                            ),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide(color: Colors.deepPurple[300]!)
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A0DAD),
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Text(
                      'LOGIN',
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () {
                    },
                     style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      minimumSize: const Size(double.infinity, 54),
                      side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      'REGISTER',
                      style: TextStyle(fontSize: 18, color: Colors.grey[700], fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24.0,
                        width: 24.0,
                        child: Checkbox(
                          value: true, 
                          onChanged: (val) {},
                          activeColor: const Color(0xFF6A0DAD),
                          side: BorderSide(color: Colors.grey[400]!, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ), 
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'By registering your details, you agree with our Terms & Conditions, and Privacy and Cookie Policy.',
                           style: TextStyle(fontSize: 11, color: Colors.black54),
                           maxLines: 2,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE0F2F1),
                    Color(0xFFA5D6A7),
                    Color(0xFF81C784),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.3, 0.7],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: ClipPath(
                      child: Container(
                        decoration: BoxDecoration(
                           gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.lightGreen.withOpacity(0.3),
                                const Color(0xFFB9E4C9).withOpacity(0.5),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(

                    top: MediaQuery.of(context).size.height * 0.2,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ]
                      ),
                      child: CircleAvatar(
                        radius: MediaQuery.of(context).size.width * 0.12,
                        backgroundColor: Colors.brown[700],
                        child: const Icon(Icons.local_restaurant, size: 60, color: Colors.white70),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.15,
                    left: MediaQuery.of(context).size.width * 0.05,
                    child: Transform.rotate(
                      angle: -0.3,
                      child: Container(
                        width: 50,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.yellow[700]?.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                           boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(5, 5),
                            )
                          ]
                        ),
                        child: const Center(child: Icon(Icons.opacity, color: Colors.black54, size: 30)),
                      ),
                    ),
                  ),

                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.15,
                    right: MediaQuery.of(context).size.width * 0.08, 
                    child: Transform.rotate(
                      angle: 0.2,
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.red[200]?.withOpacity(0.8),
                        child: const Icon(Icons.scatter_plot, color: Colors.black54, size: 30),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.05,
                    right: MediaQuery.of(context).size.width * 0.05,
                    child: Row(
                      children: [
                        Icon(Icons.restaurant, size: 60, color: Colors.grey[800]),
                        const SizedBox(width: 5),
                        Transform.rotate(
                          angle: 0.5,
                          child: Icon(Icons.icecream_outlined, size: 60, color: Colors.grey[800]), // A different icon for spoon
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}