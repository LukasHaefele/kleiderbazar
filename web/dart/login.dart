//import 'dart:convert';
import 'dart:html';
//import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

import 'panel.dart';
import 'register.dart';
import 'storefront.dart';
import 'websocket.dart';

///Login buttons initialized
void initLogin(ClientWebSocket ws) {
  print('init login');
  //initPasswordRestore(ws);
  querySelector('#loginButton')?.onClick.listen((event) {
    String username = (document.getElementById('loginusername') as InputElement)
        .value as String;
    String password = (document.getElementById('loginpassword') as InputElement)
        .value as String;
    Key key = Key.fromUtf8(getKey());
    IV iv = IV.fromLength(16);
    Encrypter encrypter = Encrypter(AES(key));
    String encrypted = encrypter.encrypt(password, iv: iv).base64;
    ws.send('login; username: $username; password: $encrypted');
  });
  querySelector('#registerButton')?.onClick.listen((event) {
    hidePanel('#loginPanel');
    showPanel('#registerPanel');
  });
  querySelector('#welcomeRegister')?.onClick.listen((event) {
    showPanel('#registerPanel');
  });
  querySelector('#backToLogin')?.onClick.listen((event) {
    hidePanel('#registerPanel');
    showPanel('#loginPanel');
  });
  querySelector('#register')?.onClick.listen((event) {
    String username = (document.getElementById('registeruname') as InputElement)
        .value as String;
    String password = (document.getElementById('registerpass') as InputElement)
        .value as String;
    String passrepe =
        (document.getElementById('regsiterpassrep') as InputElement).value
            as String;
    String name = (document.getElementById('registername') as InputElement)
        .value as String;
    String email = (document.getElementById('registeremail') as InputElement)
        .value as String;
    if (passrepe != password) {
      error('passwords don\'t match');
      return;
    } else if (username == '' || password == '' || name == '' || email == '') {
      error('Bitte alle relevanten Felder ausfüllen.');
      return;
    } else if (username.contains(RegExp(r'( |€)'))) {
      error(
          'In ihrem Nutzernamen oder Passwort befinden sich nicht akzeptierte Zeichen wie Leerzeichen oder "€".');
    } else {
      Key key = Key.fromUtf8(getKey());
      IV iv = IV.fromLength(16);
      Encrypter encrypter = Encrypter(AES(key));
      String encrypted = encrypter.encrypt(password, iv: iv).base64;
      ws.send(
          'register; username: $username; password: $encrypted; name: $name; email: $email');
    }
  });
}

void initPasswordRestore(ClientWebSocket ws) {
  querySelector('#resetPassword')?.onClick.listen((event) {
    hidePanel('#loginPanel');
    showPanel('#passwordRestore');
  });
  querySelector('#passwordRestoreConfirm')?.onClick.listen((event) {
    String email = (querySelector('#restoreEmail')! as InputElement).value!;
    String uname = (querySelector('#restoreUname')! as InputElement).value!;
    String conum = (querySelector('#restoreConum')! as InputElement).value!;
    if (email == '' && uname == '' && conum == '') {
      error('Bitte Füllen sie mindestens eines der Felder aus');
      return;
    }
    ws.send(
        'login_restore_password; email: $email; uname: $uname; conum: $conum');
  });
  querySelector('#passwordRestoreClose')?.onClick.listen((event) {
    hidePanel('#passwordRestore');
  });
}

///removes Register Buttons if the number of participants is too high
void removeRegister() {
  querySelector('#welcomeRegister')?.remove();
  querySelector('#registerButton')?.remove();
  querySelector('#welcomeMessage')!
    ..text = welcomeMessage
    ..style.marginBottom = 'auto';
}

String welcomeMessage = 'Nummernvergabe abgeschlossen.';

///login Panel initialized
void login() {
  querySelector('.welcome')?.style.display = 'none';
  showPanel('#loginPanel');
}

///valid login response user
void loggedIn(String username, String id, String payout, String ammount,
    bool byCred, ClientWebSocket ws) {
  killKey();
  final Storage ls = window.localStorage;
  ls['id'] = id;
  if (byCred) {
    window.location.reload();
  }
  querySelector('#ammountMarker')?.text = 'Warenzahl:' + ammount;
  querySelector('#loginbutton')?.style.display = 'none';
  querySelector('.welcome')?.style.display = 'none';
  querySelector('#payout')
    ?..style.display = 'flex'
    ..text = 'Sie erhalten $payout Euro';
  querySelector('#accountbutton')
    ?..style.display = 'flex'
    ..text = username
    ..onMouseEnter.listen((event) {
      querySelector('#accountbutton')?.text = 'Abmelden';
    })
    ..onMouseLeave.listen((event) {
      querySelector('#accountbutton')?.text = username;
    })
    ..onClick.listen((event) {
      invalidate();
      window.location.reload();
    });
  initStorefront(ws, id);
}

///Successful registration response
void registerSuccess(String id) {
  error(
      'Ihr account wurde angelegt. Sobald ein Administartor ihn bestätigt hat können sie sich anmelden.');
  final Storage ls = window.localStorage;
  ls['id'] = id;
  querySelector('#welcomeMessage')?.innerHtml =
      'Nach der Freigabe duch das Basarteam bekommst du eine Infomail und kannst dann deine Artikel einstellen.';
}

///valid login response register
void loginRegister(String id, ClientWebSocket ws) {
  killKey();
  querySelector('#loginbutton')?.style.display = 'none';
  querySelector('.welcome')?.style.display = 'none';
  querySelector('#accountbutton')
    ?..style.display = 'flex'
    ..text = 'Kasse'
    ..onMouseEnter.listen((event) {
      querySelector('#accountbutton')?.text = 'Abmelden';
    })
    ..onMouseLeave.listen((event) {
      querySelector('#accountbutton')?.text = 'Kasse';
    })
    ..onClick.listen((event) {
      invalidate();
      window.location.reload();
    });
  initRegister(ws);
  final Storage ls = window.localStorage;
  ls['id'] = id;
}

///checks for locally saved login
void isLoggedIn(String sr, ClientWebSocket ws) {
  String id;
  final Storage ls = window.localStorage;
  if (ls.containsKey('id')) {
    id = ls['id']!;
    //print(token);
    ws.send('login_id; id: ' + id);
    return;
  }
  ls['sr'] = sr;
}

///pulls encryption key from local
String getKey() {
  final Storage ls = window.localStorage;
  if (ls.containsKey('sr')) {
    return ls['sr']!;
  }
  return '';
}

///deletes encryption key
void killKey() {
  final Storage ls = window.localStorage;
  if (ls.containsKey('sr')) {
    ls.remove('sr');
  }
}

///deletes locally saved login
void invalidate() {
  final Storage ls = window.localStorage;
  ls.remove('id');
  window.location.reload();
}

///get locally saved login
String localId() {
  final Storage ls = window.localStorage;
  /*if (ls.containsKey('id')) {
    id = ls['id']!;
  }*/
  return ls['id']!;
}

///generates Date and Time for next bazar
void makeDt(String dt) {
  List l = dt.split(' ');
  String weekday = getWeekday(dt);
  String date = l[0];
  String time = l[1];
  l = date.split('-');
  time = getTime(time);
  String give =
      'Die Nummernvergabe für den Kleiderbazar Gomaringen bgeinnt am $weekday den ${l[2]}.${l[1]}.${l[0]} um $time Uhr';
  querySelector('#closedP')?.text = give;
}

///makes Time readable
String getTime(String t) {
  String r = '';
  List l = t.split(':');
  r += l[0] + ':' + l[1];
  return r;
}

///Returns the String weekday
String getWeekday(String s) {
  int i = DateTime.parse(s).weekday;
  switch (i) {
    case 1:
      return 'Montag';
    case 2:
      return 'Dienstag';
    case 3:
      return 'Mittwoch';
    case 4:
      return 'Donnerstag';
    case 5:
      return 'Freitag';
    case 6:
      return 'Samstag';
    case 7:
      return 'Sonntag';
  }
  return '';
}
/*
///Adds Task to Password Reset List
void addPasswordReset() {}
*/