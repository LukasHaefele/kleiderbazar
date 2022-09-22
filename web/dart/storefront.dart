import 'dart:html';

import 'login.dart';
import 'panel.dart';
import 'websocket.dart';

///User storefront initialization
void initStorefront(ClientWebSocket ws, String id) {
  querySelector('#soldItems')?.innerHtml =
      'Es wurden noch keine deiner Waren verkauft.';
  querySelector('.storefront')?.style.display = 'flex';
  querySelector('#addItem')?.onClick.listen((event) {
    showPanel('#uploadItem');
  });
  querySelector('#exitButton')?.onClick.listen((event) {
    hidePanel('#uploadItem');
  });
  querySelector('#itemUploadButton')?.onClick.listen((event) {
    uploadItem(ws);
  });
  querySelector('#soldButton')?.onClick.listen((event) {
    print('show sold');
    showPanel('#soldItemsPanel');
  });
  querySelector('#hideSold')?.onClick.listen((event) {
    hidePanel('#soldItemsPanel');
  });
  querySelector('#aHint')
    ?..onMouseEnter.listen((event) {
      querySelector('#aText')?.style.display = 'unset';
    })
    ..onMouseLeave.listen((event) {
      querySelector('#aText')?.style.display = 'none';
    });
  querySelector('#trashClose')?.onClick.listen(((event) {
    hidePanel('#trashcan');
  }));
  querySelector('#trashButton')?.onClick.listen(((event) {
    showPanel('#trashcan');
  }));
  (querySelector('.logo') as ImageElement).src = 'style/media/bazar.png';
  AnchorElement aqLabels = querySelector('#allLabels') as AnchorElement;
  aqLabels
    ..download = 'AllLabels.pdf'
    ..href = 'label/wholes/$id.pdf';
  SelectElement inelem = querySelector('#productType') as SelectElement;
  inelem.onChange.listen((event) {
    if (inelem.value! == '0') {
      querySelector('#psize')?.style.display = 'block';
      querySelector('#size')?.style.display = 'block';
      querySelector('#hsize')?.style.display = 'block';
    } else {
      querySelector('#psize')?.style.display = 'none';
      querySelector('#size')?.style.display = 'none';
      querySelector('#hsize')?.style.display = 'none';
    }
  });
  ws.send('item_claim; id: $id');
}

///add an Item to server saved items
void uploadItem(ClientWebSocket ws) {
  String name =
      (document.getElementById('itemname') as InputElement).value as String;
  String ammount =
      (document.getElementById('ammount') as InputElement).value as String;
  String price =
      (document.getElementById('price') as InputElement).value as String;
  String productType =
      (document.getElementById('productType') as SelectElement).value as String;
  String id = localId();
  if (productType == '') {
    error('Bitte wählen sie einen Produkt Typen aus.');
    return;
  } else if (productType == '0') {
    String? size = (document.getElementById('size') as InputElement).value;
    if (size == null) {
      error('Bitte alle Felder ausfüllen');
    }
    ws.send(
        'item_upload; name: $name; ammount: $ammount; price: $price; usrId: $id; productType: $productType; size: $size');
  } else {
    ws.send(
        'item_upload; name: $name; ammount: $ammount; price: $price; usrId: $id; productType: $productType');
  }
}

///Add an item received by the server to storefront
void addItemToStorefront(String name, String price, int ammount, String id,
    String lsrc, ClientWebSocket ws) {
  DivElement item = DivElement();
  AnchorElement a = AnchorElement(href: lsrc);
  a
    ..download = '$id-Etikette.pdf'
    ..text = 'Etikette';
  item
    ..id = 'item$id'
    ..classes.add('item')
    ..innerHtml =
        '<div>$name</div><div>Preis: $price</div><div id="menge$id">Menge: $ammount</div><div>Id: $id</div><div class="etikette" id="etikette$id"></div>'
    ..append(DivElement()
      ..classes.add('flexrow')
      ..append(ButtonElement()
        ..text = 'Löschen'
        ..onClick.listen((event) {
          ws.send('item_delete; id: $id');
          item.remove();
        })
        ..classes.add('itemButton'))
      ..append(DivElement()
        ..classes.add('flexrow')
        ..append(ButtonElement()
          ..onClick.listen((event) {
            ws.send('item_delete_one; id: $id');
            ammount--;
            if (ammount > 0) {
              querySelector('#menge$id')?.text = 'Menge: $ammount';
            } else {
              item.remove();
            }
          })
          ..text = '-1'
          ..classes.add('modButton'))
        ..append(ButtonElement()
          ..onClick.listen((event) {
            ws.send('item_add_one; id: $id');
            ammount++;
            querySelector('#menge$id')?.text = 'Menge: $ammount';
          })
          ..text = '+1'
          ..classes.add('modButton'))));
  querySelector('.itemDiv')?.append(item);
  querySelector('#etikette$id')?.append(a);
  hidePanel('#uploadItem');
  hidePanel('#trashcan');
}

///Adds Trashed Items to Storefront
void addTrashedToStoreFron(
    String name, String price, String id, ClientWebSocket ws) {
  DivElement item = DivElement();
  item
    ..classes.add('item')
    ..innerHtml = '<div>$name</div><div>Preis: $price</div><div>Id: $id</div>'
    ..append(ButtonElement()
      ..classes.add('panelButton')
      ..text = 'Restore')
    ..onClick.listen((event) {
      ws.send('item_untrash; id: $id');
      item.remove();
    });
  querySelector('#trashItems')?.append(item);
}

///Adds sold Items to user sold panel
void addSoldToStorefront(String name, String price, String id) {
  DivElement item = DivElement();
  item
    ..classes.add('item')
    ..classes.add('sold')
    ..innerHtml = '<div>$name</div><div>Preis: $price</div><div>Id: $id</div>';

  DivElement sp = (document.getElementById('soldItems')) as DivElement;
  if (sp.innerHtml == 'Es wurden noch keine deiner Waren verkauft.') {
    sp.innerHtml = '';
  }
  sp.append(item);
}

///handles if too many items are added by one user
void handleOverflow(ClientWebSocket ws) {
  querySelector('.itemDiv')?.innerHtml = '';
  String id = localId();
  ws.send('item_claim; id: $id');
}
