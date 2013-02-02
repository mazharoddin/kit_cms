/* DSC Kit Tree browser jQuery plugin */

(function($) {

  var div;
  var tree;
  var opts;
  var debug;

  var methods = {
    init : function(options) {
             opts = $.extend({}, $.fn.dsc_tree.defaults, options);
             div = $(this);
             debug = (opts.debug===true); 
             opts.show_refresh_button = opts.refresh_button || true;
             opts.hide_locked = opts.hide_locked || false;
             opts.show_filter = opts.show_filter || true;
             opts.show_move_buttons = opts.show_move_buttons || true;
             opts.filter_on_path = opts.filter_on_path || false;
             opts.open_level = opts.open_level || 0;
             opts.initial_refresh = opts.initial_refresh || false;
             opts.click_page = opts.click_page || "edit";
             opts.mode = opts.mode || "editor";
             fetch_data(opts.initial_refresh);
             opts.is_popup = opts.mode==="popup";
           },

get_node_data : function(id) {
                  return find_node(tree, 'c', id); 
                }
  };

  var node_template = _.template("<li class='clearfix type_<%= node.y %> <% if (node.d) { %>deleted<% } %>' id='<%= node.y %>_<%= node.id %>'><div class='control'>&nbsp;</div><div class='cog'>&nbsp;</div><div class='title'><span><%= node.t %></span></div><div class='move'>&nbsp;</div></li>");

  var node_level;
  var max_id = -1;

  function fetch_data(refresh) {
    $.get(opts.url, {refresh: refresh ? "1" : "0"}, function(json) {
      tree = json;
      tree.is_root = true;
      redraw();
    });
  }

  function l_id(li) {
    var lid = $(li).attr('id');
    return [lid.substring(0,1), lid.substring(2, lid.length)];
  }

  function find_li(type, id) {
    return div.find('ul.tree #' + type + '_' + id);
  }

  function find_node_for_li(li) {
    var lid = l_id(li);
    var type = lid[0];
    var id = lid[1];
    return find_node(tree, type, id);
  }

  function find_node(n, type, id) {
    if (n.y==type && n.id==id) { return n; }
    if (n.c===undefined) { return null; }
    for(var i=0; i<n.c.length; i++) {
      if (n.c[i].y==type && n.c[i].id==id) {
        return n.c[i]; 
      }
      else {
        var nn = find_node(n.c[i], type,id);
        if (nn!=null) {
          return nn;
        } 
      }
    }

    return null;
  }

  function get_li_up(event) {
    var el = $(event.target);
    if (!el.is("li")) el = el.parents('li');

    return el;
  }

  function redraw() {
    load_tree_state();

    $('.dsc_tree').off();
    div.html('');
    if (!div.hasClass('dsc_tree')) {
      div.addClass('dsc_tree');
    }

    var tree_options = $("<div class='tree_options clearfix'></div>");
    if (opts.show_filter || opts.show_move_buttons) {
      div.append(tree_options);
    }

    if (opts.show_filter) {
      add_filter(tree_options);
    }

    if (opts.show_move_buttons && opts.is_popup===false) {
      add_move_buttons(tree_options);
    }


    var listlist = $("<ul style='display: none;' class='list'></ul>"); 
    var list = $("<ul class='tree'></ul>");

    div.append(listlist);
    div.append(list);

    if (opts.show_refresh_button) {
      add_refresh_button();
    }

    draw_node(tree, list, 0);

    $('.dsc_tree').on('mouseenter', '.control, .title, .cog', function(event) {
      hover_in_node(get_li_up(event));
    }).on('mouseleave', '.control, .title, .cog', function(event) {
      hover_out_node(get_li_up(event));  
    }).on('click', 'div.cog', function(event) {
      $(event.target).parent('li').contextMenu({x:event.clientX,y:event.clientY});
      event.stopPropagation();
    }).on('click', 'li.type_c > div.control', function(event) {
      toggle_node($(event.target).parent('li'));
      event.stopPropagation();
    });

    $('.dsc_tree').on('click', 'li.type_s > div > span , li.type_p > div > span', function(event) {
        click_node($(event.target).parent('div').parent('li'));
      event.stopPropagation();
    }).on('click', 'li.type_c > div > span', function(event) {
        toggle_node($(event.target).parent('div').parent('li'));
      event.stopPropagation();
    });
   
    if (opts.is_popup===false) { 
      $.contextMenu({selector:'.dsc_tree li',
        build: function($trigger, e) {
          return context_menu($trigger);
        } 
      });
    }

  }

  function context_menu(target) {
    var li = target;
    if (!li.is("li")) li = li.parents('li');

    var node = find_node_for_li(li);
    var content;

    var menu;
    if (node.y==='c') {
      var has_children = node.c && node.c.length>0;
      menu =  {
        'title1' : { html: "<b>Category</b>", icon:"category", type:"html" },
        'separator1': '--' ,
          'newcat' : { name: "New Category", callback: function(menuItem,menu) { new_sub_category(node, li)}, icon: "newcat" },
        'newpage' : { name: 'New Page', callback: function(menuItem,menu) { document.location = '/page/new?cat_id=' + node.id },
          icon: "newpage" } ,
        'newpagestub' : { name: 'New Page Stub', callback: function(menuItem,menu) { new_stub(node, li); }, icon: "newpagestub" },
        'separator1': '--' ,
        'permissions' : { name: 'Permissions', callback: function(menuItem,menu) { document.location = '/category/' + node.id + '/permissions' }, icon: "permissions" },
        'separator1': '--' ,
        'rename' : {name: 'Rename', callback: function(menuItem,menu) { rename(li); }, icon:"rename", disabled: node.id==1, className: node.id==1 ? 'disabled':''} ,
        'delete' : {name: 'Delete', callback: function(menuItem,menu) { delete_category(li); }, disabled: has_children, className: has_children ? 'disabled':'', icon: "catdelete" },
      };
    }
    else {
      var is_stub = node.y == 's';
      var is_deleted = node.d;
      menu = {}

      if (node.y=='p') {
        menu['title'] = { html: "<b>Page</b>", icon:"page", type: "html" };
        menu['title2'] = { html: "<span>Status: " + node.u + "</span>", type: "html" };
        menu['separator1'] = "----";
        menu['view'] = { name: 'View', callback: function(menuItem,menu) { document.location = node.p; }, disabled: is_stub, className: is_stub ? 'disabled' : '', icon:"view"};
        menu['edit'] = { name: 'Edit', callback: function(menuItem,menu) { document.location = node.p + "?edit=1"; }, disabled: is_stub, className: is_stub ? 'disabled' : '', icon:"edit" };
      }
      else {
        menu['title'] = { html: "<b>Page Stub</b>", icon:"stub", type:"html" };
        menu['separator1'] = "----";
      }
      
      menu['info'] = { name: 'View Info', callback: function(menuItem,menu) { document.location = '/page/' + node.id + '/info'; }, disabled: node.t=='s', className: node.t=='s' ? 'disabled' : '', icon:"info"   } ;
      if (node.d==1) {
        menu['undelete'] = { name: 'Undelete', callback: function(menuItem,menu) { undelete_page(node,li); }, disabled: !is_deleted, className: is_deleted ? '' : 'disabled', icon:"undelete"};
      } else {
        menu['delete'] = { name: 'Delete', callback: function(menuItem,menu) { delete_page(node,li); }, disabled: is_deleted, className: is_deleted ? 'disabled' : '', icon:"delete"};
      }        
    }

    var r = { callback: function() {}, items:menu };
    return r;
  }

  function delete_page(node,li) {
    $.post("/page/" + node.id + "/delete", {}, function(resp) {
      node.d = 1;
      if (node.y=='s') {
        remove_child(node);
        li.remove();
      }
      style_node(li, node);
      notify(resp.message);
    });
  }

  function undelete_page(node,li) {
    $.post("/page/" + node.id + "/undelete", {}, function(resp) {
      node.d = 0;
      li.removeClass("deleted");
      li.find("div.control").removeClass("d_page").addClass("page");
      notify(resp.message);
    });
  }

  function click_node(clicked) {
    var li = $(clicked);
    var node = find_node_for_li(li);

    if (node.y=='c') {
      toggle_node(clicked);
    }
    else if (opts.mode==="popup") {
      $('#' + opts.target_field, window.parent.document).val(node.p);
      window.parent.close_link_browsers(); 
    }
    else {
      if (node.y == 's') {
        document.location = "/page/" + node.id + "/info";  
      }
      else {
        if (opts.click_page=='info') {
          document.location = "/page/" + node.id + "/info";
        }
        else {
          document.location = node.p + '?edit=1';
        }
      }
    }
  }

  function hover_in_node(node) {
    if (opts.is_popup===true) {
      return;
    }
    var li = $(node);
    if (li==cog_showing) {
      return ;
    }

    if (cog_showing) {
      hover_out_node(cog_showing);  
    } 

    cog_showing = li.find('div.cog').first();

    if (!cog_showing.hasClass('cog_show')) {
      cog_showing.addClass("cog_show");
    }
  }

  var cog_showing = null;

  function hover_out_node(node) {
    var li = $(node); 
    li.find('div.cog').first().removeClass("cog_show");
  }

  function toggle_node(to_open) {
    var li = $(to_open);
    var node = find_node_for_li(li);

    if (node.c==null || node.c.length==0) return;

    if (node.is_open) {
      close_node(node, li);
    } 
    else {
      open_node(node, li);
    }

    set_tree_state();
  }

  function open_node(node, li) {
    if (node.is_open) { 
      return;
    }
    node.is_open = true; 
    li.find('> div').first().removeClass().addClass('control cat_open');
    li.find('ul').first().show();
  }

  function close_node(node, li) {
    if (!node.is_open) { 
      return;
    }
    node.is_open = false; 
    li.find('> div').first().removeClass().addClass('control cat_can_open');
    li.find('> ul').first().hide();
  }

  function delete_category(li) {
    var node = find_node_for_li(li);

    if (node.is_new) {
      notify("Category deleted"); 
    }
    else {
      $.post("/category/delete/" + node.id, {}, function(resp) {
        notify(resp.message);
      });
    }
    
    // need to remove from LI and from node tree, then might need to change control icon of former parent...
    remove_child(node);
    li.remove();
  }

  function remove_child(node) {
    var parent_li = find_li('c', node.parentid);
    var parent_node = find_node(tree,'c',node.parentid);
    var node_index =  _.indexOf(parent_node.c, node);
    parent_node.c[node_index] = false;
    parent_node.c = _.compact(parent_node.c);
    style_node(parent_li, parent_node);
  }

  function rename(li) {
    var title = $(li).find('div.title').first();
    var node = find_node_for_li(li); 

    title.html('<input type="text" name="title" value="' + node.t + '" /> <a href="#" id="cancel_rename_link">Cancel</a>');

    li.find('a').on('click', function(event) {
      title.removeClass("not_saved");

      var parent_node = find_node(tree, 'c', node.parentid);

      if (node.is_new===true) {
        remove_child(node);
        li.remove(); 
      }
      else {
        title.html(node.t);
      } 
    event.stopPropagation();
    });

    li.find('input').focus().on('keyup', function(event) {
      if (event.which==13) {
        var entry = $(event.target).val();
        title.addClass("not_saved");
        if (node.is_new===false) {
          var url = node.y=='c' ? "/category/rename" : "/page/stub/rename";
          $.post(url + "/" + node.id, {name:entry}, function(resp) {
            if (resp.okay===true) {
              title.removeClass("not_saved");
              node.t = resp.name;
              title.html(resp.name);
              node.is_new = false;
            } 
            notify(resp.message);
          });
        }
        else {
          var url = node.y=='c' ? "/category/new" : "/page/stub";
          $.post(url + "/" + node.parentid, {name:entry}, function(resp) {
            if (resp.okay) {
              title.html(resp.name);
              title.removeClass("not_saved");
              node.id = resp.id;
              li.attr('id', node.y + "_" + node.id);
            }
            notify(resp.message);
          });
        }

      }
    }).focus();
  }

  function new_stub(parent_node, parent_li) {
    new_item(parent_node, parent_li, 's');
    style_node(parent_li, parent_node);
  }

  function new_sub_category(parent_node, parent_li) {
    new_item(parent_node, parent_li, 'c');
    style_node(parent_li, parent_node);
  }

  function new_item(parent_node, parent_li, type) {
    var node = { t: "New " + (type=='c' ? "Category" :"Page Stub"),
      y: type,
      d: false,
      c: [],
      id: max_id + 1,
      parentid: parent_node.id,
      is_new: true,
      extended: true,
      is_open: false};

    var new_li = add_node(node, parent_li);
    if (!parent_node.is_open) {
      toggle_node(parent_li);
    }

    rename(new_li);
  }

  function add_node(node, parent_li) {
    var parent_node = find_node_for_li(parent_li);
    parent_node.c.push(node);
    var parent_ul = parent_li.find('ul').first();
    if (parent_ul.length==0) {
      parent_ul = $("<ul></ul>");
      parent_li.append(parent_ul);
    }
    return draw_node(node, parent_ul, parent_node.level + 1);
  }

  function style_node(li, node) {
    var control_class = ''; 
    var control_div = li.find('div.control').first();

    if (node.y=='c') {
      var has_children = node.c && node.c.length>0;
      if (!has_children) {
        node.is_open = false;
      }
      control_class = node.is_open ? 'cat_open' : (has_children ? 'cat_can_open' : 'cat_cant_open') 
      if (node.is_root) {
        li.find('div.move').addClass('root_move');
      }
    }
    else {
      if (node.d==1) {
        control_class = 'd_page'
        li.addClass("deleted");
      }
      else {
        control_class = node.y=='s' ? 'stub' : 'page';
        if (node.b==false) {
          li.addClass("not_published");
        }
      }
      if (node.b===true) {
        li.addClass("pub");
      }
    }

    control_div.removeClass("cat_open cat_can_open cat_cant_open").addClass(control_class); 
  }

  function draw_node(node, list, level) {
    if (node.id>max_id) {
      max_id = node.id;
    }
    node.level = level;
    var this_li = $(node_template({node: extend_node(node)}));

    style_node(this_li, node);

    if (opts.hide_locked==false || node.k!=true) {
      list.append(this_li);
    }

    if (node.y=='c') {
      var new_list_style = node.is_open ? '' : 'display: none;';
      var new_list = $("<ul style='" + new_list_style + "'></ul>");
      this_li.append(new_list);
      if (node.c && node.c.length>0) {
        _.each(node.c, function(n) {
          n.parentid = node.id;
          draw_node(n, new_list, level + 1);
        });
      }
    }
    return this_li;
  }

  function extend_node(node) {
    if (node.extended===undefined) {
      if (node.is_open===undefined) {
        node.is_open = (node.level <= opts.open_level);
      }
      node.extended = true;
      node.is_new = false;
    }
    return node;
  }

  function load_tree_state() {
    var state = $.cookie('tree');
    if (state==null) {
      return;
    }
    var nodes = state.split(",");
    _.each(nodes, function(nid) {
      var node = find_node(tree, 'c', nid);
      if (node && node.c && node.c.length>0) {
        node.is_open = true;
      }
    }); 
  }

  function set_tree_state() {
    var l = []
      var list = get_open_list(tree, l);
    $.cookie("tree", list.join(','), {expires: 365, path: '/pages'})
  }

  function get_open_list(node, list) {
    if (node.y!='c') {
      return list;
    }

    if (node.is_open===true) {
      list.push(node.id);
    }

    _.each(node.c, function(n) {
      list = get_open_list(n, list);
    });

    return list
  }

  function add_refresh_button() {
    div.append($('<a class="icon refresh_icon" href="#">Refresh</a>').on('click', function() {
      fetch_data(true); 
      notify("Refreshed");
    }));
  }

  function add_move_buttons(options_div) {
  var buttons_div = $('<div class="buttons"></div>');
    options_div.append(buttons_div);

    buttons_div.append($('<span id="move_help" style="display:none;">Move Help</span>'));
    buttons_div.append($('<a class="icon move_icon" href="#">Move</a>').on('click', function() {
      move_mode();
    }));
    buttons_div.append($('<a class="icon copy_icon" href="#">Copy</a>').on('click', function() {
      copy_mode();
    }));
    buttons_div.append($('<a style="display: none;" class="cancel icon no_icon" href="#">Cancel</a>').on('click', function() {
      cancel_move(true);
    }));
  }

  function cancel_move(show_buttons_again) {
    if (show_buttons_again) {
      div.find('div.buttons a.copy_icon').show();
      div.find('div.buttons a.move_icon').show();
    }
    div.find('div.buttons a.cancel').hide();
    div.find('li div.move').hide();
    //div.find('li.type_c > div.move').droppable('destroy');
    div.find('.dd_accept').removeClass('dd_accept'); 
  }

  var dd = null;

  function move_mode() {
    dd = "move";
    setup_dd();
  }

  function copy_mode() {
    dd = "copy";
    setup_dd();
  }

  function setup_dd() {
    div.find('div.buttons a.copy_icon').hide();
    div.find('div.buttons a.move_icon').hide();
    div.find('div.buttons a.cancel').show();

    div.find('li div.move').show().draggable({
     addClasses: false,
     revert: true
    });

    div.find('li.type_c ').droppable({
      over: function(event, ui) {
        //var li = get_li_up(event); //$(event.target).parent('li').first();
        var li = $(event.target);
        li.find('div.title').first().addClass("dd_accept");
      },
      out: function(event, ui) {
        //var li = get_li_up(event); // $(event.target).parent('li').first();
        var li = $(event.target);
        li.find('div.title').first().removeClass("dd_accept");
      },
      drop: function(event, ui) {
        var li = $(event.target);
        move($(ui.draggable).parent('li'), li);  
      }
    });
  }

  function add_filter(options_div) {
    options_div.append("<div class='filter'><label>Quick Search:</label><input name='filter' value='' /></div>");
    options_div.find('input[name=filter]').on('keyup', function(event) {
      do_filter();
    }).focus();
  }

  function do_filter() {
    var filter_el = div.find("input[name=filter]").first();
    if (filter_el===undefined || filter_el===null) {
      return;
    }

    var filter = filter_el.val();

    if (filter.trim().length==0) {
      div.find('ul.list').hide();
      div.find('ul.tree').show();
      return;
    }

    div.find('ul.tree').hide();
    var list_el = div.find('ul.list');
    list_el.html('');
    list_el.show();

    div.find('div.highlight').removeClass('highlight'); 
    add_node_to_filtered_list(list_el, tree, filter);
  }

  function add_node_to_filtered_list(el, node, filter) {
    if (node.t.indexOf(filter)>=0 || (node.g && node.g.indexOf(filter)>=0) || (opts.filter_on_path && node.p && node.p.indexOf(filter)>=0)) {
      el.append("<li class='" + node.y + "' id='" + node.y + "_" + node.id +"'><a href='#'>" + node.p + "</a></li>").on('click', function(event) {
        div.find('ul.list').hide();
        div.find('ul.tree').show();
        highlight_li($(event.target.parentElement));
      });   
    }

    _.each(node.c, function(n) {
      add_node_to_filtered_list(el, n, filter);
    });
  }

  function highlight_li(li) {
    // walk up tree to root, opening as you go
    var lid = l_id(li);
    var lip = find_li(lid[0], lid[1]);
    find_li(lid[0],lid[1]).find('div.title').first().addClass('highlight');

    node = find_node_for_li(li); 

    if (node.y!='c') {
      node = find_node(tree,'c',node.parentid);
    }

    var done = false;
    while (!done) {
      open_node(node, find_li('c',node.id));

      if (node.is_root === undefined) {
        node = find_node(tree,'c',node.parentid);
      } else {
        done = true;
      }
    }    
  }

  function move(src, target) {
          var src_lid = l_id(src);
          var target_lid = l_id(target);
          var src_node = find_node(tree, src_lid[0], src_lid[1]);
          var target_node = find_node(tree, target_lid[0], target_lid[1]);
          if (src_node.parentid == target_node.id) {
            return;
          }

          if (src_node.y=='c') {
          // walk up from target to root - if we find the source, disallow
          //
          var okay = true;
          var node = target_node;
          while (node!=tree) {
            if (node.id == src_node.id) {
              okay = false;
              break;
            }
            node = find_node(tree, 'c', node.parentid);
          } 
          if (!okay) {
            notify("Sorry, you can't do this - it would leave an orphaned category");
            return;
          }
          }

          var move = dd=="move";

          $.post("/category/move", { mode: dd, source_id: src_lid[1], target_id: target_lid[1], is_cat: src_lid[0]=='c' ? 1 : 0 }, function(resp) {
            if (resp.okay) {
              if (target_node.c===undefined) {
                target_node.c = [];
              }

              if (move) {
                remove_child(src_node);
                src_node.parentid = target_node.id;
                target_node.c.push(src_node);
                target.find('ul').first().append(src);
              } 
              else {
                var copy_src_node = $.extend(true, {}, src_node);
                copy_src_node.id = resp.new_id;
                target_node.c.push(copy_src_node);
                var new_li = src.clone();
                new_li.attr("id", copy_src_node.y + "_" + resp.new_id);
                target.find('ul').first().append(new_li);
              }
              open_node(target_node, target);
              style_node(target, target_node);
              cancel_move(false);
            } else {
              log("Move failed " + resp.message);
            }
            notify(resp.message);
          });

      cc = null;  
  }

  function log(message) {
    if (debug) {
      console.debug(message);
    }
  }

  $.fn.dsc_tree = function(method) {

    if (methods[method]) {
      return  methods[ method ].apply( this, Array.prototype.slice.call( arguments, 1 ));
    } else if ( typeof method === 'object' || ! method ) {
      return methods.init.apply(this, arguments);
    } else {
      $.error('Method ' + method + ' does not exist on JQuery.dsc_tree');
    }

  }
})(jQuery);

