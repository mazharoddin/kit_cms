/*
 *= require './kit'
 *= require './kit/application-edit'
 *= require './kit/underscore'
 *= require './kit/jquery.contextmenu'
 *= require './kit/tree'
 *= require_self
 */


$(document).ready(function() {
  $('#menu').naviDropDown({
    slideDownDuration: 150,
  dropDownWidth: '200px'
  });
  $('#menu_search_img, #menu_search_li, #menu_search_link').mouseover(
    function() {
      $('#search_field').focus();
    });
  $('.dropdown p').mouseenter(function() {
    $(this).parent().parent().addClass("selected-item");
    $(this).addClass("selected-sub-item");
  });
  $('.dropdown p').mouseleave(function() {
    $(this).parent().parent().removeClass("selected-item");
    $(this).removeClass("selected-sub-item");
  });
  $('div#menu ul#bar').show();

  $('div.box_close').append("<div class='close_box'><a href='#'>X</div>");
  $('div.side_box div.close_box').on('click', function(event) {
    var box = $(event.target).parent().parent();
    $.post("/admin/preference?" + box.attr('id') + "=false");
    notify("To re-show this box, go to User Preferences");
    box.hide();
  });
  $('.validated form').validate();
});

function show_form_submission(id) {
  $.get("/admin/form/submission/" + id, {}, function(resp) {
    $('#sub_' + id).after(resp);
    $('#show_' + id).hide();
    $('#hide_' + id).show();
  }); 
}

function hide_form_submission(id) {
    $('#showing_' + id).remove();
    $('#show_' + id).show();
    $('#hide_' + id).hide();
}


function visible_form_submission(id) {
  var visible = $('#sub_' + id + " .visibled").text();
  $.post("/admin/form/submission/" + id, {visible:visible}, function(resp) {
    $('#sub_' + id + " a.visible").text(resp.visible ? "Invisible" : "Visible");
    $('#sub_' + id + ' .visibled').text(resp.visible ? 0 : 1);
    $('#sub_' + id + ' .is_visible').text(resp.visible ? "Visible" : "Invisible");
  });
}

function mark_form_submission(id) {
  var mark = $('#sub_' + id + " .marked").text();
  $.post("/admin/form/submission/" + id, {mark:mark}, function(resp) {
    $('#sub_' + id + " a.mark").text(resp.mark ? "Unmark" : "Mark");
    $('#sub_' + id + ' .marked').text(resp.mark ? 0 : 1);
    $('#sub_' + id + ' .is_marked').text(resp.mark ? "Marked" : "Unmarked");
  });
}

function destroy_submission(id) {
  $.post('/admin/form/submission/' + id + "/destroy", null, function(resp) {
    $('#sub_' + id).remove(); 
  });
}

