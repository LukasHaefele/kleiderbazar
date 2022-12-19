import 'dart:convert';
import 'dart:html';

import 'login.dart';
import 'panel.dart';
import 'qr.dart';
import 'qrscanner.dart';
import 'websocket.dart';

///register frontend initialization
List<int> re = [];
void initRegister(ClientWebSocket ws) {
  QRScanner? qs;
  querySelector('.register')?.style.display = 'flex';
  querySelector('#qrScan')?.onClick.listen((event) {
    qs = initQrscanner(ws);
    showPanel('#qrScanner');
  });
  modNumber(0);
  querySelector('#qrScanClose')?.onClick.listen((event) {
    qs!.clearScanner();
    querySelector('#qrSep')?.innerHtml = '';
    hidePanel('#qrScanner');
  });
  InputElement searchId = document.getElementById('itemIdIn') as InputElement;
  searchId.onChange.listen((event) {
    clearRegSearch();
    String id = '0';
    if (searchId.value != null) {
      id = searchId.value!;
      print('searchID: $id');
    }
    if (id != '') {
      ws.send('register_lookup; id: $id');
    }
  });
  initCustom(ws);
  initTip(ws);
  querySelector('#checkoutButton')?.onClick.listen((event) {
    String s = jsonEncode(re);
    InputElement inp = (document.getElementById('given') as InputElement);
    String g = (inp).value as String;
    inp.value = '';
    ws.send('register_checkout; items: $s; total: $billTotal; giv: $g');
  });
}

///Initializes the tip panel
void initTip(ClientWebSocket ws) {
  querySelector('#openTip')?.onClick.listen((event) {
    showPanel('#tipPanel');
  });
  querySelector('#closeTip')?.onClick.listen((event) {
    hidePanel('#tipPanel');
  });
  querySelector('#sendTip')?.onClick.listen((event) {
    String tip = (querySelector('#tipIn')! as InputElement).value!;
    if (tip == '' || tip == '0.0') {
      error(
          'Bitte geben sie einen Betrag ein. Wenn kein Trinkgeld gegeben wurde schließen sie das Feld.');
      return;
    }
    ws.send('register_tip; tip: $tip; id: ${localId()}');
    hidePanel('#tipPanel');
  });
}

///Initializes the custom item panel
void initCustom(ClientWebSocket ws) {
  querySelector('#addCustom')?.onClick.listen((event) {
    showPanel('#addCustomPanel');
  });
  querySelector('#customClose')?.onClick.listen((event) {
    hidePanel('#addCustomPanel');
  });
  querySelector('#customSend')?.onClick.listen((event) {
    String conum = (querySelector('#customConum')! as InputElement).value!;
    String id = (querySelector('#customId')! as InputElement).value!;
    String price = (querySelector('#customPrice')! as InputElement).value!;
    ws.send('register_add_custom; conum: $conum; id: $id; price: $price');
  });
}

///Modifies Number of Scanned Items
void modNumber(int n) {
  numScanned = n;
  querySelector('#amountItems')?.text = 'Anzahl: $numScanned';
}

///Amount of scanned items
int numScanned = 0;

///register id search results
void registerItem(Map m, ClientWebSocket ws) {
  DivElement newDiv = generateItem(m);
  newDiv.append(DivElement()
    ..classes.add('flexrow')
    ..append(ButtonElement()
      ..classes.add('registerButton')
      ..text = 'Hinzufügen'
      ..onClick.listen((event) {
        addToBill(m, ws);
        reduceRes(newDiv, m);
      })));
  querySelector('#searchres')?.append(newDiv);
}

///Add Item to bill
void addToBill(Map m, ClientWebSocket ws) {
  ws.send('register_mark; id: ' + m['id'].toString());
  modNumber(numScanned + 1);
  //querySelector('#change')?.text = '';
  re.add(m['id']);
  DivElement newDiv = generateItem(m);
  newDiv.append(DivElement()
    ..classes.add('flexrow')
    ..append(ButtonElement()
      ..classes.add('registerButton')
      ..text = 'Entfernen'
      ..onClick.listen((event) {
        ws.send('register_unmark; id: ' + m['id'].toString());
        modNumber(numScanned - 1);
        newDiv.remove();
        m['ammount']++;
        if (m['ammount'] == 1 && re.contains(m['id'])) {
          registerItem(m, ws);
        }
        updateBillTotal(0.0 - m['price']);
        re.remove(m['id']);
      })));
  querySelector('#billList')!.insertAdjacentElement('afterbegin', newDiv);
  updateBillTotal(getDouble(m['price'].toString()));
}

///reduces amount of server saved Item
void reduceRes(DivElement div, Map m) {
  m['ammount']--;
  if (m['ammount'] > 0) {
    div = generateItem(m);
  } else {
    div.remove();
  }
}

///parses String to double
double getDouble(String pr) {
  if (pr.contains('.')) {
    return jsonDecode(pr);
  } else {
    return jsonDecode('$pr.0');
  }
}

///updates the total amount to pay
void updateBillTotal(double d) {
  billTotal = ((billTotal + d) * 100).round() / 100;
  String s = billTotal.toString();
  querySelector('#total')?.text = 'Total: $s€';
}

double billTotal = 0.0;

///generates the item to be added to the id search results
DivElement generateItem(Map m) {
  DivElement newDiv = DivElement()
    ..classes.add('flexcol')
    ..append(ParagraphElement()..text = 'Warenname: ' + m['name'])
    ..append(ParagraphElement()..text = 'Preis: ' + m['price'].toString() + '€')
    ..append(ParagraphElement()..text = 'Warenid: ' + m['id'].toString());
  return newDiv;
}

///clears search results
void clearRegSearch() {
  querySelector('#searchres')?.innerHtml = '';
}

///generates receipt download link
void generateReceipt(String s, String d) {
  querySelector('#change')?.text = 'Rückgeld: $d€';
  AnchorElement a = AnchorElement(href: s);
  a
    ..text = 'Rechnung'
    ..download = 'Rechnung.' + DateTime.now().toString() + '.txt'
    ..onClick.listen((event) {
      a.remove();
    });
  querySelector('#checkoutA')
    ?..innerHtml = ' '
    ..append(a);
  clearBill();
}

///clears the bill for the next customer
void clearBill() {
  modNumber(0);
  querySelector('#billList')?.innerHtml = '';
  billTotal = 0.0;
  updateBillTotal(0);
  re = [];
}
