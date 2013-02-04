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

function do_cmd(editor, cmd) {
  if (cmd=='list') {
    do_list(editor, '-');
  }
  if (cmd=='numbered_list') {
    do_list(editor, '1.');
  }
  if (cmd=='image') {
    do_image(editor);
  }
  if (cmd=='video') {
    do_video(editor);
  }
  if (cmd=='link') {
    do_link(editor);
  }
  if (cmd=='bold') {
    insert_formatting(editor, '**', '**', 'Bold');
  }
  if (cmd=='underline') {
    insert_formatting(editor, '_', '_', 'Underline');
  }
  if (cmd=='pre') {
    do_prefix(editor, '    '); 
  }
  if (cmd=='quote') {
    do_prefix(editor, '> ');
  }
  if (cmd=='undo') {
    do_undo(editor);
  }
  if (cmd=='redo') {
    do_redo(editor);
  }
  if (cmd=='preview') {
    do_preview(editor);
  }
}

function do_prefix(editor, prefix) {
  var editor = html_editors[editor];
  var start_pos = editor.getCursor('start');
  var end_pos = editor.getCursor('end');

  if (editor.somethingSelected()) {
    for (var i = start_pos.line; i <= end_pos.line; i++) {
      editor.setLine(i, prefix + editor.getLine(i));
    }
  } else {
    if (start_pos.ch==0) {
      editor.replaceSelection(prefix);
    }
    else {
      editor.setLine(start_pos.line, prefix + editor.getLine(start_pos.line));
    }
    start_pos.ch = start_pos.ch + prefix.length;
    editor.setCursor(start_pos);
  }
  editor.focus();
}

function do_link(editor) {
  var url = prompt("Enter the full URL for the link", "http://");

  insert_formatting(editor, '[', '](' + url + ')', 'Link');
}

function do_video(editor) {
 var editor = html_editors[editor];
  var start_pos = editor.getCursor('start');
  var url = prompt("Enter Youtube 'share' URL or Vimeo URL");
 
  editor.replaceSelection(url);
  start_pos.ch = start_pos.ch + url.length;
  editor.setCursor(start_pos);
  editor.focus(); 
}

function do_undo(editor) {
  var editor = html_editors[editor];
  editor.undo();
}

function do_redo(editor) {
  var editor = html_editors[editor];
  editor.redo();
}

function do_image(editor) {
  var editor = html_editors[editor];
  var url = prompt("Enter the full URL of the image", "http://");
  var start_pos = editor.getCursor('start');

  editor.replaceSelection("![](" + url + ")");
  start_pos.ch = start_pos.ch + url.length + 5;
  editor.setCursor(start_pos);
  editor.focus();
}

function do_list(editor_name,list) {
  var editor = html_editors[editor_name];
  var start_pos = editor.getCursor('start');
  var end_pos = editor.getCursor('end');
  var to_insert = '';

  if (editor.somethingSelected()) {
    if (start_pos.line != end_pos.line) {
      do_prefix(editor_name, list);
      return;
    } 
    else {
      var selection = editor.getSelection();
      editor.replaceSelection(((start_pos.ch==0) ? '' : '\r') + list + ' ' + selection + '\r' + list + ' ');
      start_pos.line = start_pos.line + 2;
      start_pos.ch = selection.length + list.length;
    }
    editor.setCursor(start_pos);
  }
  else {
    if (start_pos.ch>0) {
      var line = editor.getLine(start_pos.line);
      if (line && line.indexOf(list)==0) {
        editor.setLine(start_pos.line, editor.getLine(start_pos.line) + '\r' + list + ' ');
      }
      else {
        editor.setLine(start_pos.line, list + ' ' + editor.getLine(start_pos.line) + '\r' + list + ' ');
      }
      start_pos.line = start_pos.line + 1;
      editor.setCursor(start_pos);
    } else {
      editor.replaceSelection(list + ' ');
      start_pos.ch = list.length+1;
      editor.setCursor(start_pos);
    }
  }
  editor.focus();
}

function insert_formatting(editor,start,end,placeholder) {
  var editor = html_editors[editor];
  var current = editor.getSelection();
  var placeholder_mode = false;
  var start_pos = editor.getCursor("start");
  var end_pos = editor.getCursor("end");
  
  if (!editor.somethingSelected()) {
    current = placeholder;
    placeholder_mode = true;
  }

  editor.replaceSelection(start + current + end);
  if (placeholder_mode) {
    start_pos.ch = start_pos.ch + start.length;
    end_pos.ch = start_pos.ch + placeholder.length;
    editor.setSelection( start_pos, end_pos);
  } 
  else {
    end_pos.ch = end_pos.ch + (start.length*2);
    editor.setCursor(end_pos);
  }
  editor.focus();
}


function do_preview(field) {
  var editor = html_editors[field];
  $('#preview_' + field).dialog({ autoOpen: true, 
    width: 800, height: 500, modal: true, resizable: true, show: {effect:"drop"}, title: "Preview", closeOnEscape: true, dialogClass: "modal_markdown_preview" });
   
  $.post('/utility/markdown_preview', {body: editor.getValue()}, function(data) {
    $('#preview_' + field).html(data); 
  }); 
}
