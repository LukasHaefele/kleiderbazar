//import 'dart:html';
//import 'dart:io';

//import 'package:pdf/widgets.dart';

import 'qr.dart';
import 'websocket.dart';

///Very simple, barely even necessary
QRScanner initQrscanner(ClientWebSocket ws) {
  QRScanner qs = QRScanner(ws);
  return qs;
}
