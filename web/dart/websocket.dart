import 'dart:html';

import 'actionhandler.dart';
//import 'login.dart';

///modified WebSocket Class
class ClientWebSocket {
  final WebSocket _webSocket = WebSocket('');
  //final WebSocket _webSocket = WebSocket('ws://localhost:7070/ws');
  void connect() async {
    messageStream.listen((data) async {
      getaction(parseData(data), this);
    });
  }

  Stream get messageStream => _webSocket.onMessage.map((event) => event.data);

  Future<void> send(data) async {
    print(data);
    _webSocket.send(data);
  }
}

///Web socket for communication with server
ClientWebSocket ws = ClientWebSocket();

///parses ws data to action Map
Map<String, dynamic> parseData(String data) {
  Map<String, dynamic> r = {};

  List<String> split;
  split = data.split('; ');
  //print(split);
  r['action'] = split[0];
  split.removeAt(0);

  for (int i = 0; i < split.length; i++) {
    List<String> par = split[i].split(': ');
    //print(par);
    r[par[0]] = par[1];
  }
  return r;
}

///websocket initialized
void initwebsocket(ClientWebSocket ws) {
  ws.connect();
  //isLoggedIn(ws);
}
