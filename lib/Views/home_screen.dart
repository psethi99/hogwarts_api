import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ScreenOne(),
    const ScreenTwo(),
    const ScreenThree(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My App'),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_add_outlined),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class ScreenOne extends StatelessWidget {
  const ScreenOne({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            color: Theme.of(context).primaryColor,
          child: const TabBar(
            tabs: [
              Tab(text: 'Hogwarts Characters', icon: Icon(Icons.castle_outlined),),
              Tab(text: 'Currency Conversion', icon: Icon(Icons.attach_money_outlined)),
            ],
          ),
        ),
        ),
        body: const TabBarView(
          children: [
            HogwartsTab(),
            CurrencyTab(),
          ],
        ),
      ),
    );
  }
}

// Tab no. 1 displaying Hogwarts characters
class HogwartsTab extends StatefulWidget {
  const HogwartsTab({Key? key}) : super(key: key);

  @override
  _HogwartsTabState createState() => _HogwartsTabState();
}

class _HogwartsTabState extends State<HogwartsTab> {
  late List<dynamic> characters;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final response = await http.get(Uri.parse('https://hp-api.onrender.com/api/characters'));
    if (response.statusCode == 200) {
      setState(() {
        characters = json.decode(response.body);
      });
    }
  }

  void _showDetails(BuildContext context, dynamic character) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(character['name'])),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('House: ${character['house']}'),
                Text('Species: ${character['species']}'),
                Text('Gender: ${character['gender']}'),
                Text('Actor: ${character['actor']}'),
                Text('Wand: ${character['wand']['wood']}, ${character['wand']['core']}, ${character['wand']['length']}"'),
                Text('Patronus: ${character['patronus'] ?? 'unknown'}'),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return characters == null
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: characters.length,
            itemBuilder: (context, index) => ListTile(
              title: Padding(
                padding: const EdgeInsets.only(bottom:8.0),
                child: Text(characters[index]['name'], style: const TextStyle(fontSize: 18),),
              ),
              subtitle: Text(characters[index]['house'], style: TextStyle(fontSize: 16),),
              onTap: () => _showDetails(context, characters[index]),
            ),
          );
  }
}

// Tab no. 2 displaying currency conversion
class CurrencyTab extends StatefulWidget {
  const CurrencyTab({Key? key}) : super(key: key);

  @override
  _CurrencyTabState createState() => _CurrencyTabState();
}

class _CurrencyTabState extends State<CurrencyTab> {
  late Future<Map<String, dynamic>> _ratesFuture;

  @override
  void initState() {
    super.initState();
    _ratesFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    final response = await http.get(Uri.parse('https://v6.exchangerate-api.com/v6/6620c6f0c1b2abea68ddb91f/latest/USD'));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded != null && decoded['conversion rates'] != null) {
      return decoded['conversion rates'];
      }
      else {
        throw Exception('Failed to process data');
      }
    }
    else {
      print(response.body);
      throw Exception('Failed to load Data ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>> (
        future: _ratesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final rates = snapshot.data!;
            return ListView.builder(
              itemCount: rates.length,
              itemBuilder: (context, index) {
                final currency = rates.keys.elementAt(index);
                final rate = rates[currency];
                return ListTile(
                  title: Text(currency),
                  trailing: Text(rate.toString()),
                );
              },
            );
          }
          else if (snapshot.hasError) {
            return Center(
              child: Text('Error : ${snapshot.error}'),
            );
          }
          else {
            return const Center (
              child: CircularProgressIndicator(),
            );
          }
        },
      ),

    );
  }
}

  // Screen no.2 displaying list of friends
class ScreenTwo extends StatefulWidget {
  const ScreenTwo({Key? key}) : super(key: key);

  @override
  _ScreenTwoState createState() => _ScreenTwoState();
}

class _ScreenTwoState extends State<ScreenTwo> {
  late Database _database;
  List<Map<String, dynamic>> _friendsList = [];

  @override
  void initState() {
    super.initState();
    _openDB();
    _loadFriendsList();
  }

  Future <void> _openDB() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'friends.db'),
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE friends(id INTEGER PRIMARY KEY, name TEXT, status TEXT)',
        );
      },
      version: 1,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final List<Map<String, dynamic>> friends = await _database.query('friends');
    setState(() {
      _friendsList = friends;
    });
  }

  Future<void> _addFriend() async {
    await _database.insert(
      'friends',
      {
        'name': 'Friend ${_friendsList.length + 1}',
        'status': 'Status message goes here',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _loadData();
  }

  Future<void> _updateFriend(int id, String name, String status) async {
    await _database.update(
      'friends',
      {'name': name, 'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadData();
  }

  Future<void> _deleteFriendById(int id) async {
    await _database.delete(
      'friends',
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadData();
  }

  Future<void> _showEditDialog(BuildContext context, int id, String name, String status) async {
    String newName = name;
    String newStatus = status;

    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Edit Friend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => newName = value,
              controller: TextEditingController(text: name),
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              onChanged: (value) => newStatus = value,
              controller: TextEditingController(text: status),
              decoration: const InputDecoration(labelText: 'Status'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              _updateFriend(id, newName, newStatus);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Friend updated');
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
      ),
      body: ListView.builder(
        itemCount: _friendsList.length,
        itemBuilder: (BuildContext context, int index) {
          final friend = _friendsList[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(friend['name'][0]),
            ),
        title: Text(friend['name']),
        subtitle: Text(friend['statusMessage']),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                //_editFriend(friend, index);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _deleteFriendByIndex(index);
              },
            ),
          ],
        ),
      );
    },
  ),
  floatingActionButton: FloatingActionButton(
    onPressed: () {
      _addFriend;
    },
    child: const Icon(Icons.add),
  ),
);
  }

/*
void _editFriend(Map<String, String> friend, int index) async {
final result = await Navigator.of(context).pushNamed('/editFriend', arguments: friend);
if (result != null && result is Map<String, String>) {
setState(() {
_friendsList[index] = result;
});
_saveFriendsList();
}
}
*/

void _deleteFriendByIndex(int index) {
setState(() {
_friendsList.removeAt(index);
});
_saveFriendsList();
}

void _saveFriendsList() async {
final prefs = await SharedPreferences.getInstance();
final encodedList = json.encode(_friendsList);
final list = json.decode(encodedList).cast<String>();
await prefs.setStringList('friendsList', list);

}

Future<void> _loadFriendsList() async {
final prefs = await SharedPreferences.getInstance();
final friendsListString = prefs.getString('friendsList');
if (friendsListString != null) {
setState(() {
_friendsList = json.decode(friendsListString).cast<Map<String, String>>();
});
}
}

@override
void dispose() {
_saveFriendsList();
super.dispose();
}
}


  // screen no. 3 displaying user details
class ScreenThree extends StatelessWidget {
  const ScreenThree({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      body: Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80, horizontal: 110),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                "Logged in as - ",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 18),
              Text(
                user.email!,
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                child: Text('Sign Out'),
                onPressed: () => FirebaseAuth.instance.signOut(),
              )
            ],
          ),
        ),
      ),
    );
  }
}
