/*
 *
 *= require "./codemirror"
 *= require "./overlay"
 *= require "./htmlmixed"
 *= require "./sass"
 *= require "./css"
 *= require "./markdown"
 *= require "./xml"
 *= require "./javascript"
 *= require "./dialog"
 *= require "./match-highlighter"
 *= require "./matchbrackets"
 *= require "./searchcursor"
 *= require "./search"
 *= require "./collapserange"
 *
*/

var html_editors = new Array();

function do_bold(editor) {
  insert_formatting(editor, "*", "*", "Bold");
}

function do_underline(editor) {
  insert_formatting(editor, "_", "_", "Underlined");
}

function insert_code(editor,start) {
  var editor = html_editors[editor];
  var start_pos = editor.getCursor('start');
  var to_insert = '';
  if (start_pos.ch>0) {
    to_insert = "\n";
  }
  to_insert = to_insert + start;

}

function insert_formatting(editor,start,end,placeholder) {
  var editor = html_editors[editor];
  var current = editor.getSelection();
  var placeholder_mode = false;
  var start_pos = editor.getCursor("start");
  var end_pos = editor.getCursor("start"); // yes, start
  
  if (!editor.somethingSelected()) {
    current = placeholder;
    placeholder_mode = true;
  }

  editor.replaceSelection(start + current + end);
  if (placeholder_mode) {
    start_pos.ch = start_pos.ch + 1;
    end_pos.ch = start_pos.ch + placeholder.length;
    editor.setSelection( start_pos, end_pos);
  } 
  else {
    start_pos.ch = start_pos.ch + 2;
    editor.setCursor(start_pos);
  }
  editor.focus();
}



