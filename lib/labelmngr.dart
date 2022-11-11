import 'dart:io';
//import 'dart:typed_data';

//import 'package:kleiderbazar/item.dart';
import 'package:kleiderbazar/item.dart';
import 'package:kleiderbazar/user.dart';
import 'package:qr/qr.dart';
import 'package:image/image.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

///Generating a label with qr code
Future<String> generateLabel(int id, String name, double price, String size,
    int userid, int ammount) async {
  QrCode qr = QrCode(1, QrErrorCorrectLevel.L);
  qr.addData('$id');
  qr.make();
  String qsrc = await renderQr(qr, id);

  String lsrc = await getLabel(qsrc, id, name, price, size, userid, ammount);

  return lsrc;
}

///Putting together the lable from parts
Future<String> getLabel(String qsrc, int id, String name, double price,
    String size, int userid, int ammount) async {
  final label = pw.Document();
  int conum = getUserById(userid).conum;
  final whole = makeWhole(userid, conum);
  String wsrc = 'label/wholes/$userid.pdf';
  File saveWhole = File('web/$wsrc');
  String pr = price.toStringAsFixed(2);
  //int conum = getUserById(userid)!.conum;
  String lableText = '\n$name';
  if (size != '') {
    lableText = lableText + '\nGröße: $size';
  }
  lableText = lableText + '\n$pr Euro\n' + id.toString() + '\n\n';
  final qrImage = pw.MemoryImage(File(qsrc).readAsBytesSync());
  for (int i = 0; i < ammount; i++) {
    label.addPage(makePage(lableText, qrImage, conum));
    whole.addPage(makePage(lableText, qrImage, conum));
  }
  String lsrc = 'label/print/$id.pdf';
  File savePdf = File('web/$lsrc')..createSync();
  //saveWhole.writeAsBytesSync(await whole.save());
  saveWhole.writeAsBytesSync(await whole.save());
  savePdf.writeAsBytesSync(await label.save());
  return lsrc;
}

///makes page for items given
pw.Page makePage(String lableText, pw.MemoryImage qrImage, int conum) {
  return pw.Page(
      pageFormat: PdfPageFormat(200, 420),
      build: (pw.Context context) {
        return pw.Center(
            child: pw.Column(children: [
          pw.Text('\nO', style: pw.TextStyle(fontSize: 20)),
          pw.Text(lableText,
              style:
                  pw.TextStyle(fontSize: 20, fontBold: pw.Font.courierBold())),
          pw.Image(qrImage, width: 160, height: 160),
          pw.Text('\nKOM: $conum',
              style: pw.TextStyle(fontSize: 25, fontWeight: pw.FontWeight.bold))
        ]));
      });
}

///remakes PDF with all Lables for one user whenever there is a change
void remakeWhole(int id, int conum) async {
  final whole = makeWhole(id, conum);
  String wsrc = 'label/wholes/$id.pdf';
  File saveWhole = File('web/$wsrc');
  saveWhole.writeAsBytesSync(await whole.save());
}

///makes whole for first time
pw.Document makeWhole(int id, int conum) {
  final whole = pw.Document();
  for (Item i in items) {
    if (i.usrId == id && (i.sold + i.trashed) < i.ammount) {
      String iname = i.name;
      String lableText = '\n$iname';
      String size = i.size;
      double pr = i.price;
      int iid = i.id;
      String qsrc = 'web/label/qr/$iid.png';
      if (!File(qsrc).existsSync()) continue;
      if (size != '') {
        lableText = lableText + '\nGröße: $size';
      }
      lableText = lableText + '\n$pr Euro\n' + iid.toString() + '\n\n';
      final qrImage = pw.MemoryImage(File(qsrc).readAsBytesSync());
      for (int j = 0; j < (i.ammount - i.sold - i.trashed); j++) {
        whole.addPage(makePage(lableText, qrImage, conum));
      }
    }
  }

  return whole;
}

///renders the qr code
Future<String> renderQr(QrCode qr, int id) async {
  Image img = Image(21, 21);
  for (int i = 0; i < qr.moduleCount; i++) {
    for (int j = 0; j < qr.moduleCount; j++) {
      if (qr.isDark(i, j)) {
        img.setPixelRgba(i, j, 0, 0, 0);
      }
    }
  }
  img.fillBackground(0xFFFFFFFF);
  String src = 'web/label/qr/$id.png';
  File f = File(src);
  await f.create();
  f.writeAsBytesSync(encodePng(img));
  print('saved File');
  return src;
}


/*pw.Page(
pageFormat: PdfPageFormat(200, 420),
build: (pw.Context context) {
  return pw.Center(
      child: pw.Column(children: [
    pw.Text(lableText,
        style: pw.TextStyle(
            fontSize: 20, font: pw.Font.courierBold())),
    pw.Image(qrImage, width: 160, height: 160),
    pw.Text('\n$iid\nKOM: $conum',
        style: pw.TextStyle(fontSize: 20))
  ]));
})*/
/*pw.Page(
pageFormat: PdfPageFormat(200, 420),
build: (pw.Context context) {
  return pw.Center(
      child: pw.Column(children: [
    pw.Text(lableText,
        style: pw.TextStyle(
            fontSize: 20, fontBold: pw.Font.courierBold())),
    pw.Image(qrImage, width: 160, height: 160),
    pw.Text('\n$id\nKOM: $conum', style: pw.TextStyle(fontSize: 20))
  ]));
})*/
