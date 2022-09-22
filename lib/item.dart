import 'dart:convert';
//import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:kleiderbazar/admin.dart';
import 'package:kleiderbazar/labelmngr.dart';
import 'package:kleiderbazar/user.dart';
import 'package:kleiderbazar/websockethandler.dart';
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

  Item(this.id, this.name, this.ammount, this.price, this.usrId, this.lablesrc,
      this.productType, this.size);
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
    'size': i.size
  };
}

///generates item from map from json
Item itemFromJson(Map m) {
  return Item(m['id'], m['name'], m['ammount'], m['price'], m['usrId'],
      m['lablesrc'], m['productType'], m['size']);
}

///List of all items
List<Item> allItems = getItems('item');

///List of sold items
List<Item> sold = getItems('sold');

///List of trashed items
List<Item> trashed = getItems('trashed');

///List of Items already in checkout
List<Item> marked = [];

///List of Items that couldn't be computed
List<Item> uncomputed = getItems('unc');

///generates items from saved json
List<Item> getItems(String sw) {
  List<Item> r = [];
  File f = File('.data/$sw.json');
  List l = jsonDecode(f.readAsStringSync());
  if (sw == 'item') {
    f = File('.data/marked.json');
    l.addAll(jsonDecode(f.readAsStringSync()));
  }
  for (var element in l) {
    r.add(itemFromJson(element));
  }

  return r;
}

///saves items to json
void saveItems(String sw) {
  List l = [];
  List<Item> sa = [];
  switch (sw) {
    case 'item':
      sa = allItems;
      break;
    case 'sold':
      sa = sold;
      break;
    case 'trashed':
      sa = trashed;
      break;
    case 'marked':
      sa = marked;
      break;
    case 'unc':
      sa = uncomputed;
      break;
  }

  for (Item i in sa) {
    l.add(itemToJson(i));
  }
  File f = File('.data/$sw.json');
  f.writeAsStringSync(jsonEncode(l));
}

///saves all ItemLists
void saveAllItems() {
  saveItems('item');
  saveItems('sold');
  saveItems('trashed');
  saveItems('marked');
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
  Item newItem = Item(id, name, ammount, price, usrId, lsrc, productType, size);

  u.ammounts[productType] += ammount;
  allItems.add(newItem);
  saveItems('item');
  saveUsers();
  int am = u.fullAmmount();
  wsc.sink.add(
      'item_update; name: $name; ammount: $ammount; price: $price; id: $id; lsrc: $lsrc; ammount: $am');
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
List maxes = [30, 50];

///generates new id for new item
int getItemId() {
  Random r = Random();
  int id = r.nextInt(stat['maxId']);
  while (itemIdTaken(id)) {
    id = r.nextInt(stat['maxId']);
  }
  return id;
}

///Checks if generated Item ID is already taken
bool itemIdTaken(int id) {
  for (Item i in allItems) {
    if (i.id == id) {
      return true;
    }
  }
  return false;
}

///sends items found by id to user
void sendItemsById(int id, WebSocketChannel wsc) {
  for (Item i in allItems) {
    if (i.usrId == id) {
      String name = i.name;
      int ammount = i.ammount;
      double price = i.price;
      int iid = i.id;
      String lsrc = i.lablesrc;
      wsc.sink.add(
          'item_update; name: $name; ammount: $ammount; price: $price; id: $iid; lsrc: $lsrc');
    }
  }
  for (Item i in sold) {
    if (i.usrId == id) {
      String name = i.name;
      double price = i.price;
      int iid = i.id;
      wsc.sink.add('item_update_sold; name: $name; price: $price; id: $iid');
    }
  }
  for (Item i in trashed) {
    if (i.usrId == id) {
      String name = i.name;
      double price = i.price;
      int iid = i.id;
      wsc.sink.add('item_update_trashed; name: $name; price: $price; id: $iid');
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
  for (Item i in allItems) {
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
        i.ammount--;
        u.ammounts[i.productType]--;
        if (i.ammount <= 0) {
          removeItem(i.id, trash, wsc);
        }
        remakeWhole(u.id, u.conum);
      }
      saveItems('item');
      saveUsers();
      return;
    }
  }
}

///removes an item from array and passes it back.
///Handles both checkout and delete.
///If bool trash is set Item is moved to trashed list
///else Item is moved to marked
Item? removeItem(int id, bool trash, WebSocketChannel wsc) {
  /*for (Item i in marked) {
    if (i.id == id) {
      getUserById(i.usrId)!.ammounts[i.productType] -= i.ammount;
      saveUsers();
      marked.remove(i);
      saveItems('item');
      //removeFile(File('web/label/print/$id.pdf'));
      //removeFile(File('web/label/qr/$id.png'));

      if (trash) remakeWhole(i.usrId, getUserById(i.usrId)!.conum);
      return i;
    }
  }*/
  List o = [];
  List g = [];
  if (trash) {
    o = allItems;
    g = trashed;
  } else {
    o = marked;
    g = sold;
  }
  for (Item i in o) {
    if (i.id == id) {
      g.add(i);
      o.remove(i);
      if (trash) {
        String name = i.name;
        double price = i.price;
        int iid = i.id;
        wsc.sink
            .add('item_update_trashed; name: $name; price: $price; id: $iid');
      }
      getUserById(i.usrId).ammounts[i.productType] -= i.ammount;
      saveUsers();
      saveAllItems();
      return i;
    }
  }
  return null;
}

///restores Item from trash
void itemUntrash(int id, WebSocketChannel wsc) {
  Item? ir;
  for (Item i in trashed) {
    if (i.id == id) {
      User u = getUserById(i.usrId);
      if (u == emptyUser) return;
      if (u.fullAmmount() + 1 >= stat['maxItem']) {
        wsc.sink.add('overflow');
      }
      ir = i;
      trashed.remove(i);
      break;
    }
  }
  Item it = ir ?? Item(-1, 'no', 0, 0, 0, '', 0, '');
  if (it.id != -1) {
    addItem(it.name, it.ammount, it.price.toString(), it.usrId, it.productType,
        it.size, wsc);
  }
}

///sends item to register frontend
void registerLookup(WebSocketChannel wsc, int id, bool b) {
  for (Item i in allItems) {
    /*String iid = i.id.toString();
    String iiid = id.toString();
    print('iid: $iid');
    print('iiid: $iiid');
    print(iid.contains(iiid));*/
    if (i.id.toString().contains(id.toString())) {
      Map m = itemToJson(i);
      String s = jsonEncode(m);
      if (b) {
        wsc.sink.add('register_item; item: $s');
      } else {
        if (i.id == id) {
          wsc.sink.add('register_bill; item: $s');
        }
      }
    }
  }
}

///Function for Lookup on scan:
void registerScan(WebSocketChannel wsc, int id) {
  for (Item i in allItems) {
    if (i.id == id) {
      Map m = itemToJson(i);
      String s = jsonEncode(m);
      wsc.sink.add('register_bill; item: $s');
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
    Item i = getItemFromCheckout(id);
    if (i.id == -1) {
      marked.add(i..id = id);
      uncomputed.add(i);
      saveItems('unc');
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
    saveAllItems();
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
  /*for (Item i in sold) {
    if (i.id == id) {
      return i;
    }
  }*/
  for (Item i in allItems) {
    if (i.id == id) {
      return i;
    }
  }
  for (Item i in sold) {
    if (i.id == id) {
      return i;
    }
  }
  for (Item i in marked) {
    if (i.id == id) {
      return i;
    }
  }
  return Item(-1, 'Ware konnte nicht gefunden werden', 0, 0.0, 0, '', 0, '');
}

///Function to remember the Items already in checkout
void registerMark(String id, WebSocketChannel wsc) {
  for (Item i in allItems) {
    if (i.id == int.parse(id)) {
      /*marked.add(Item(i.id, i.name, 1, i.price, i.usrId, i.lablesrc,
          i.productType, i.size));
      if (i.ammount - 1 == 0) {
        allItems.remove(i);
      } else {
        i.ammount--;
      }*/
      Item toMark = Item(
          i.id, i.name, 1, i.price, i.usrId, i.lablesrc, i.productType, i.size);
      marked.add(toMark);
      saveItems('marked');
      //itemModByOne(i.id, false, false, wsc);
      i.ammount--;
      if (i.ammount <= 0) {
        allItems.remove(i);
      }
      watchFor(toMark, wsc);
      saveItems('item');
      return;
    }
  }
  wsc.sink
      .add('error; message: Die Ware $id muss von Hand abgerechnet werden.');
  marked.add(Item(int.parse(id), '', 1, 0.0, 0, '', 0, ''));
  saveItems('marked');
}

///function that remove Item from List if ws closes without it being removed
void watchFor(Item i, WebSocketChannel wsc) async {
  while (marked.contains(i)) {
    if (!channelList[wsc]) {
      registerUnmark(i.id.toString());
      return;
    }
    await Future.delayed(Duration(seconds: 20));
  }
}

///removes Item from checkout if removed in client
void registerUnmark(String id) {
  for (Item i in marked) {
    if (i.id == int.parse(id)) {
      Item li = getItemById(int.parse(id));
      if (li.id == -1) {
        allItems.add(i);
      } else {
        li.ammount++;
      }
      marked.remove(i);
      saveItems('item');
      return;
    }
  }
}

///returnsItem from checkout
Item getItemFromCheckout(int id) {
  for (Item i in marked) {
    if (i.id == id) {
      return i;
    }
  }
  return Item(-1, 'Undefinierte Ware', 0, 0, 0, '', 0, '');
}

///makes an Item for custom add
void makeCustom(int conum, int id, double price, WebSocketChannel wsc) {
  int uid = -1;
  for (User u in allUsers) {
    if (u.conum == conum) uid = u.id;
  }
  Item i = Item(id, id.toString(), 1, price, uid, '', 1, '');
  allItems.add(i);
  saveAllItems();
  registerLookup(wsc, id, false);
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
