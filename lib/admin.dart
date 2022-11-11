import 'dart:convert';
import 'dart:io';

import 'package:kleiderbazar/item.dart';
import 'package:kleiderbazar/transaction.dart';
import 'package:kleiderbazar/user.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

///sends users and transactions to admin frontend
void adminGetAll(WebSocketChannel wsc) {
  for (User u in activeUsers) {
    int id = u.id;
    String username = u.username;
    bool reg = u.register;
    bool adm = u.admin;
    String name = u.name;
    int conum = u.conum;
    wsc.sink.add(
        'admin_add_edit; id: $id; username: $username; register: $reg; admin: $adm; name: $name; conum: $conum');
    if (!u.admin && !u.register && u.payout > 0) {
      double payout = u.payout;
      wsc.sink
          .add('admin_add_user; id: $id; username: $username; payout: $payout');
    }
  }
  for (Tr t in allTr) {
    int id = t.id;
    List items = t.items;
    double total = t.total;
    wsc.sink
        .add('admin_add_transaction; id: $id; items: $items; total: $total');
  }
  for (User u in unconfirmed) {
    int id = u.id;
    String username = u.username;
    String name = u.name;
    String email = u.email;
    wsc.sink.add(
        'admin_add_unconfirmed; id: $id; username: $username; name: $name; email: $email');
  }
  for (Item i in items) {
    int id = i.id;
    String src = i.lablesrc;
    wsc.sink.add('admin_item_edit; id: $id; src: $src');
  }
}

///computes payout for seller
void payout(int id, WebSocketChannel wsc) async {
  for (User u in activeUsers) {
    if (u.id == id) {
      String src = await makePayoutReceipt(u);
      u.payout = 0;
      saveUsers();
      wsc.sink.add('admin_receipt; src: $src; id: $id');
      return;
    }
  }
}

///generates all Payout Receipts in one Button Click

void adminPayoutAll(WebSocketChannel wsc) async {
  final pdfFile = pw.Document();
  for (User u in activeUsers) {
    if (!u.register && !u.admin) {
      String receipt = await makePayoutReceipt(u);
      File f = File('web/$receipt');
      List<String> addList = f.readAsLinesSync();
      String addThis = '';
      int lineCounter = 0;
      for (String s in addList) {
        if (lineCounter == 50) {
          pdfFile.addPage(makePayoutPage(addThis));
          lineCounter = 0;
          addThis = '';
        }
        addThis += s + '\n';
        lineCounter++;
      }
      pdfFile.addPage(makePayoutPage(addThis));
      u.payout = -5.0;
    }
  }
  File f = File('web/por/whole.pdf')..create();
  f.writeAsBytesSync(await pdfFile.save());
  wsc.sink.add('admin_payout_all');
  saveUsers();
}

///make page for payout all
pw.Page makePayoutPage(String s) {
  return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(0.2),
      build: (pw.Context context) {
        return pw.Align(child: pw.Text(s));
      });
}

///generates Payout Receipt and sends it to seller
Future<String> makePayoutReceipt(User u) async {
  String dt = DateTime.now().toString().split('.')[0];
  int id = u.id;
  String r = 'web/por/$id-$dt.txt';
  File f = File(r);
  await f.create();
  String sep =
      '**************************************************************************************\n';
  String write = sep +
      'Abrechnung Kinderbasar Gomaringen                     ' +
      dt +
      '\n' +
      'Kommission: ' +
      u.conum.toString() +
      '                                              ' +
      u.name +
      '\n' +
      sep;
  double hold = 0;
  for (Item i in items) {
    if (i.usrId == id) {
      while (i.sold > 0) {
        i.sold--;
        String s = i.name + ':\t' + i.price.toStringAsFixed(2) + '\t\t\tEuro\n';
        write += s;
        hold += i.price;
      }
    }
  }
  write += sep +
      'Summe:                                                                ' +
      hold.toString() +
      '\tEuro\nabzgl. ' +
      (100 * stat['comissionFee']).toStringAsFixed(2) +
      '% Spende                                         ' +
      (hold * stat['comissionFee']).toStringAsFixed(2) +
      '\tEuro\nabzgl. Bearbeitungsgebühr                                  ' +
      stat['donation'].toStringAsFixed(2) +
      '\tEuro\n' +
      sep +
      'Auszahlungsbetrag für Komission ' +
      u.conum.toString() +
      '                     ' +
      (hold - (hold * stat['comissionFee']) - stat['donation'])
          .toStringAsFixed(1) +
      '0\tEuro\n';
  write += sep + endstring + sep;

  await f.writeAsString(write);
  return r.substring(4);
}

String endstring =
    '\nAnfragen zu vermissten Artikeln unter basarsupport@cvjm-gomaringen.de \nDer nächste Kinderbasar findet am 25.9.22 in der Sport- und Kulturhalle \nGomaringen statt.\n\n';

///confirm user accounts
void adminConfirm(int id, WebSocketChannel wsc) {
  for (User u in unconfirmed) {
    if (u.id == id) {
      activeUsers.add(u);
      unconfirmed.remove(u);
      saveUnconfirmed();
      saveUsers();
      String username = u.username;
      String name = u.name;
      bool reg = u.register;
      bool adm = u.admin;
      int conum = u.conum;
      updateEmailList();
      wsc.sink.add(
          'admin_add_edit; id: $id; username: $username; register: $reg; admin: $adm; name: $name; conum: $conum');
      return;
    }
  }
  wsc.sink.add('error; message: Account konnte nicht bestätigt werden.');
}

///Updates the Status Info
void updateStat(String comissionFee, String donation) {
  stat['comissionFee'] = double.parse(comissionFee);
  stat['donation'] = double.parse(donation);
  saveStat();
}

///adds a Value to Revenue and returns the payout for the User
double addRevenue(double price) {
  double d = ((price * stat['comissionFee']) * 100).floor() / 100;
  //double r = price * (1 - stat['comissionFee']);

  stat['revenue'] = ((stat['revenue'] + d) * 100).floor() / 100;

  saveStat();

  return d;
}

Map stat = getStat();

///gets Status Info
Map getStat() {
  File f = File('.data/stat.json');
  Map m = jsonDecode(f.readAsStringSync());
  return m;
}

///saves Status Info
void saveStat() {
  File f = File('.data/stat.json');
  f.writeAsStringSync(jsonEncode(stat));
}

///toggles Register Status of a user
void adminMakeRegister(int id) {
  User u = getUserById(id);
  if (u == emptyUser) return;
  u.register = !u.register;
  stat['maximumUser']++;
  updateEmailList();
  saveUsers();
  saveStat();
}

///deletes User and saves it to deleted
void adminDeleteUser(int id) {
  User u = getUserById(id);
  if (u == emptyUser) return;
  deleted.add(u);
  activeUsers.remove(u);
  updateEmailList();
  for (Item i in items) {
    if (i.usrId == id) {
      items.remove(i);
    }
  }
  stat['maximumUser']++;
  updateEmailList();
  saveDeleted();
  saveUsers();
  saveItems('item');
  saveStat();
}

///Archives all files
void adminArchiveAll() async {
  File del = File('.data/deleted.json');
  File ite = File('.data/item.json');
  File sol = File('.data/sold.json');
  File sta = File('.data/stat.json');
  File trl = File('.data/tr.json');
  File unc = File('.data/unconfirmed.json');
  File use = File('.data/user.json');
  File res = File('.data/reset.json');
  DateTime today = DateTime.now();

  archiveLables();

  await File('.data/.dataarchive/$today-deleted.json')
      .writeAsString(await del.readAsString());
  await del.writeAsString('[]');
  await File('.data/.dataarchive/$today-item.json')
      .writeAsString(await ite.readAsString());
  await ite.writeAsString('[]');
  await File('.data/.dataarchive/$today-sol.json')
      .writeAsString(await sol.readAsString());
  await sol.writeAsString('[]');
  await File('.data/.dataarchive/$today-stat.json')
      .writeAsString(await sta.readAsString());
  await sta.writeAsString(
      '{"revenue":2.40,"comissionFee":${stat['comissionFee']},"donation":${stat['donation']},"sr":"eTkr5sqD67vLSVnWw1OuCrRhuoh5f2ad","bareUserNum":0,"maximumUser":150,"maxItem":130,"maxId":10000,"dLower":"2022-05-21 00:00:00","dUpper":"2022-05-21 10:00:00","isseperated":${stat['isseperated']}}');
  await File('.data/.dataarchive/$today-tr.json')
      .writeAsString(await trl.readAsString());
  await trl.writeAsString('[]');
  await File('.data/.dataarchive/$today-unconfirmed.json')
      .writeAsString(await unc.readAsString());
  await unc.writeAsString('[]');
  await File('.data/.dataarchive/$today-user.json')
      .writeAsString(await use.readAsString());
  await File('.data/dataarchive/$today-reset.json')
      .writeAsString(await res.readAsString());
  await res.writeAsString('[]');
  //use.writeAsString('[]');

  deleted = getDeleted();
  items = getItems('item');
  allTr = getTr();
  freeUsers();
  unconfirmed = getUnconfirmed();
  stat = getStat();
}

void archiveLables() async {
  remFromDir(Directory('web/label/print'));
  remFromDir(Directory('web/label/qr'));
  remFromDir(Directory('web/label/wholes'));
  File('web/label/emails.txt').writeAsString('');
}

///removes all Files in directory
void remFromDir(Directory d) async {
  await for (var f in d.list(recursive: true, followLinks: false)) {
    if (f.path.contains('.g')) continue;
    f.delete();
  }
}

///Saves Admin accounts during archiving
void freeUsers() {
  List<User> l = [];
  for (User u in activeUsers) {
    if (u.admin || u.register) {
      l.add(u);
    }
  }
  activeUsers = l;
  saveUsers();
}

///resets a Users Password
void adminResetPassword(int id, WebSocketChannel wsc) {
  User u = getUserById(id);
  if (u == emptyUser) return;
  resetUsers.add(u);
  activeUsers.remove(u);
  saveReset();
  saveUsers();
  stat['maximumUser']++;
  saveStat();
}
