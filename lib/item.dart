import 'dart:convert';
//import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:kleiderbazar/actions.dart';
import 'package:kleiderbazar/admin.dart';
import 'package:kleiderbazar/labelmngr.dart';
import 'package:kleiderbazar/user.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
//import 'package:web_socket_channel/status.dart' as status;

import 'transaction.dart';

///Item class for articles to be sold
class Item {
  ///unique Item id
  late int id;

  ///Item name
  late String name;

  ///Amount of the same Items
  late int ammount;

  ///Item price
  late double price;

  ///Id of user who uploaded the Item
  late int usrId;

  ///source path to item Label
  late String lablesrc;

  ///indicator of Item type
  late int productType;

  ///Size in text format
  late String size;

  ///Item is Sold
  late int sold;

  ///Item is trashed
  late int trashed;

  ///Item is marked
  int marked = 0;

  Item(this.id, this.name, this.ammount, this.price, this.usrId, this.lablesrc,
      this.productType, this.size, this.sold, this.trashed);
}

///generates map to save item
Map itemToJson(Item i) {
  return {
    'id': i.id,
    'name': i.name,
    'ammount': i.ammount,
    'price': i.price,
    'usrId': i.usrId,
    'lablesrc': i.lablesrc,
    'productType': i.productType,
    'size': i.size,
    'sold': i.sold,
    'trashed': i.trashed
  };
}

///generates item from map from json
Item itemFromJson(Map m) {
  return Item(m['id'], m['name'], m['ammount'], m['price'], m['usrId'],
      m['lablesrc'], m['productType'], m['size'], m['sold'], m['trashed']);
}

///List of all items
List<Item> items = getItems('item');

///List of sold items
//List<Item> sold = getItems('sold');

///List of trashed items
//List<Item> trashed = getItems('trashed');

///List of Items already in checkout
//List<Item> marked = [];

///List of Items that couldn't be computed
//List<Item> uncomputed = getItems('unc');

///generates items from saved json
List<Item> getItems(String sw) {
  List<Item> r = [];
  File f = File('.data/$sw.json');
  List l = jsonDecode(f.readAsStringSync());
  /* if (sw == 'item') {
    f = File('.data/marked.json');
    l.addAll(jsonDecode(f.readAsStringSync()));
  } */
  for (var element in l) {
    r.add(itemFromJson(element));
  }
  return r;
}

///saves items to json
void saveItems(String sw) {
  List l = [];
  List<Item> sa = items;

  for (Item i in sa) {
    l.add(itemToJson(i));
  }
  File f = File('.data/$sw.json');
  f.writeAsStringSync(jsonEncode(l));
}

///saves new item and adds it to array
void addItem(String name, int ammount, String pr, int usrId, int productType,
    String size, WebSocketChannel wsc,
    {int? iid}) async {
  User u = getUserById(usrId);
  if (u == emptyUser) {
    print('User Nonexistent');
    return;
  }
  //int check = u.ammounts[0] + u.ammounts[1];
  //if ((check + ammount) > stat['maxItem']) {
  if (checkAmmount(u.ammounts, ammount, productType)) {
    wsc.sink.add('overflow');
    return;
  }
  double price = double.parse(pr);
  int id = iid ?? getItemId();
  String lsrc = await generateLabel(id, name, price, size, usrId, ammount);
  Item newItem =
      Item(id, name, ammount, price, usrId, lsrc, productType, size, 0, 0);

  u.ammounts[productType] += ammount;
  items.add(newItem);
  saveItems('item');
  saveUsers();
  int am = u.fullAmmount();
  wsc.sink.add(
      'item_update; name: $name; ammount: $ammount; price: $price; id: $id; lsrc: $lsrc; ammountTotal: $am');
}

bool checkAmmount(List ammounts, int ammount, int type) {
  if (isSeperated) {
    int c = ammounts[type] + ammount;
    return c > maxes[type];
  } else {
    int c = ammounts[0] + ammounts[1] + ammount;
    return c > stat['maxItem'];
  }
}

bool isSeperated = stat['isseperated'];
List maxes = stat['maxes'];

///generates new id for new item
int getItemId() {
  Random r = Random();
  int id = r.nextInt(999999);
  while (itemIdTaken(id)) {
    id = r.nextInt(999999);
  }
  return id;
}

///Checks if generated Item ID is already taken
bool itemIdTaken(int id) {
  for (Item i in items) {
    if (i.id == id) {
      return true;
    }
  }
  return false;
}

///sends items found by id to user
void sendItemsById(int id, WebSocketChannel wsc) {
  for (Item i in items) {
    if (i.usrId == id) {
      String name = i.name;
      int ammount = i.ammount - i.sold - i.trashed;
      double price = i.price;
      int iid = i.id;
      String lsrc = i.lablesrc;
      if (i.sold >= i.ammount) {
        wsc.sink.add('item_update_sold; name: $name; price: $price; id: $iid');
      } else if (i.trashed >= i.ammount) {
        wsc.sink
            .add('item_update_trashed; name: $name; price: $price; id: $iid');
      } else {
        int at = getUserById(i.usrId).fullAmmount();
        wsc.sink.add(
            'item_update; name: $name; ammount: $ammount; price: $price; id: $iid; lsrc: $lsrc; ammountTotal: $at');
      }
    }
  }
}

///modifies item amount by one +/-
void itemModByOne(int id, bool add, bool trash, WebSocketChannel wsc) {
  /*for (Item i in allItems) {
    if (i.id == id) {
      if (add) {
        User u = getUserById(i.usrId)!;
        int check = u.ammounts[0] + u.ammounts[1];
        if (check == stat['maxItem']) {
          wsc.sink.add('overflow');
          return null;
        }
        i.ammount++;
        u.ammounts[i.productType]++;
      } else {
        i.ammount--;
        getUserById(i.usrId)!.ammounts[i.productType]--;
        if (i.ammount <= 0) {
          allItems.remove(i);
        }
        r = Item(i.id, i.name, 1, i.price, i.usrId, i.lablesrc, i.productType,
            i.size);
      }
      saveUsers();
      saveItems();
      remakeWhole(i.usrId, getUserById(i.usrId)!.conum);
      return r;
    }
  }*/
  for (Item i in items) {
    if (i.id == id) {
      User u = getUserById(i.usrId);
      if (u == emptyUser) return;
      if (add) {
        if (checkAmmount(u.ammounts, 1, i.productType)) {
          wsc.sink.add('overflow');
        } else {
          u.ammounts[i.productType]++;
          i.ammount++;
          remakeWhole(u.id, u.conum);
        }
      } else {
        u.ammounts[i.productType]--;
        if (i.ammount <= 0) {
          removeItem(i.id, trash, wsc);
        }
        remakeWhole(u.id, u.conum);
      }
      saveItems('item');
      saveUsers();
      wsc.sink.add('$ITEM_UPDATE_TOTAL; ammountTotal: ${u.fullAmmount()}');
      return;
    }
  }
}

///removes an item from array and passes it back.
///Handles both checkout and delete.
///If bool trash is set Item is marked as trashed
///else Item is marked as marked
Item? removeItem(int id, bool trash, WebSocketChannel wsc) {
  for (Item i in items) {
    if (i.id == id) {
      if (trash) {
        i.trashed += i.ammount;
        wsc.sink.add(
            '$ITEM_UPDATE_TRASHED; name: ${i.name}; price: ${i.price}; id: ${i.id}');
      } else {
        i.sold++;
      }
      User u = getUserById(i.usrId);
      u.ammounts[i.productType] -= i.ammount;
      wsc.sink.add('$ITEM_UPDATE_TOTAL; ammountTotal: ${u.fullAmmount()}');
      wsc.sink.add('$ITEM_UPDATE_TOTAL; ammountTotal: ${u.fullAmmount()}');
      saveItems('item');
      saveUsers();
    }
  }
  return null;
}

///restores Item from trash
void itemUntrash(int id, WebSocketChannel wsc) {
  Item? ir;
  for (Item i in items) {
    if (i.id == id) {
      ir = i;
      break;
    }
  }
  Item it = ir ?? Item(-1, 'no', 0, 0, 0, '', 0, '', 0, 0);
  if (it.id != -1) {
    addItem(it.name, it.ammount, it.price.toString(), it.usrId, it.productType,
        it.size, wsc);
  }
}

///sends item to register frontend
void registerLookup(WebSocketChannel wsc, int id, bool b) {
  for (Item i in items) {
    /*String iid = i.id.toString();
    String iiid = id.toString();
    print('iid: $iid');
    print('iiid: $iiid');
    print(iid.contains(iiid));*/
    if (b) {
      if (i.id.toString().contains(id.toString())) {
        Map m = itemToJson(i);
        String s = jsonEncode(m);
        wsc.sink.add('register_item; item: $s');
      }
    } else {
      if (i.id == id) {
        i.marked++;
        String s = jsonEncode(itemToJson(i));
        wsc.sink.add('register_bill; item: $s');
        return;
      }
    }
  }
}

///Function for Lookup on scan:
void registerScan(WebSocketChannel wsc, int id) {
  for (Item i in items) {
    if (i.id == id) {
      Map m = itemToJson(i);
      String s = jsonEncode(m);
      wsc.sink.add('register_bill; item: $s');
      i.marked++;
      saveItems('item');
      return;
    }
  }
}

///computes finished purchase
void registerCheckout(
    WebSocketChannel wsc, List l, String total, String given) async {
  if (given == '') {
    wsc.sink.add('error; message: Bitte Gegebenes Geld Eingeben.');
    return;
  }
  double tt = double.parse(total);
  Tr t = addTr(tt);
  for (int id in l) {
    t.addItem(id);
    Item i = getItemById(id);
    if (i.id == -1) {
      i.marked--;
      i.sold++;
    }
    /*if (i.ammount == 1) {
      removeItem(id, false);
    } else {
      i.ammount--;
      getUserById(i.usrId)!.ammounts[i.productType]--;
      saveUsers();
      sold.add(Item(i.id, i.name, 1, i.price, i.usrId, i.lablesrc,
          i.productType, i.size));
    }*/
    removeItem(id, false, wsc);
    saveItems('item');
    saveTr();
  }
  Map m = await makeReceipt(t, double.parse(given));
  wsc.sink.add('register_receipt; src: ${m['src']}; change: ${m['change']}');
}

///generates sold receipt
Future<Map> makeReceipt(Tr t, double given) async {
  Map r = {};
  int id = t.id;
  File f = File('web/receipts/$id.txt');
  await f.create();
  double total = 0;
  String s =
      'Rechnungsnummer: $id\n\n--------------------------------------------------------------\n';
  for (int iid in t.items) {
    Item i = getItemById(iid);
    total = ((total + i.price) * 100).round() / 100;
    User u = getUserById(i.usrId);
    if (u == emptyUser) return {'src': '', 'change': 0.0};
    u.payout = ((u.payout + i.price - addRevenue(i.price)) * 100).round() / 100;
    saveUsers();
    s += 'Ware: ' +
        i.name +
        '\nPreis: ' +
        i.price.toString() +
        'Euro\nWarenID: ' +
        i.id.toString() +
        '\n\n--------------------------------------------------------------\n';
  }
  double change = given - total;
  s +=
      'Zu zahlen: $total Euro\n\n--------------------------------------------------------------\nBezahlt: $given\nRueckgeld: $change\nVielen Dank';
  await f.writeAsString(s);
  r['src'] = 'receipts/$id.txt';
  r['change'] = change;
  return r;
}

///gets item by id from either sold, unsold, or marked
Item getItemById(int id) {
  for (Item i in items) {
    if (i.id == id) {
      return i;
    }
  }
  return Item(
      -1, 'Ware konnte nicht gefunden werden', 0, 0.0, 0, '', 0, '', 0, 0);
}

///removes Item from checkout if removed in client
void registerUnmark(String id) {
  int iid = int.parse(id);
  Item i = getItemById(iid);
  if (i.marked > 0) i.marked--;
}

///makes an Item for custom add
void makeCustom(int conum, int id, double price, WebSocketChannel wsc) {
  int uid = -1;
  for (User u in activeUsers) {
    if (u.conum == conum) uid = u.id;
  }
  Item i = Item(id, id.toString(), 1, price, uid, '', 1, '', 0, 0);
  items.add(i);
  saveItems('item');
  String s = jsonEncode(itemToJson(i));
  wsc.sink.add('register_bill; item: $s');
}

///Function that remembers tips given by register
void registerTip(double tip, int id) {
  double newTip = registerTipMap[id.toString()] + tip;
  registerTipMap[id.toString()] = double.parse(newTip.toStringAsFixed(2));
  saveTips();
}

///Map of registers to tips
Map registerTipMap = getRegisterTipMap();

///generates Register-Tip map
///Map knows which register got which tips
Map getRegisterTipMap() {
  List rids = [];
  Map r = {};
  for (User u in activeUsers) {
    if (u.register) {
      rids.add(u.id);
    }
  }
  File f = File('.data/registerTip.json');
  r = jsonDecode(f.readAsStringSync());
  for (int id in rids) {
    if (!r.containsKey(id.toString())) {
      r[id.toString()] = 0.0;
    }
  }

  return r;
}

///Really short function to save tip map
void saveTips() {
  File('.data/registerTip.json').writeAsStringSync(jsonEncode(registerTipMap));
}
