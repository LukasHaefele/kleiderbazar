import 'dart:convert';
import 'dart:html';

import 'package:kleiderbazar/actions.dart';

import 'admin_front.dart';
import 'login.dart';
import 'panel.dart';
import 'register.dart';
import 'storefront.dart';
import 'websocket.dart';

///parses websocket actions
void getaction(Map<String, dynamic> request, ClientWebSocket ws) {
  print(request);
  switch (request['action']) {
    case CONNECTION_OPENED:
      print('connection opened');
      isLoggedIn(request['key'], ws);
      return;

    case CONNECTION_REG:
      removeRegister();
      return;

    case ERROR:
      error(request['message']);
      return;

    case OVERFLOW:
      error('Sie überschreiten die maximale Anzahl an Produkten.');
      handleOverflow(ws);
      return;

    case LOGIN_SUCCESS:
      hidePanel('#loginPanel');
      loggedIn(request['username'], request['id'], request['payout'],
          request['ammount'], jsonDecode(request['byCred'] ?? 'false'), ws);
      return;

    case LOGIN_FAILURE:
      error('Nutzername oder Passwort sind falsch');
      return;

    case LOGIN_REGISTER:
      hidePanel('#loginPanel');
      loginRegister(request['id'], ws);
      return;

    case LOGIN_INVALIDATE:
      invalidate();
      return;

    case LOGIN_ADMIN:
      initializeAdmin(request['id'], jsonDecode(request['stat']), ws);
      return;

    case REGISTER_SUCCESS:
      hidePanel('#registerPanel');
      registerSuccess(request['id']);
      querySelector('.welcome')?.style.display = 'flex';
      return;

    case ITEM_UPDATE:
      addItemToStorefront(request['name'], request['price'],
          int.parse(request['ammount']), request['id'], request['lsrc'], ws);
      querySelector('#ammountMarker')?.text =
          'Warenzahl: ' + request['ammountTotal'];
      return;

    case ITEM_UPDATE_SOLD:
      addSoldToStorefront(request['name'], request['price'], request['id']);
      return;

    case ITEM_UPDATE_TRASHED:
      addTrashedToStoreFron(
          request['name'], request['price'], request['id'], ws);
      return;

    case ITEM_UPDATE_TOTAL:
      querySelector('#ammountMarker')?.text =
          'Warenzahl: ' + request['ammountTotal'];
      return;

    case REGISTER_ITEM:
      registerItem(jsonDecode(request['item']), ws);
      return;

    case REGISTER_RECEIPT:
      generateReceipt(request['src'], request['change']);
      showPanel('#tipPanel');
      return;

    case REGISTER_BILL:
      addToBill(jsonDecode(request['item']), ws);
      return;

    case ADMIN_ADD_TRANSACTION:
      adminAddTr(request['id'], request['total'], request['items']);
      return;

    case ADMIN_ADD_USER:
      adminAddUser(request['id'], request['username'], request['payout'], ws);
      return;

    case ADMIN_ADD_UNCONFIRMED:
      addUnconfirmed(request['id'], request['name'], request['username'],
          request['email'], ws);
      return;

    case ADMIN_RECEIPT:
      savePOR(request['src'], request['id']);
      return;

    case ADMIN_ADD_EDIT:
      addToEdit(
          request['id'],
          request['username'],
          request['name'],
          jsonDecode(request['register']),
          jsonDecode(request['admin']),
          request['conum'],
          jsonDecode(request['emp']),
          ws);
      return;

    case ADMIN_ITEM_EDIT:
      adminAddLable(request['id'], request['src']);
      return;

    case ADMIN_PAYOUT_ALL:
      saveReceiptForAll();
      return;

    case ADMIN_WAITLIST_ADD:
      addWaiting(jsonDecode(request['pars']), ws);
      return;

    case ADMIN_WAITLIST_PRINT:
      drawWaitList();
      return;

    case PAGE_CLOSED:
      showPanel('#pageClosed');
      makeDt(request['dt']);
      return;
  }
  window.console.warn('unhandeled action $request');
}

///List to remember something but I forgot what
List remember = [];
