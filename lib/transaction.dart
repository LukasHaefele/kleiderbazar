import 'dart:convert';
import 'dart:io';

///transaction class for Kleiderbazar
class Tr {
  ///unique transaction id
  late int id;

  ///total ammount owed
  late double total;

  ///List of item Ids in this transaction
  late List items;

  Tr(this.id, this.items, this.total);

  ///adds Item to list of ids
  void addItem(int id) {
    items.add(id);
  }
}

///generates map from transaction
Map trToJson(Tr t) {
  return {'id': t.id, 'total': t.total, 'items': t.items};
}

///generates transaction from map from json
Tr trFromJson(Map m) {
  return Tr(m['id'], m['items'], m['total']);
}

List<Tr> allTr = getTr();

///generates transactions from json
List<Tr> getTr() {
  File f = File('.data/tr.json');
  List<Tr> r = [];
  List l = jsonDecode(f.readAsStringSync());
  for (var e in l) {
    r.add(trFromJson(e));
  }
  return r;
}

///saves all transactions to json
void saveTr() {
  List l = [];
  for (Tr t in allTr) {
    l.add(trToJson(t));
  }
  File f = File('.data/tr.json');
  f.writeAsStringSync(jsonEncode(l));
}

///adds transaction to json and array
Tr addTr(double total) {
  Tr t = Tr(getTrId(), [], total);
  allTr.add(t);
  saveTr();
  return t;
}

///generate new id for new transaction
int getTrId() {
  /*if (allTr.isEmpty) {
    return 0;
  }
  return allTr[allTr.length - 1].id + 1;*/

  int dt1 = DateTime(2021, 12).millisecondsSinceEpoch;
  int dt2 = DateTime.now().millisecondsSinceEpoch;
  int id = ((dt2 - dt1) / 500).floor();
  return id;
}
