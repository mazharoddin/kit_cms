

$(document).ready(function() {
  set_gnric_help();

  $('#notice_box').on('click', function() {
    $('#notice_box').hide();
  });

  $("form.cr_submit input, form.cr_submit select").on('keypress', function (e) {
    if ((e.which && e.which == 13) || (e.keyCode && e.keyCode == 13)) {
      var button = $(this).parents('form').find('button[type=submit].default, input[type=submit].default');
      if (button.length>0) {
        button.click();
      }
      else {
        $(this).parents('form').submit();
      }
  return false;
    } else {
      return true;
    }
  });
  if (eval("typeof " + $(".fancybox").fancybox + " == 'function'")) {
    init_fancybox();
  }


});

function copy_to_clipboard(text) {
  window.prompt ("Copy to clipboard: Ctrl+C (or Apple+C on a Mac), Enter", text);
}

function get_gnric_help_link() {
  return $('#gnric_help_link a.field_show_more');
}

function get_gnric_help_showing() {
  var link = get_gnric_help_link();
  if (link==null) return false;
  return link.data('showing');
}

function set_gnric_help() {
  var link = get_gnric_help_link();
  if (link==null) return false;
  var showing = get_gnric_help_showing();
  if (!showing) {
    link.text('Inline Help'); 
    $('.field_help').hide();
  } else {
    link.text('No Inline Help'); 
    $('.field_help').show();
  }
}

function toggle_gnric_help(persist) {
  var link = get_gnric_help_link();
  if (link==null) return false;
  var showing = get_gnric_help_showing();
  showing = !showing;
  link.data('showing', showing);
  set_gnric_help();
  $.post('/admin/user/help_mode', { mode: showing });
};

function being_edited_by(emails) {
  alert("This item is also currently being edited by: " + emails +"\n\nYou can still edit it but be aware that you may overwrite one another's changes.");
}

function notify(message) {
  $('#notice').html(message);
  $('#notice_box').stop(true).fadeIn().delay(3000).fadeOut("slow");
}

var auto_name = '';

function nameChanged() {
  var new_name = $('#page_name').val();
  $.post("/page/unique", { cat_id: $('#page_category_id').val(), name: new_name });
  if (editing_page) {
    if (new_name!=page_name) {
      $('#page_name_change_warning').slideDown();
    }
    else {
      $('#page_name_change_warning').slideUp();
    }
  }
}

function titleChanged() {
  if ($('#page_name').hasClass('input_manual')) { return; }
  if ($('#page_title').val()=="") { return; }
  if ($('#page_title').val()==$('#page_title').attr('data-default')) { return; }

  if (!$('#page_title').hasClass('input_manual')) {
    v = text_to_friendly_url($('#page_title').val());
    if (v.length>40) {
      v = v.substring(0,40);
    }
    if (v!='') {
      auto_name = v;
      $('#page_name').val(v);
      $('#page_name').removeClass('field-hint');
    }
  }

  $.post("/page/unique", { cat_id: $('#page_category_id').val(), name: v });
}


function page_name_valid(valid) {
  $('#page_name_valid').text(valid ? "" : "Page with this name already exists in this category");
  if (valid) {
    $('#page_submit').removeAttr('disabled');
  }
  else {
    $('#page_submit').attr('disabled', 'disabled');
  }
}

function new_category(parent_id) {
  $('#category_parent_id').val(parent_id);
  $('#new_category_popup').dialog("open");        
}


/*******************************************/


/******/
init_tree = function(mode, target_field, page_click, hide_locked) {
  hide_locked = (typeof hide_locked === 'undefined') ? false : hide_locked;
  var tree = $('#browser').dsc_tree({
    debug: false, 
      url:"/category/browse",
      click_page: page_click,
      target_field: target_field,
      mode: mode,
      hide_locked: hide_locked
  });
}

function toggle_editing(menu_id) {
  $('#modes').slideUp();
  $('#menus .not_delete, #menus .not_reorder').hide();
  menu_done_button('Editing');
  $('#menus').find('a.edit').removeClass('hidden');
}

function toggle_delete(menu_id) {
  $('#modes').slideUp();
  $('#menus .not_delete').hide();
  menu_done_button('Deleting');
  $('#menus').find('a.delete').removeClass('hidden');
}

function toggle_sorting(menu_id) {
  $('#modes').slideUp();
  $('#menus .not_reorder').hide();
  $('#menus .reorder').show();
  menu_done_button('Reording');
  $('#menus ul li').addClass('sorting');
  $('#menus > ul').sortable({
    items: 'li',
    'placeholder' : 'placeholder',
    containment : '#menus > ul',
    forcePlaceholderSize: true,
    update: function() {
      $('#menus .new_parent').hide();
      save_sorting(menu_id);
    }
    });
  $('#menus .new_parent').bind('change', function(event) {
    var select = $(event.target);
    var item_id = select.parent().parent().attr('id');
    window.location = "/menu/" + menu_id + "/promote/" + item_id + "/" + select.val() ;
  });
}

function menu_done_button(mode) {
  $('#menus').find('.done_button').text("Done " + mode).removeClass('hidden');
}  

function save_sorting(menu_id) {
   $.post("/menu/" + menu_id + "/move", {order:$('#menus > ul').serializeTree('id','tree')});
}

function edit_menu_item(menu_id, item_id) {
  document.location = "/menu/" + menu_id + "/edit/" + item_id;
}

function in_place() {
  $('.best_in_place').best_in_place();
}

function setup_menu_editor() {
  $('#browser').hide();
  build_tree("embedded", "menu_item_link_url");
  $('#menu_item_link_url').on("focus", function() {
    $('#browser').slideDown();
  }).on("blur", function() {
    $('#browser').slideUp();
  });

}

make_link_to = function(url, target_field) {
  $('#' + target_field).val(url)   
  $('#link_browser').hide();
}

field_hide_more = function(key) {
  var field = $('#' + key);
  field.find('.long').hide();
  field.find('.short').show();
}

field_show_more = function(key) {
  var field = $('#' + key);
  field.find('.short').hide();
  field.find('.long').show();
}


category_permission = function(category_id, group_id, mode, granted) {
  $.post("/category/" + category_id + "/permission/" + group_id + "/" + mode + "/" + granted, null, function(response) {
  });
}

copy_permissions_to_subs = function(category_id) {
  $.post("/category/" + category_id + "/permissions/subs");
}

category_permission_public = function(category_id, is_public) {
  $.post("/category/" + category_id + "/public/" + is_public);
}


setup_google_preview = function() {

  $('#page_category_id').on('change', function() {
    update_google_preview();
  });

  $("#page_title, #page_name,#page_meta_description").keyup(function(){
    if(typeof(window.delayer) != 'undefined')
    clearTimeout(window.delayer);
  window.delayer = setTimeout(update_google_preview, 100);
  });
  update_google_preview();
}

update_google_preview = function() {
  var category = current_category || $("#page_category_id option:selected").text();
  var page_name = $('#page_name').val();
  if (page_name===$('#page_name').data('default')) {
    page_name = "page-name";
  }
  var page_title = $('#page_title').val();
  if (page_title===$('#page_title').data('default')) {
    page_title = "Page Title";
  }

  if (category.substring(0,1)!='/') {
    category = "/" + category;
  }

  if (category!='/' && category.substring(category.length-1,category.length)!='/') {
    category = category + "/";
  }

  var link = $('#google #host').text().trim() + category + text_to_friendly_url(page_name);
  $('#google #entry #link a').attr('href', link);
  if (link.length>60) {
    link = link.substring(0,60) + "...";
  }

  $('#google #entry #url').text(link);
  var title = page_title;
  if (title.length>68) {
    title = title.substr(0,68) + " ...";
  }
  $('#google #entry #link a').text(title);
  var desc = $('#page_meta_description').val();
  if (desc.trim().length==0) {
    desc = "Text from somehwere near the top of the page will appear here until you enter a meta description";
  }
  if (desc.length>156) {
    desc = desc.substring(0,156) + " ...";
  }
  $('#google #entry #description').text(desc);
}

function remove_image_from_gallery(image_id) {
  $("#row_"+ image_id).remove();
}

function add_image_to_gallery(image_id, gallery_id) {
  $.post("/admin/gallery/" + gallery_id + "/image/" + image_id, null, function(resp,data) {
    $('#image_list').append(resp);
    var msg = $('<span>Added&nbsp;</span>').delay(3000).fadeOut();
    $('#file_name_' + image_id).append(msg);
    $(".best_in_place").best_in_place();
  }); 
}

function sort_gallery_images(gallery_id, event, ui) {
  var orders = [];
  $('#image_list').find('tr').each(function(index, element) {
    var row_id = $(element).attr('id');
    var id = row_id.substring(4,row_id.length);
    orders.push(id); 
  });
  $.post("/admin/gallery/" + gallery_id + "/images/sort", {order:orders});
}

function zoom_browser() {
  $('#left-box1').hide();
  $('#left-box2').css('width', '740px').css('left', '10px');
  $('.zoom_link').hide();
}


/*
 * JavaScript Load Image 1.1.6
 * https://github.com/blueimp/JavaScript-Load-Image
 *
 * Copyright 2011, Sebastian Tschan
 * https://blueimp.net
 *
 * Licensed under the MIT license:
 * http://www.opensource.org/licenses/MIT
 */

/*jslint nomen: true */
/*global window, document, URL, webkitURL, Blob, File, FileReader, define */

(function ($) {
  'use strict';

  // Loads an image for a given File object.
  // Invokes the callback with an img or optional canvas
  // element (if supported by the browser) as parameter:
  var loadImage = function (file, callback, options) {
    var img = document.createElement('img'),
url,
oUrl;
img.onerror = callback;
img.onload = function () {
  if (oUrl) {
    loadImage.revokeObjectURL(oUrl);
  }
  callback(loadImage.scale(img, options));
};
if ((window.Blob && file instanceof Blob) ||
  // Files are also Blob instances, but some browsers
  // (Firefox 3.6) support the File API but not Blobs:
  (window.File && file instanceof File)) {
    url = oUrl = loadImage.createObjectURL(file);
  } else {
    url = file;
  }
if (url) {
  img.src = url;
  return img;
} else {
  return loadImage.readFile(file, function (url) {
    img.src = url;
  });
}
},
  urlAPI = (window.createObjectURL && window) ||
  (window.URL && URL) || (window.webkitURL && webkitURL);

  // Scales the given image (img or canvas HTML element)
  // using the given options.
  // Returns a canvas object if the browser supports canvas
  // and the canvas option is true or a canvas object is passed
  // as image, else the scaled image:
  loadImage.scale = function (img, options) {
    options = options || {};
    var canvas = document.createElement('canvas'),
        width = img.width,
        height = img.height,
        scale = Math.max(
            (options.minWidth || width) / width,
            (options.minHeight || height) / height
            );
    if (scale > 1) {
      width = parseInt(width * scale, 10);
      height = parseInt(height * scale, 10);
    }
    scale = Math.min(
        (options.maxWidth || width) / width,
        (options.maxHeight || height) / height
        );
    if (scale < 1) {
      width = parseInt(width * scale, 10);
      height = parseInt(height * scale, 10);
    }
    if (img.getContext || (options.canvas && canvas.getContext)) {
      canvas.width = width;
      canvas.height = height;
      canvas.getContext('2d')
        .drawImage(img, 0, 0, width, height);
      return canvas;
    }
    img.width = width;
    img.height = height;
    return img;
  };

loadImage.createObjectURL = function (file) {
  return urlAPI ? urlAPI.createObjectURL(file) : false;
};

loadImage.revokeObjectURL = function (url) {
  return urlAPI ? urlAPI.revokeObjectURL(url) : false;
};

// Loads a given File object via FileReader interface,
// invokes the callback with a data url:
loadImage.readFile = function (file, callback) {
  if (window.FileReader && FileReader.prototype.readAsDataURL) {
    var fileReader = new FileReader();
    fileReader.onload = function (e) {
      callback(e.target.result);
    };
    fileReader.readAsDataURL(file);
    return fileReader;
  }
  return false;
};

if (typeof define !== 'undefined' && define.amd) {
  define(function () {
    return loadImage;
  });
} else {
  $.loadImage = loadImage;
}
}(this));

function initialise_upload_form(name) {
  var uploading_files = [];
  
  $(name).fileupload({
    dataType: 'json',
    url: '/assets',
    type: 'post',
    singleFileUploads: true,
    add: function(e, data) {
      $.each(data.files, function (index, file) {
        var li = $("<li id='file_" + uploading_files.length + "' class='toupload clearfix'/>");
        uploading_files.push(file.name);
        $('#filelist').append(li);
        li.append($("<img class='image_holder'/>"));
        li.append($("<div class='status'><div class='message'>Uploading</div><div class='progress'><div class='inner'>&nbsp;</div></div></div>"));
        var img = $(loadImage(file, function() {
          img.attr('height', '100');
          img.attr('width', '100');
          li.find('.image_holder').replaceWith(img); 
        }));
      });
      data.submit();
    },
    done: function(e, data) {
      $('#files table tr.title_row').after(data.result.result);
      $(".best_in_place").best_in_place();
      var index = _.indexOf(uploading_files, data.files[0].name);
      $('#filelist li#file_' + index + " div.message").html("Done");
      uploading_files[index] = 'xxx';
      var all_done = true;
      _.each(uploading_files, function(e) {
        if (e!='xxx') {
          all_done  = false;
        }
      });
      if (all_done) {
        $('#filelist').fadeOut(1000, function() {
          $('#filelist').html('').show();
          init_fancybox();
        });
      }
    },
    progress: function (e, data) {
      var progress = parseInt(data.loaded / data.total * 100, 10);
      var index = _.indexOf(uploading_files, data.files[0].name);
      var status_div = $('#filelist li#file_' + index + ' .status');
      status_div.find("div.inner").css('width', (5*progress) + "px");
      if (progress>99.9) {
        status_div.find('div.message').html("Processing");
      }
    }
  });
}

show_image_browser_for_block = function(target_field, source_div, mode) {
  create_browser_container("image_browser", source_div, mode); 
  show_image_browser(target_field);
}

show_page_browser_for_block = function(target_field, after_div, mode) {
  create_browser_container('link_browser', after_div, mode);
  $('#file_browser').hide();
  show_page_browser(target_field);
}

show_file_browser_for_block = function(target_field, after_div, mode) {
  create_browser_container('file_browser', after_div, mode);
  $('#link_browser').hide();
  show_file_browser(target_field);
}

create_browser_container = function(browser_name, source_div, mode) {
  $('#' + browser_name).remove();
  var container = mode == "db" ? 'div' : 'fieldset' ;
  var content = $("<" + container + " id='" + browser_name + "'>Loading please wait...</" + container + ">");
  var source = $('#' + source_div);

  var close_browser = $('<div class="close_browser_link"><a href="#" class="icon no_icon mercury-button">Close Browser</a></div>');
  close_browser.find('a').on('click', function() {
    close_link_browsers();
  });

  // store the open link(s) for later reinstatement
  var open_links = source.find(".open_browser_links");
  open_links.after(close_browser);
  $('.open_browser_links').hide(); // all on page

  if (mode=='db') {
    $(source).append(content);
  } else {
    $(source).after(content);
  }
}

show_image_browser = function(target_field) {
  $('#video_fields, #media_options, #media_buttons').hide();
  $('#image_browser').show();
  $('#open_browser_links').hide();
  $('#image_browser').html($("<iframe src='/mercury/images?target_field=" + target_field + "' frameborder='0' marginheight='0' marginwidth='0' style='height: 680px; width: 100%'>Image browser frame</iframe>"));
  return false;
}  

show_page_browser = function(target_field) {
  $('#open_browser_links').hide();
  $('#link_browser').html($("<iframe src='/mercury/links?target_field=" + target_field + "' frameborder='0' marginheight='0' marginwidth='0' style='height: 570px; width: 100%'>Link browser frame</iframe>"));
  $('#link_browser').show();
  return false;
}

show_file_browser = function(target_field) {
  $('#open_browser_links').hide();
  $('#file_browser').html($("<iframe src='/mercury/images?files=1&target_field=" + target_field + "' frameborder='0' marginheight='0' marginwidth='0' style='height: 700px; width: 100%'>File browser frame</iframe>"));
  $('#file_browser').show();
  return false;
}

close_link_browsers = function() {
  $('#file_browser').hide();
  $('#link_browser').hide();
  $('#image_browser').hide();
  $('.close_browser_link').remove();
  $('.open_browser_links').show();
  $('#video_fields, #media_options, #media_buttons').show();

}

set_image_url = function(url, target_field) {
  $('#' + target_field).val(url); 
  close_link_browsers();
  $('#open_browser_links').show();
  $('#video_fields, #media_options, #media_buttons').show();
}

