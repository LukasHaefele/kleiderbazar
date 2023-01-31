import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:kleiderbazar/admin.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

///user class for Kleiderbazar
class User {
  ///Unique user id
  late int id;

  ///unique username for login
  late String username;

  ///encrypted user password
  late String password;

  ///Full name of User
  late String name;

  ///Indicator whether user is a register
  late bool register;

  ///Ammount of money owed to the user
  late double payout;

  ///Indicator whether user is an admin
  late bool admin;

  ///User email
  late String email;

  ///List of amounts the user has in each article type
  late List ammounts;

  ///unique Commission number
  late int conum;

  late bool emp;

  late bool pwR;

  late bool unc;

  late bool del;

  User(
      this.id,
      this.username,
      this.password,
      this.name,
      this.register,
      this.payout,
      this.admin,
      this.email,
      this.ammounts,
      this.conum,
      this.emp,
      this.pwR,
      this.unc,
      this.del);

  int fullAmmount() {
    int r = 0;
    for (int i in ammounts) {
      r += i;
    }
    return r;
  }
}

///generates a map to save the user to json
Map userToJson(User u) {
  Map m = {
    'id': u.id,
    'username': u.username,
    'password': u.password,
    'name': u.name,
    'register': u.register,
    'payout': u.payout,
    'admin': u.admin,
    'email': u.email,
    'ammounts': u.ammounts,
    'conum': u.conum,
    'emp': u.emp,
    'pwR': u.pwR,
    'unc': u.unc,
    'del': u.del
  };

  return m;
}

///generates user from Map from json
User userFromJson(Map m) {
  return User(
      m['id'],
      m['username'],
      m['password'],
      m['name'],
      m['register'],
      m['payout'],
      m['admin'],
      m['email'],
      m['ammounts'],
      m['conum'],
      m['emp'],
      m['pwR'],
      m['unc'],
      m['del']);
}

///Empty User to be returned if no user was found
User emptyUser = User(-1, '', '', '', false, 0.0, false, '',
    [stat['maxItem'], 0], -1, false, false, false, false);

///List of active users
List<User> activeUsers = getUsers();

List coHash = jsonDecode(File('.data/coHash.json').readAsStringSync());

List waiting = jsonDecode(File('.data/waiting.json').readAsStringSync());

///List of deleted users
//List<User> deleted = getDeleted();

///List of all users
//List<User> allUsers = makeAll();

///List of Reset users
//List<User> resetUsers = getReset();

///Generates List of all Users
/* List<User> makeAll() {
  List<User> l = [];
  l.addAll(activeUsers);
  l.addAll(deleted);
  l.addAll(resetUsers);
  return l;
}
 */
///get Reset User List
/* List<User> getReset() {
  List<User> l = [];
  File f = File('.data/reset.json');
  List ll = jsonDecode(f.readAsStringSync());

  for (var element in ll) {
    l.add(userFromJson(element));
  }
  return l;
}
 */
///save Reset User List
/* void saveReset() {
  List l = [];
  for (var element in resetUsers) {
    l.add(userToJson(element));
  }
  File f = File('.data/reset.json');
  f.writeAsString(jsonEncode(l));
}
 */
///get Deleted User List
/* List<User> getDeleted() {
  List<User> l = [];
  File f = File('.data/deleted.json');
  List ll = jsonDecode(f.readAsStringSync());

  for (var element in ll) {
    l.add(userFromJson(element));
  }
  return l;
}
 */
///save Deleted User List
/* void saveDeleted() {
  List l = [];
  for (var element in deleted) {
    l.add(userToJson(element));
  }
  File f = File('.data/deleted.json');
  f.writeAsString(jsonEncode(l));
}
 */
///gets Users from json file
List<User> getUsers() {
  List<User> l = [];

  File f = File('.data/user.json');
  List l1 = jsonDecode(f.readAsStringSync());

  for (var element in l1) {
    l.add(userFromJson(element));
  }

  return l;
}

///saves Users to json file
void saveUsers() async {
  List l = [];
  for (var element in activeUsers) {
    l.add(userToJson(element));
  }
  File f = File('.data/user.json');
  f.writeAsString(jsonEncode(l));
}

///logs in User through loginpanel
void login(String username, String password, WebSocketChannel wsc) {
  for (User u in activeUsers) {
    if (u.username == username) {
      if (u.unc) {
        wsc.sink.add(
            'error; message: Ihr Account wurde noch nicht bestätigt. Bitte haben sie noch ein wenig Geduld. Sie werden eine Email erhalten sobald ihr account bestätigt wurde.');
        return;
      } else if (u.pwR) {
        wsc.sink.add(
            'error; message: Ihr Passwort wurde zurückgesetzt. Bitte setzen sie ein neues Passwort indem sie sich erneut mit gleicher Email und gleichem Benutzernamen registrieren. Alles bereits erstellten Waren werden weiterhin auffindbar sein.');
        return;
      } else if (u.password == password) {
        int id = u.id;
        if (u.register) {
          print('A Register has opened');
          wsc.sink.add('login_register; id: $id');
        } else if (u.admin) {
          print('An Admin has connected to the System');
          String sendable = jsonEncode(stat);
          wsc.sink.add('login_admin; id: $id; stat: $sendable');
        } else {
          double p = u.payout;
          int am = u.fullAmmount();
          wsc.sink.add(
              'login_success; username: $username; id: $id; payout: $p; ammount: $am; byCred: true');
        }
        return;
      }
    }
  }
  wsc.sink.add('login_failure');
}

///registers User
void registerUser(String username, String password, String name, String email,
    WebSocketChannel wsc) {
  if (stat['bareUserNum'] >= stat['maximumUser']) {
    waiting.add({
      'username': username,
      'password': password,
      'name': name,
      'email': email
    });
    File('.data/waiting.json').writeAsStringSync(jsonEncode(waiting));
    wsc.sink.add(
        'error; message: Leider ist die maximale Anzahl an Nutzern erreicht. Sie wurden auf die Warteliste gesetzt.');
    return;
  }
  int id = getUserId();
  for (User u in activeUsers) {
    if (u.username == username) {
      if (u.pwR) {
        u.password = password;
        wsc.sink.add(
            'error; message: Ihr Passwort wurde zu dem neuen Passwort geändert. Bitte Loggen sie sich erneut ein.');
        u.pwR = false;
        return;
      }
      wsc.sink.add('error; message: Nutzername ist bereits vergeben.');
      return;
    }
    if (u.email == email) {
      if (u.pwR) {
        wsc.sink.add(
            'error; message: Ihr Passwort wurde zurück gesetzt. Bitte registrieren sie sich erneut mit ihrem Nutzernamen.');
      } else {
        wsc.sink.add('error; message: Diese E-Mail ist bereits registriert.');
      }
      return;
    }
  }
  int coNum = getCoNum(id);
  if (coNum == -1) {
    wsc.sink.add(
        'error; message: Es gab ein Problem bei der Zuweisung der Kom-Nummer. Bitte melden sie sich bei einem Administrator.');
  }
  User newUser = User(id, username, password, name, false, -stat['donation'],
      false, email, [0, 0], coNum, false, false, true, false);
  activeUsers.add(newUser);
  stat['bareUserNum']++;
  saveStat();
  saveUsers();
  wsc.sink.add('register_success; id: $id');
}

///checks whether User is a password reset User
/* bool isReset(String username, String password, String name, String email,
    WebSocketChannel wsc) {
  for (User u in resetUsers) {
    if (u.email == email) {
      resetUsers.remove(u);
      u.password = password;
      u.username = username;
      u.name = name;
      activeUsers.add(u);
      saveReset();
      saveUsers();
      stat['bareUserNum']++;
      saveStat();
      wsc.sink.add(
          'error; message: Ihr Passwort wurde zurück gesetzt. Bitte laden sie die Seite neu und melden sich an.');
      return true;
    }
  }
  return false;
}
 */
///Updates E-Mail List
void updateEmailList() {
  String emp = '';
  String sellers = '';
  for (User u in activeUsers) {
    if (!u.admin && !u.register && !u.del) {
      String s = 'Name: ${u.name}, Nutzername: ${u.username}, Kom: ${u.conum}'
          ', email: ${u.email}\n';
      if (u.emp) {
        emp += s;
      } else {
        sellers += s;
      }
    }
  }
  File f = File('web/label/emails.txt');
  String write = '---------------------Mitarbeiter---------------------\n$emp'
      '----------------------Verkäufer----------------------\n$sellers';
  f.writeAsStringSync(write);
}

///returns Commission Number for new user
int getCoNum(int id) {
  for (int i = 0; i < stat['bareUserNum']; i++) {
    if (coHash[i] == -1) {
      coHash[i] = id;
      File('.data/coHash.json').writeAsStringSync(jsonEncode(coHash));
      return i;
    }
  }
  return -1;
}

/* 
///gets unconfirmed Users
List<User> getUnconfirmed() {
  List<User> l = [];

  File f = File('.data/unconfirmed.json');
  List l1 = jsonDecode(f.readAsStringSync());

  for (var element in l1) {
    l.add(userFromJson(element));
  }

  return l;
}

///saves unconfirmed users
void saveUnconfirmed() async {
  List l = [];
  for (var element in unconfirmed) {
    l.add(userToJson(element));
  }
  File f = File('.data/unconfirmed.json');
  f.writeAsString(jsonEncode(l));
}

 */ ///gets new Id for new user
int getUserId() {
  /*
  if (activeUsers.isNotEmpty) {
    return activeUsers[activeUsers.length - 1].id + 1;
  } else {
    return 0;
  }
  */

  Random r = Random();
  int id = r.nextInt(stat['maxId']);
  while (userIdTaken(id)) {
    id = r.nextInt(stat['maxId']);
  }
  return id;
}

bool userIdTaken(int id) {
  return getUserById(id) != emptyUser;
}

///logs in user through saved token
void loginId(int id, WebSocketChannel wsc) {
  for (User u in activeUsers) {
    if (u.id == id) {
      if (u.unc) {
        return;
      }
      if (u.pwR) {
        wsc.sink.add(
            'error; message: Ihr Passwort wurde zurückgesetzt. Bitte setzen sie ein neues Passwort indem sie sich erneut mit gleicher Email und gleichem Benutzernamen registrieren. Alles bereits erstellten Waren werden weiterhin auffindbar sein.');
        return;
      }
      String username = u.username;
      if (u.register) {
        print('A Register has opened');
        wsc.sink.add('login_register; id: $id');
      } else if (u.admin) {
        print('An Admin has connected to the System');
        String sendable = jsonEncode(stat);
        wsc.sink.add('login_admin; id: $id; stat: $sendable');
      } else {
        double payout = u.payout;
        int am = u.fullAmmount();
        wsc.sink.add(
            'login_success; username: $username; id: $id; payout: $payout; ammount: $am');
      }
      return;
    }
  }
  wsc.sink.add('login_invalidate');
}

///gets User by Id
User getUserById(int id) {
  for (User u in activeUsers) {
    if (u.id == id) {
      return u;
    }
  }
  return emptyUser;
}

///checks if the maximum amount of Users is already reached
void checkForSpace(WebSocketChannel wsc) {
  if (stat['bareUserNum'] >= stat['maximumUser']) {
    wsc.sink.add('connection_reg');
  }
}
