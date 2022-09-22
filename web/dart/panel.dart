import 'dart:html';

///shows panel by identifier
void showPanel(String id) {
  querySelector('.greyout')?.style.display = 'flex';
  querySelector(id)?.style.display = 'flex';
}

///hides panel by identifier
void hidePanel(String id) {
  querySelector(id)?.style.display = 'none';
  querySelector('.greyout')?.style.display = 'none';
}

///generates error message that disapears after 8 seconds
void error(String message) async {
  querySelector('#error')
    ?..style.display = 'flex'
    ..text = message;
  await Future.delayed(Duration(seconds: 8));
  querySelector('#error')
    ?..text = ''
    ..style.display = 'none';
}
