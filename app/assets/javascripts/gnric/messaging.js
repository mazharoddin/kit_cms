/*
 *= require "../views/jsrender.js"
 *= require "../views/jquery.observable.js"
 *= require "../views/jquery.views.js"
*/

var conversations = {};
var conversation_height_allowance = 130;
var visible_conversation = 0;
var conversation_updates = 5000;
var selected_game_id = null;

setup_messaging = function() {
  $(window).resize(function() {
    messaging_resize_window();
  });
  messaging_resize_window();
  

  $.templates({opponent_template: $('#opponent_list').html(), conversation_list_template: $('#conversation_list').html()});

  $('#opponent_list').on('click', '.opponent', function(event) {
    click_opponent(event.currentTarget); 
  }).on('click', '.available', function(event) {
    available_for_game(selected_game_id, $(event.currentTarget).data("available"));
  }); 

  $('#conversation_list').on('click', '.conversation', function(event) {
    var link = $(event.currentTarget);
    load_conversation(link.data("conversationid"), link.data("conversationname"));
  });

  fetch_messages(true);
}

select_conversation = function(id) {
  visible_conversation = id;
  $('#conversations #convs > div').hide();
  $('#conv_' + id).show();
  setTimeout("focus_message($('#conversations textarea#message_' + visible_conversation))", 300);
}

focus_message = function(message) {
  message.focus();
}

messaging_resize_window = function() {
  var h = $(window).height()-conversation_height_allowance;
  $('#conversations').height(h);
  $('#conversations .message_list').height(h - conversation_height_allowance);
}

create_conversation = function(id, name) {
  $('#conversations #convs').append("<div class='hidden' id='conv_" + id + "'></div>");
  $('#conv_' + id).load("/convo/" + id, null, function() {
    messaging_resize_window();
  });
  conversations[id] = { name: name, last_message: 0, conversation_id: id};

}

load_conversation = function(id, name) {
  if (conversations[id]==null) {
    create_conversation(id, name);
  }

  select_conversation(id);
  fetch_messages(false);
}

var fetching = false;

fetch_messages = function(start_timer) {
  if (fetching==true && start_timer==true) return;
  fetching = true;
  $.post("/convo", {"conversations" : JSON.stringify(conversations), "selected_game_id" : selected_game_id}, function(data) {
    display_messages(data.conversations);
    display_conversation_list(data.list);
    if (data.opponents!=null) display_opponents(data.opponents, data.me_available);
  });
  if (start_timer) setTimeout('fetch_messages(true)', conversation_updates);
  fetching = false;
}

add_message_to_conversation = function(message) {
  c = find_conversation(message.conversation_id);
  if (c.length==0) return;
  c.append("<li>");
  c.append(message.sender + ": " + message.message);
  c.append("</li>"); 
  c.parent().scrollTop(c.parent().height()+20);
}

find_conversation = function(conversation_id) {
  return $('#conversation_' + conversation_id);  
}

send_message = function(conversation_id) { 
  var message =  $('#message_' + conversation_id).val();
  if (message === '') return;
  $.ajax({type:'PUT', url:"/convo/" + conversation_id, data: {message: message}, success: function(data) {
    fetch_messages(false);
  }});
  $('#message_' + conversation_id).val("");
}

display_messages = function(data) {
    if (data==null) return;
    for(i=0; i<=data.length; i++) {
      var message = data[i];
      if (message!=null) {
        add_message_to_conversation(message);
        var c = conversations[message.conversation_id];
        if (c!=null) {
          c.last_message = message.message_id;
        }
      }
    }    
}  

need_to_register = function() {
  $('.enable_register').removeClass('disabled');  
  $('.enable_register').removeClass('hidden');  
  $('.hide_register').addClass('hidden');  
  $('#display_name').attr("disabled", null);
}

setup_register = function() {
  $('#display_name').on("keyup", function() {
    $.post("/utility/display_name_check",{name:$('#display_name').val()});
  });
}

display_name_check = function(msg) {
  $('#display_name_message').html(msg);  
}

var opponent_timer = null;

show_opponents = function(game_id, game_name) {
  $('#game #message').hide();

  $('#game #name').html("Opponents for " + game_name); 
  $('#game #details').show();
  selected_game_id = game_id; 
  available_for_game(game_id, true);
  fetch_messages(false);
}

available_for_game = function(game_id, available) {
  $.post("/convo/game/" + game_id + "/" + available, null, function(data) {

  });
  fetch_messages(false);
}

display_conversation_list = function(data) {
  $('#conversation_list').html($.render["conversation_list_template"](data));
  $('#conversation_list').show();
  var index = 0;
  for (var c in conversations) {
    var convo = conversations[c];
    index++;
    var found_convo = false;
    for (var dd in data) {
      var d = data[dd];
      if (d.id === convo.conversation_id) {
        found_convo = true;
        break;
      }
    }
    if (!found_convo) {
      $('#conversations').tabs('remove', index);
      delete conversations[c];
    }
  }
}

thanks_for_suggestion = function() {
  $("#suggestion_name").val("");
  alert("Thanks for your suggestion.  We'll consider it right away.");
}

display_opponents = function(data, me_available) {
  $('#opponent_list').html($.render["opponent_template"](data));
  if (me_available==='true') {
    $('#opponent_list').prepend("<li>You are <em>available</em> to play this game. Become <a href='#' class='available' data-available='false'>not available</a></li>");
  }
  else {
    $('#opponent_list').prepend("<li>You are <em>not available</em> to play this game. Become <a href='#' class='available' data-available='true'>available</a></li>");
  }
}

click_opponent = function(item) {
    var link = $(item);
    var user_id = link.data('userid'); 
    var game_id = link.data('gameid'); 
    var user_name = link.html();
    $.post("/convo/game/" + game_id + "/start/" + user_id);
}

game_start_error = function(message) {
  alert(message);
}

game_created = function(conversation_id,conversation_name) {
  load_conversation(conversation_id, conversation_name);
}
