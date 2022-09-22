import 'dart:convert';
import 'dart:html';

import 'login.dart';
import 'panel.dart';
import 'websocket.dart';

///admin frontend initialized
void initializeAdmin(String id, Map stat, ClientWebSocket ws) {
  querySelector('#loginbutton')?.style.display = 'none';
  querySelector('.welcome')?.style.display = 'none';
  querySelector('#payout')
    ?..style.display = 'flex'
    ..text = stat['revenue'].toString();
  hidePanel('#loginPanel');
  (document.getElementById('comissionFee') as InputElement).value =
      stat['comissionFee'].toString();
  (document.getElementById('donation') as InputElement).value =
      stat['donation'].toString();
  querySelector('#accountbutton')
    ?..style.display = 'flex'
    ..text = 'Admin'
    ..onMouseEnter.listen((event) {
      querySelector('#accountbutton')?.text = 'Abmelden';
    })
    ..onMouseLeave.listen((event) {
      querySelector('#accountbutton')?.text = 'Admin';
    })
    ..onClick.listen((event) {
      invalidate();
      window.location.reload();
    });
  querySelector('#userView')?.onClick.listen((event) {
    showPanel('#userAdminView');
  });
  querySelector('#hideUserView')?.onClick.listen((event) {
    hidePanel('#userAdminView');
  });
  querySelector('#modVars')?.onClick.listen((event) {
    showPanel('#adminVarEdit');
  });
  querySelector('#saveVars')?.onClick.listen((event) {
    updateVars(ws);
    hidePanel('#adminVarEdit');
  });
  querySelector('#closeVarEdit')?.onClick.listen((event) {
    hidePanel('#adminVarEdit');
  });
  querySelector('#userEdit')?.onClick.listen((event) {
    showPanel('#adminUserEdit');
  });
  querySelector('#closeUserEdit')?.onClick.listen((event) {
    hidePanel('#adminUserEdit');
  });
  querySelector('#lableManage')?.onClick.listen((event) {
    showPanel('#labels');
  });
  querySelector('#closeLabels')?.onClick.listen((event) {
    hidePanel('#labels');
  });
  querySelector('#archiveAllConfirmed')?.onClick.listen((event) {
    ws.send('admin_archive_all');
    window.location.reload();
  });
  querySelector('#archiveAll')?.onClick.listen((event) {
    archiveAllClient(ws);
  });
  querySelector('#exitArchiveAll')?.onClick.listen((event) {
    hidePanel('#archiveWarn');
  });
  querySelector('#getAllPOR')?.onClick.listen((event) {
    ws.send('admin_payout_all');
  });
  querySelector('.admin')?.style.display = 'flex';
  ws.send('admin_get_users');
  final Storage ls = window.localStorage;
  ls['id'] = id;
}

///generates makes a download button for the receipt for all users
void saveReceiptForAll() {
  AnchorElement a = AnchorElement()
    ..text = 'Alle Rechnungen'
    ..href = 'por/whole.pdf'
    ..download = 'AlleRechnungen.pdf'
    ..classes.add('actionButton');
  a.onClick.listen((event) {
    a.remove();
  });
  querySelector('#adminButtonBar')?.append(a);
  querySelector('#adminUs')?.innerHtml = '';
}

///Archives all Users
void archiveAllClient(ClientWebSocket ws) {
  hidePanel('#adminUserEdit');
  showPanel('#archiveWarn');
}

///updates Variables for general management
void updateVars(ClientWebSocket ws) {
  String comissionFee =
      (document.getElementById('comissionFee') as InputElement).value!;
  String donation =
      (document.getElementById('donation') as InputElement).value!;
  ws.send('update_stat; comissionFee: $comissionFee; donation: $donation');
}

///adds users to pay out to admin storefront
void adminAddUser(
    String id, String username, String payout, ClientWebSocket ws) {
  ParagraphElement p = ParagraphElement()..text = 'Erhält: $payout Euro';
  DivElement userDiv = DivElement()
    ..style.display = 'flex'
    ..style.flexDirection = 'column'
    ..append(ParagraphElement()..text = 'Id: $id')
    ..append(ParagraphElement()..text = 'Nutzer: $username')
    ..append(p)
    ..append(ParagraphElement()..id = 'receipt$id')
    ..append(ButtonElement()
      ..classes.add('panelButton')
      ..text = 'Ausbezahlen'
      ..onClick.listen((event) {
        ws.send('admin_payout; id: $id');
        p.text = 'Erhält: 0.00 Euro';
      }));
  querySelector('#adminUs')?.append(userDiv);
}

///adds transaction to admin storefront
void adminAddTr(String id, String paid, String sl) {
  List l = jsonDecode(sl);
  String a = '';
  for (var i in l) {
    a = '$a, $i';
  }
  if (a == '') {
    return;
  }
  a = a.substring(2);

  DivElement trDiv = DivElement()
    ..style.display = 'flex'
    ..style.flexDirection = 'column'
    ..append(ParagraphElement()..text = 'Id: $id')
    ..append(ParagraphElement()..text = 'Bezahlt: $paid')
    ..append(ParagraphElement()..text = 'WarenIDs: $a');
  querySelector('#adminTr')?.append(trDiv);
}

///generates payout receipt download link
void savePOR(String src, String id) {
  AnchorElement a = AnchorElement(href: src);
  String n = src.split('/')[1];
  a
    ..text = 'Rechnung'
    ..download = n
    ..onClick.listen((event) {
      a.remove();
    });
  querySelector('#receipt$id')?.append(a);
}

///Add unconfirmed Users to panel to be confirmed
void addUnconfirmed(
    String id, String name, String username, String email, ClientWebSocket ws) {
  DivElement unconfirmed = DivElement();
  unconfirmed
    ..classes.add('unconfirmed')
    ..innerHtml =
        "<div>Id : $id</div><div>Nutzer: $username</div><div>Name: $name</div><div>E-Mail: $email</div>"
    ..append(ButtonElement()
      ..classes.add('panelButton')
      ..onClick.listen((event) {
        ws.send('admin_confirm; id: $id');
        unconfirmed.remove();
      })
      ..text = "Bestätigen");
  querySelector('#unconfirmed')?.append(unconfirmed);
}

///Adds a user to the admin user edit panel
void addToEdit(String id, String username, String name, bool register,
    bool admin, String conum, ClientWebSocket ws) {
  ParagraphElement p = ParagraphElement()..id = 'tags';
  if (register) {
    p.text = 'Kasse';
  } else if (admin) {
    p.text = 'Admin';
  }
  DivElement newUser = DivElement();
  newUser
    ..classes.add('userInEdit')
    ..innerHtml =
        '<div>Id: $id</div><div>Nutzer: $username </div><div>KOM: $conum</div><div>Name: $name</div>'
    ..append(DivElement()
      ..classes.add('flexrow')
      ..append(ButtonElement()
        ..text = 'Toggle'
        ..classes.add('panelButton')
        ..onClick.listen((event) {
          if (register) {
            p.text = '';
          } else {
            p.text = 'Kasse';
          }
          register = !register;
          ws.send('admin_make_register; id: $id');
        }))
      ..append(ButtonElement()
        ..text = 'Löschen'
        ..classes.add('panelButton')
        ..onClick.listen((event) {
          ws.send('admin_delete_user; id: $id');
          newUser.remove();
        }))
      ..append(ButtonElement()
        ..text = 'PW-R'
        ..classes.add('panelButton')
        ..onClick.listen((event) {
          ws.send('admin_password_reset; id: $id');
          newUser.remove();
        })))
    ..append(p);
  querySelector('#usersToEdit')?.append(newUser);
}

///Adds lable to admin label panel
void adminAddLable(String id, String src) {
  AnchorElement a = AnchorElement(href: src)
    ..classes.add('panelButton')
    ..download = '$id.pdf'
    ..text = 'Etikette $id';
  querySelector('#labelDiv')?.append(a);
}
