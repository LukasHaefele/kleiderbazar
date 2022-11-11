//import 'dart:io';

import 'dart:convert';
//import 'dart:html';

import 'package:kleiderbazar/actions.dart';
import 'package:kleiderbazar/admin.dart';
import 'package:kleiderbazar/item.dart';
//import 'package:kleiderbazar/transaction.dart';
import 'package:kleiderbazar/user.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

Map<WebSocketChannel, dynamic> channelList = {};

///specific on connect function
void onConnect(WebSocketChannel wsc) {
  //wsc.sink.add('cock');
  print('connection opened');
  String key = stat['sr'];
  if (checkForOpen(wsc)) {
    return;
  }
  channelList[wsc] = true;
  checkForSpace(wsc);
  wsc.sink.add('connection_opened; key: $key');
  wsc.stream.listen((data) {
    //wsc.sink.add('penis');
    //print(data);
    getAction(parseData(data), wsc);
  }, onDone: () {
    channelList[wsc] = false;
    wsc.sink.close(status.goingAway);
    print('connection closed');
  });
}

///Function to close page if Site is supposed to be unavailable
bool checkForOpen(WebSocketChannel wsc) {
  DateTime dLower = DateTime.parse(stat['dLower']);
  DateTime dUpper = DateTime.parse(stat['dUpper']);
  if (dLower.isBefore(DateTime.now()) && DateTime.now().isBefore(dUpper)) {
    wsc.sink.add('page_closed; dt: ${dUpper.toString()}');
    return true;
  }
  return false;
}

///parses ws data to action
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

///handels action
void getAction(Map<String, dynamic> request, WebSocketChannel wsc) {
  print(request);
  switch (request['action']) {
    case LOGIN:
      login(request['username'], request['password'], wsc);
      return;

    case LOGIN_ID:
      loginId(int.parse(request['id']), wsc);
      return;

    /*case LOGIN_RESTORE_PASSWORD:
      return;
    */

    case REGISTER:
      registerUser(request['username'], request['password'], request['name'],
          request['email'], wsc);
      return;

    case ITEM_UPLOAD:
      String size = '';
      if (request.containsKey('size')) {
        size = request['size'];
      }
      addItem(
          request['name'],
          int.parse(request['ammount']),
          request['price'],
          int.parse(request['usrId']),
          int.parse(request['productType']),
          size,
          wsc);
      return;

    case ITEM_CLAIM:
      sendItemsById(int.parse(request['id']), wsc);
      return;

    case ITEM_ADD_ONE:
      itemModByOne(int.parse(request['id']), true, false, wsc);
      return;

    case ITEM_DELETE_ONE:
      itemModByOne(int.parse(request['id']), false, true, wsc);
      return;

    case ITEM_DELETE:
      removeItem(int.parse(request['id']), true, wsc);
      return;

    case ITEM_UNTRASH:
      itemUntrash(int.parse(request['id']), wsc);
      return;

    case REGISTER_LOOKUP:
      registerLookup(wsc, int.parse(request['id']), true);
      return;

    case REGISTER_CHECKOUT:
      List l = jsonDecode(request['items']);
      registerCheckout(wsc, l, request['total'], request['giv']);
      return;

    case REGISTER_SCAN:
      registerScan(wsc, int.parse(request['id']));
      return;

    case REGISTER_MARK:
      registerLookup(wsc, int.parse(request['id']), false);
      return;

    case REGISTER_UNMARK:
      registerUnmark(request['id']);
      return;

    case REGISTER_ADD_CUSTOM:
      makeCustom(int.parse(request['conum']), int.parse(request['id']),
          double.parse(request['price']), wsc);
      return;

    case REGISTER_TIP:
      registerTip(double.parse(request['tip']), int.parse(request['id']));
      return;

    case ADMIN_GET_ALL:
      adminGetAll(wsc);
      return;

    case ADMIN_PAYOUT:
      payout(int.parse(request['id']), wsc);
      return;

    case ADMIN_CONFIRM:
      adminConfirm(int.parse(request['id']), wsc);
      return;

    case ADMIN_UPDATE_STAT:
      updateStat(request['comissionFee'], request['donation']);
      return;

    case ADMIN_MAKE_REGISTER:
      adminMakeRegister(int.parse(request['id']));
      return;

    case ADMIN_DELETE_USER:
      adminDeleteUser(int.parse(request['id']));
      return;

    case ADMIN_ARCHIVE_ALL:
      adminArchiveAll();
      return;

    case ADMIN_PAYOUT_ALL:
      adminPayoutAll(wsc);
      return;

    case ADMIN_PASSWORD_RESET:
      adminResetPassword(int.parse(request['id']), wsc);
      return;
  }
  print('unhandeled action');
}
