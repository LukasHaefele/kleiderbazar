import 'dart:html';
import 'dart:typed_data';

import 'package:zxing2/qrcode.dart';

import 'websocket.dart';

///QR Scanner class
class QRScanner {
  ///Scanner video for computing of what's seen
  final video = VideoElement();

  ///Canvas to draw e.g. frame on
  final canvas = CanvasElement();

  ///Paragraph element to show result
  final output = ParagraphElement();

  ///stream to convert to video
  late MediaStream stream;

  ///Websocket to send Info
  ClientWebSocket ws;

  ///Don't know what this but will uodate if I find out
  bool co = true;

  ///Width of video
  int _width = 0;

  ///Height od video
  int _height = 0;

  QRScanner(this.ws) {
    magic();
  }

  ///scannes video, comprehends it, gets qr code
  void magic() async {
    querySelector('#qrSep')
      ?..append(canvas)
      ..append(output);
    stream = await window.navigator.mediaDevices!
        .getUserMedia({'video': true, 'audio': false});
    print(stream.getVideoTracks()[0].label);
    video.srcObject = stream;
    await video.play();
    print('can play');

    _width = 400;
    _height = video.videoHeight ~/ (video.videoWidth / _width);

    canvas.width = video.width = _width;
    canvas.height = video.height = _height;

    var reader = QRCodeReader();
    //DateTime start;

    while (co) {
      //start = DateTime.now();
      var img = _toBitImage();
      try {
        var result = reader.decode(img);
        // print('Found QR!');
        output.text = result.text;
        ws.send('register_scan; id: $result');
        AudioElement('audio/beep.mp3')
          ..autoplay = true
          ..load()
          ..remove();
        await Future.delayed(Duration(seconds: 3));
      } on ReaderException catch (_) {
        //print('Error reading QR: ${e.runtimeType}');
      }
      //var diff = DateTime.now().difference(start);
      // print('took ${diff.inMilliseconds} ms');
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  ///clears all Scanner activities
  void clearScanner() {
    for (var v in stream.getVideoTracks()) {
      v.stop();
    }
    co = false;
    output.remove();
    canvas.remove();
    stream.getAudioTracks().clear();
  }

  ///Also don't remember bur I'm sure it'll come back to me
  BinaryBitmap _toBitImage() {
    var ctx = canvas.context2D;
    ctx.drawImageScaled(video, 0, 0, _width, _height);

    var source = CanvasLuminanceSource(_width, _height, ctx);
    var binarizer = HybridBinarizer(source);
    var img = BinaryBitmap(binarizer);
    return img;
  }
}

///Man, I should've looked at this class more carefully
class CanvasLuminanceSource extends LuminanceSource {
  late final Int8List _luminances;

  CanvasLuminanceSource(int width, int height, CanvasRenderingContext2D ctx)
      : super(width, height) {
    var data = ctx.getImageData(0, 0, width, height);
    var values = data.data;

    var size = width * height;
    _luminances = Int8List(size);
    for (var i = 0; i < size; i++) {
      var offset = i << 2;
      var r = values[offset];
      // var g2 = (pixel >> 7) & 0x1fe; // 2 * green
      var g2 = 2 * values[offset + 1];
      var b = values[offset + 2];
      // Calculate green-favouring average cheaply
      _luminances[i] = ((r + g2 + b) ~/ 4).toInt();
    }
  }

  @override
  Int8List getMatrix() => _luminances;

  @override
  Int8List getRow(int y, Int8List? row) {
    if (y < 0 || y >= height) {
      throw ArgumentError('Requested row is outside the image: $y');
    }
    var width = this.width;
    if (row == null || row.length < width) {
      row = Int8List(width);
    }
    var offset = y * width;
    row.setRange(0, width, _luminances, offset);
    return row;
  }
}
