import 'dart:html';

import 'login.dart';
import 'websocket.dart';

///initializing header
void initheader(ClientWebSocket ws) {
  querySelector('.logo')
    ?..onClick.listen((event) {
      querySelector('.logo')?.style.display = 'none';
    })
    ..onMouseEnter.listen((event) {
      querySelector('#logoHint')?.style.display = 'unset';
    })
    ..onMouseLeave.listen((event) {
      querySelector('#logoHint')?.style.display = 'none';
    });
  querySelector('.welcome')?.style.display = 'flex';
  initLogin(ws);
  querySelector('#loginbutton')?.onClick.listen((event) {
    login();
  });
}
