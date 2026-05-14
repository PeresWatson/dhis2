import 'package:d2_touch/modules/auth/models/login-response.model.dart';
import 'package:flutter/material.dart';
import 'package:d2_touch/d2_touch.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize the SDK shell
  D2Touch d2Touch = await D2Touch.init();

  runApp(MaterialApp(home: LoginScreen(d2Touch: d2Touch)));
}

class LoginScreen extends StatefulWidget {
  final D2Touch d2Touch;
  const LoginScreen({super.key, required this.d2Touch});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  // 2. The Login Process
  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {

      // This method downloads user info and sets up the local database
      
      var status = await D2Touch.logIn(
        username: "admin", // Replace with your DHIS2 username
        password: "district", // Replace with your DHIS2 password
        url: "https://play.dhis2.org/2.36.10",
      );

      if (status == LoginResponseStatus.ONLINE_LOGIN_SUCCESS) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DataScreen(d2Touch: widget.d2Touch)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: $status")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DHIS2 Login")),
      body: Center(
        child: _isLoading 
          ? const CircularProgressIndicator() 
          : ElevatedButton(onPressed: _handleLogin, child: const Text("Login to DHIS2")),
      ),
    );
  }
}

// 3. Viewing Data Screen
class DataScreen extends StatelessWidget {
  final D2Touch d2Touch;
  const DataScreen({super.key, required this.d2Touch});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My DHIS2 Data")),
      body: FutureBuilder(
        // Fetching from the local DB queries you provided earlier
        future: Future.wait([
          d2Touch.userModule.user.getOne(),
          d2Touch.userModule.userOrganisationUnit.get(),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final user = snapshot.data![0];
          final List orgUnits = snapshot.data![1];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text("Logged in as: ${user?.displayName}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text("My Organisation Units:", style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              ...orgUnits.map((ou) => ListTile(
                title: Text(ou.displayName ?? "Unknown Unit"),
                subtitle: Text("ID: ${ou.id}"),
                leading: const Icon(Icons.map),
              )),
            ],
          );
        },
      ),
    );
  }
}