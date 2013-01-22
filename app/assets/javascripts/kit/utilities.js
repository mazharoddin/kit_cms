function init_fancybox() {
  $('a.fancybox').fancybox({overlayOpacity:0.9, transitionIn: 'elastic', transitionOut: 'elastic',  overlayShow: true, hideOnOverlayClick:true, enableEscapeButton: true, showCloseButton: true});
}  

select_change_parent = function(element, child, data, value) {
  var selection = $('#' + element).val(); 
  if (selection==='') {
    op = "<option></option>";
  }
  else {
    var subs = data[selection];
    var op = '<option></option>';
    for (i=0; i<subs.length; i++) {
      op = op + "<option value='" + selection + ":" + subs[i] + "'" + (subs[i]==value ? ' selected ' : '') + ">" + subs[i] + "</option>";
    }
  }
  $('#' + child).html(op);
}


function markup_menu(id) {
  var first_top_level = true;
  var last_top_level_element = null;
  var current_url = window.location.pathname;
  var last_sub_level_element = null;
  $('#' + id + " > li").each(function(index, element) {
    if (first_top_level===true) {
      $(element).addClass("first_item");
      first_top_level = false;
    }
    last_top_level_element = element;
    var top_level_link = $(element).find("a:first");
    if (top_level_link.attr('href') === current_url) {
      $(element).addClass('current');
    }

    var first_sub_level = true;
    $(element).find('div.dropdown p').each(function(child_index, child_element) {
      if (first_sub_level===true) {
        $(child_element).addClass("first_item");
        first_sub_level = false;
      }
      last_sub_level_element = child_element;
      var link = $(child_element).find("a:first");
      if (link.attr('href') === current_url) {
        $(child_element).addClass('current');
        $(element).addClass('child_current');
      }
    });
  });
  if (last_sub_level_element!==null) {
    $(last_sub_level_element).addClass("last");
  }
  if (last_top_level_element!==null) {
    $(last_top_level_element).addClass("last_item");
  }
}

/*
 * jQuery UI Slider Access
 * By: Trent Richardson [http://trentrichardson.com]
 * Version 0.2
 * Last Modified: 12/02/2011
 * 
 * Copyright 2011 Trent Richardson
 * Dual licensed under the MIT and GPL licenses.
 * http://trentrichardson.com/Impromptu/GPL-LICENSE.txt
 * http://trentrichardson.com/Impromptu/MIT-LICENSE.txt
 * 
 */
(function($){

  $.fn.extend({
    sliderAccess: function(options){
      options = options || {};
      options.touchonly = options.touchonly !== undefined? options.touchonly : true; // by default only show it if touch device

      if(options.touchonly === true && !("ontouchend" in document))
    return $(this);

  return $(this).each(function(i,obj){
    var $t = $(this),
         o = $.extend({},{ 
           where: 'after',
         step: $t.slider('option','step'), 
         upIcon: 'ui-icon-plus', 
         downIcon: 'ui-icon-minus',
         text: false,
         upText: '+',
         downText: '-',
         buttonset: true,
         buttonsetTag: 'span'
         }, options),
         $buttons = $('<'+ o.buttonsetTag +' class="ui-slider-access">'+
           '<button data-icon="'+ o.downIcon +'" data-step="-'+ o.step +'">'+ o.downText +'</button>'+
           '<button data-icon="'+ o.upIcon +'" data-step="'+ o.step +'">'+ o.upText +'</button>'+
           '</'+ o.buttonsetTag +'>');

  $buttons.children('button').each(function(j, jobj){
    var $jt = $(this);
    $jt.button({ 
      text: o.text, 
      icons: { primary: $jt.data('icon') }
    })
    .click(function(e){
      var step = $jt.data('step'),
      curr = $t.slider('value'),
      newval = curr += step*1,
      minval = $t.slider('option','min'),
      maxval = $t.slider('option','max');

    e.preventDefault();

    if(newval < minval || newval > maxval)
      return;

    $t.slider('value', newval);

    $t.slider("option", "slide").call($t, null, { value: newval });
    });
  });

  // before or after          
  $t[o.where]($buttons);

  if(o.buttonset){
    $buttons.removeClass('ui-corner-right').removeClass('ui-corner-left').buttonset();
    $buttons.eq(0).addClass('ui-corner-left');
    $buttons.eq(1).addClass('ui-corner-right');
  }

  // adjust the width so we don't break the original layout
  var bOuterWidth = $buttons.css({
    marginLeft: (o.where == 'after'? 10:0), 
      marginRight: (o.where == 'before'? 10:0)
  }).outerWidth(true) + 5;
  var tOuterWidth = $t.outerWidth(true);
  $t.css('display','inline-block').width(tOuterWidth-bOuterWidth);
  });    
    }
  });

})(jQuery);


/*
 * jQuery timepicker addon
 * By: Trent Richardson [http://trentrichardson.com]
 * Version 1.0.1
 * Last Modified: 07/01/2012
 *
 * Copyright 2012 Trent Richardson
 * You may use this project under MIT or GPL licenses.
 * http://trentrichardson.com/Impromptu/GPL-LICENSE.txt
 * http://trentrichardson.com/Impromptu/MIT-LICENSE.txt
 *
 * HERES THE CSS:
 * .ui-timepicker-div .ui-widget-header { margin-bottom: 8px; }
 * .ui-timepicker-div dl { text-align: left; }
 * .ui-timepicker-div dl dt { height: 25px; margin-bottom: -25px; }
 * .ui-timepicker-div dl dd { margin: 0 10px 10px 65px; }
 * .ui-timepicker-div td { font-size: 90%; }
 * .ui-tpicker-grid-label { background: none; border: none; margin: 0; padding: 0; }
 */

/*jslint evil: true, maxlen: 300, white: false, undef: false, nomen: false, onevar: false */

(function($) {

  // Prevent "Uncaught RangeError: Maximum call stack size exceeded"
  $.ui.timepicker = $.ui.timepicker || {};
  if ($.ui.timepicker.version) {
    return;
  }

  $.extend($.ui, { timepicker: { version: "1.0.1" } });

  /* Time picker manager.
     Use the singleton instance of this class, $.timepicker, to interact with the time picker.
     Settings for (groups of) time pickers are maintained in an instance object,
     allowing multiple different settings on the same page. */

  function Timepicker() {
    this.regional = []; // Available regional settings, indexed by language code
    this.regional[''] = { // Default regional settings
      currentText: 'Now',
closeText: 'Done',
ampm: false,
amNames: ['AM', 'A'],
pmNames: ['PM', 'P'],
timeFormat: 'hh:mm tt',
timeSuffix: '',
timeOnlyTitle: 'Choose Time',
timeText: 'Time',
hourText: 'Hour',
minuteText: 'Minute',
secondText: 'Second',
millisecText: 'Millisecond',
timezoneText: 'Time Zone'
    };
    this._defaults = { // Global defaults for all the datetime picker instances
      showButtonPanel: true,
      timeOnly: false,
      showHour: true,
      showMinute: true,
      showSecond: false,
      showMillisec: false,
      showTimezone: false,
      showTime: true,
      stepHour: 1,
      stepMinute: 1,
      stepSecond: 1,
      stepMillisec: 1,
      hour: 0,
      minute: 0,
      second: 0,
      millisec: 0,
      timezone: null,
      useLocalTimezone: false,
      defaultTimezone: "+0000",
      hourMin: 0,
      minuteMin: 0,
      secondMin: 0,
      millisecMin: 0,
      hourMax: 23,
      minuteMax: 59,
      secondMax: 59,
      millisecMax: 999,
      minDateTime: null,
      maxDateTime: null,
      onSelect: null,
      hourGrid: 0,
      minuteGrid: 0,
      secondGrid: 0,
      millisecGrid: 0,
      alwaysSetTime: true,
      separator: ' ',
      altFieldTimeOnly: true,
      showTimepicker: true,
      timezoneIso8601: false,
      timezoneList: null,
      addSliderAccess: false,
      sliderAccessArgs: null
    };
    $.extend(this._defaults, this.regional['']);
  }

  $.extend(Timepicker.prototype, {
    $input: null,
  $altInput: null,
  $timeObj: null,
  inst: null,
  hour_slider: null,
  minute_slider: null,
  second_slider: null,
  millisec_slider: null,
  timezone_select: null,
  hour: 0,
  minute: 0,
  second: 0,
  millisec: 0,
  timezone: null,
  defaultTimezone: "+0000",
  hourMinOriginal: null,
  minuteMinOriginal: null,
  secondMinOriginal: null,
  millisecMinOriginal: null,
  hourMaxOriginal: null,
  minuteMaxOriginal: null,
  secondMaxOriginal: null,
  millisecMaxOriginal: null,
  ampm: '',
  formattedDate: '',
  formattedTime: '',
  formattedDateTime: '',
  timezoneList: null,

  /* Override the default settings for all instances of the time picker.
     @param  settings  object - the new settings to use as defaults (anonymous object)
     @return the manager object */
  setDefaults: function(settings) {
    extendRemove(this._defaults, settings || {});
    return this;
  },

  //########################################################################
  // Create a new Timepicker instance
  //########################################################################
  _newInst: function($input, o) {
    var tp_inst = new Timepicker(),
    inlineSettings = {};

    for (var attrName in this._defaults) {
      var attrValue = $input.attr('time:' + attrName);
      if (attrValue) {
        try {
          inlineSettings[attrName] = eval(attrValue);
        } catch (err) {
          inlineSettings[attrName] = attrValue;
        }
      }
    }
    tp_inst._defaults = $.extend({}, this._defaults, inlineSettings, o, {
      beforeShow: function(input, dp_inst) {
        if ($.isFunction(o.beforeShow)) {
          return o.beforeShow(input, dp_inst, tp_inst);
        }
      },
      onChangeMonthYear: function(year, month, dp_inst) {
        // Update the time as well : this prevents the time from disappearing from the $input field.
        tp_inst._updateDateTime(dp_inst);
        if ($.isFunction(o.onChangeMonthYear)) {
          o.onChangeMonthYear.call($input[0], year, month, dp_inst, tp_inst);
        }
      },
      onClose: function(dateText, dp_inst) {
        if (tp_inst.timeDefined === true && $input.val() !== '') {
          tp_inst._updateDateTime(dp_inst);
        }
        if ($.isFunction(o.onClose)) {
          o.onClose.call($input[0], dateText, dp_inst, tp_inst);
        }
      },
      timepicker: tp_inst // add timepicker as a property of datepicker: $.datepicker._get(dp_inst, 'timepicker');
    });
    tp_inst.amNames = $.map(tp_inst._defaults.amNames, function(val) { return val.toUpperCase(); });
    tp_inst.pmNames = $.map(tp_inst._defaults.pmNames, function(val) { return val.toUpperCase(); });

    if (tp_inst._defaults.timezoneList === null) {
      var timezoneList = [];
      for (var i = -11; i <= 12; i++) {
        timezoneList.push((i >= 0 ? '+' : '-') + ('0' + Math.abs(i).toString()).slice(-2) + '00');
      }
      if (tp_inst._defaults.timezoneIso8601) {
        timezoneList = $.map(timezoneList, function(val) {
          return val == '+0000' ? 'Z' : (val.substring(0, 3) + ':' + val.substring(3));
        });
      }
      tp_inst._defaults.timezoneList = timezoneList;
    }

    tp_inst.timezone = tp_inst._defaults.timezone;
    tp_inst.hour = tp_inst._defaults.hour;
    tp_inst.minute = tp_inst._defaults.minute;
    tp_inst.second = tp_inst._defaults.second;
    tp_inst.millisec = tp_inst._defaults.millisec;
    tp_inst.ampm = '';
    tp_inst.$input = $input;

    if (o.altField) {
      tp_inst.$altInput = $(o.altField)
        .css({ cursor: 'pointer' })
        .focus(function(){ $input.trigger("focus"); });
    }

    if(tp_inst._defaults.minDate===0 || tp_inst._defaults.minDateTime===0)
    {
      tp_inst._defaults.minDate=new Date();
    }
    if(tp_inst._defaults.maxDate===0 || tp_inst._defaults.maxDateTime===0)
    {
      tp_inst._defaults.maxDate=new Date();
    }

    // datepicker needs minDate/maxDate, timepicker needs minDateTime/maxDateTime..
    if(tp_inst._defaults.minDate !== undefined && tp_inst._defaults.minDate instanceof Date) {
      tp_inst._defaults.minDateTime = new Date(tp_inst._defaults.minDate.getTime());
    }
    if(tp_inst._defaults.minDateTime !== undefined && tp_inst._defaults.minDateTime instanceof Date) {
      tp_inst._defaults.minDate = new Date(tp_inst._defaults.minDateTime.getTime());
    }
    if(tp_inst._defaults.maxDate !== undefined && tp_inst._defaults.maxDate instanceof Date) {
      tp_inst._defaults.maxDateTime = new Date(tp_inst._defaults.maxDate.getTime());
    }
    if(tp_inst._defaults.maxDateTime !== undefined && tp_inst._defaults.maxDateTime instanceof Date) {
      tp_inst._defaults.maxDate = new Date(tp_inst._defaults.maxDateTime.getTime());
    }
    return tp_inst;
  },

  //########################################################################
  // add our sliders to the calendar
  //########################################################################
  _addTimePicker: function(dp_inst) {
    var currDT = (this.$altInput && this._defaults.altFieldTimeOnly) ?
      this.$input.val() + ' ' + this.$altInput.val() :
      this.$input.val();

    this.timeDefined = this._parseTime(currDT);
    this._limitMinMaxDateTime(dp_inst, false);
    this._injectTimePicker();
  },

  //########################################################################
  // parse the time string from input value or _setTime
  //########################################################################
  _parseTime: function(timeString, withDate) {
    if (!this.inst) {
      this.inst = $.datepicker._getInst(this.$input[0]);
    }

    if (withDate || !this._defaults.timeOnly) 
    {
      var dp_dateFormat = $.datepicker._get(this.inst, 'dateFormat');
      try {
        var parseRes = parseDateTimeInternal(dp_dateFormat, this._defaults.timeFormat, timeString, $.datepicker._getFormatConfig(this.inst), this._defaults);
        if (!parseRes.timeObj) { return false; }
        $.extend(this, parseRes.timeObj);
      } catch (err)
      {
        return false;
      }
      return true;
    }
    else
    {
      var timeObj = $.datepicker.parseTime(this._defaults.timeFormat, timeString, this._defaults);
      if(!timeObj) { return false; }
      $.extend(this, timeObj);
      return true;
    }
  },

  //########################################################################
  // generate and inject html for timepicker into ui datepicker
  //########################################################################
  _injectTimePicker: function() {
    var $dp = this.inst.dpDiv,
    o = this._defaults,
    tp_inst = this,
    // Added by Peter Medeiros:
    // - Figure out what the hour/minute/second max should be based on the step values.
    // - Example: if stepMinute is 15, then minMax is 45.
    hourMax = parseInt((o.hourMax - ((o.hourMax - o.hourMin) % o.stepHour)) ,10),
    minMax  = parseInt((o.minuteMax - ((o.minuteMax - o.minuteMin) % o.stepMinute)) ,10),
    secMax  = parseInt((o.secondMax - ((o.secondMax - o.secondMin) % o.stepSecond)) ,10),
    millisecMax  = parseInt((o.millisecMax - ((o.millisecMax - o.millisecMin) % o.stepMillisec)) ,10),
    dp_id = this.inst.id.toString().replace(/([^A-Za-z0-9_])/g, '');

    // Prevent displaying twice
    //if ($dp.find("div#ui-timepicker-div-"+ dp_id).length === 0) {
    if ($dp.find("div#ui-timepicker-div-"+ dp_id).length === 0 && o.showTimepicker) {
      var noDisplay = ' style="display:none;"',
        html =  '<div class="ui-timepicker-div" id="ui-timepicker-div-' + dp_id + '"><dl>' +
          '<dt class="ui_tpicker_time_label" id="ui_tpicker_time_label_' + dp_id + '"' +
          ((o.showTime) ? '' : noDisplay) + '>' + o.timeText + '</dt>' +
          '<dd class="ui_tpicker_time" id="ui_tpicker_time_' + dp_id + '"' +
          ((o.showTime) ? '' : noDisplay) + '></dd>' +
          '<dt class="ui_tpicker_hour_label" id="ui_tpicker_hour_label_' + dp_id + '"' +
          ((o.showHour) ? '' : noDisplay) + '>' + o.hourText + '</dt>',
          hourGridSize = 0,
          minuteGridSize = 0,
          secondGridSize = 0,
          millisecGridSize = 0,
          size = null;

      // Hours
      html += '<dd class="ui_tpicker_hour"><div id="ui_tpicker_hour_' + dp_id + '"' +
        ((o.showHour) ? '' : noDisplay) + '></div>';
      if (o.showHour && o.hourGrid > 0) {
        html += '<div style="padding-left: 1px"><table class="ui-tpicker-grid-label"><tr>';

        for (var h = o.hourMin; h <= hourMax; h += parseInt(o.hourGrid,10)) {
          hourGridSize++;
          var tmph = (o.ampm && h > 12) ? h-12 : h;
          if (tmph < 10) { tmph = '0' + tmph; }
          if (o.ampm) {
            if (h === 0) {
              tmph = 12 +'a';
            } else {
              if (h < 12) { tmph += 'a'; }
              else { tmph += 'p'; }
            }
          }
          html += '<td>' + tmph + '</td>';
        }

        html += '</tr></table></div>';
      }
      html += '</dd>';

      // Minutes
      html += '<dt class="ui_tpicker_minute_label" id="ui_tpicker_minute_label_' + dp_id + '"' +
        ((o.showMinute) ? '' : noDisplay) + '>' + o.minuteText + '</dt>'+
        '<dd class="ui_tpicker_minute"><div id="ui_tpicker_minute_' + dp_id + '"' +
        ((o.showMinute) ? '' : noDisplay) + '></div>';

      if (o.showMinute && o.minuteGrid > 0) {
        html += '<div style="padding-left: 1px"><table class="ui-tpicker-grid-label"><tr>';

        for (var m = o.minuteMin; m <= minMax; m += parseInt(o.minuteGrid,10)) {
          minuteGridSize++;
          html += '<td>' + ((m < 10) ? '0' : '') + m + '</td>';
        }

        html += '</tr></table></div>';
      }
      html += '</dd>';

      // Seconds
      html += '<dt class="ui_tpicker_second_label" id="ui_tpicker_second_label_' + dp_id + '"' +
        ((o.showSecond) ? '' : noDisplay) + '>' + o.secondText + '</dt>'+
        '<dd class="ui_tpicker_second"><div id="ui_tpicker_second_' + dp_id + '"'+
        ((o.showSecond) ? '' : noDisplay) + '></div>';

      if (o.showSecond && o.secondGrid > 0) {
        html += '<div style="padding-left: 1px"><table><tr>';

        for (var s = o.secondMin; s <= secMax; s += parseInt(o.secondGrid,10)) {
          secondGridSize++;
          html += '<td>' + ((s < 10) ? '0' : '') + s + '</td>';
        }

        html += '</tr></table></div>';
      }
      html += '</dd>';

      // Milliseconds
      html += '<dt class="ui_tpicker_millisec_label" id="ui_tpicker_millisec_label_' + dp_id + '"' +
        ((o.showMillisec) ? '' : noDisplay) + '>' + o.millisecText + '</dt>'+
        '<dd class="ui_tpicker_millisec"><div id="ui_tpicker_millisec_' + dp_id + '"'+
        ((o.showMillisec) ? '' : noDisplay) + '></div>';

      if (o.showMillisec && o.millisecGrid > 0) {
        html += '<div style="padding-left: 1px"><table><tr>';

        for (var l = o.millisecMin; l <= millisecMax; l += parseInt(o.millisecGrid,10)) {
          millisecGridSize++;
          html += '<td>' + ((l < 10) ? '0' : '') + l + '</td>';
        }

        html += '</tr></table></div>';
      }
      html += '</dd>';

      // Timezone
      html += '<dt class="ui_tpicker_timezone_label" id="ui_tpicker_timezone_label_' + dp_id + '"' +
        ((o.showTimezone) ? '' : noDisplay) + '>' + o.timezoneText + '</dt>';
      html += '<dd class="ui_tpicker_timezone" id="ui_tpicker_timezone_' + dp_id + '"'  +
        ((o.showTimezone) ? '' : noDisplay) + '></dd>';

      html += '</dl></div>';
      var $tp = $(html);

      // if we only want time picker...
      if (o.timeOnly === true) {
        $tp.prepend(
            '<div class="ui-widget-header ui-helper-clearfix ui-corner-all">' +
            '<div class="ui-datepicker-title">' + o.timeOnlyTitle + '</div>' +
            '</div>');
        $dp.find('.ui-datepicker-header, .ui-datepicker-calendar').hide();
      }

      this.hour_slider = $tp.find('#ui_tpicker_hour_'+ dp_id).slider({
        orientation: "horizontal",
        value: this.hour,
        min: o.hourMin,
        max: hourMax,
        step: o.stepHour,
        slide: function(event, ui) {
          tp_inst.hour_slider.slider( "option", "value", ui.value);
          tp_inst._onTimeChange();
        }
      });


      // Updated by Peter Medeiros:
      // - Pass in Event and UI instance into slide function
      this.minute_slider = $tp.find('#ui_tpicker_minute_'+ dp_id).slider({
        orientation: "horizontal",
        value: this.minute,
        min: o.minuteMin,
        max: minMax,
        step: o.stepMinute,
        slide: function(event, ui) {
          tp_inst.minute_slider.slider( "option", "value", ui.value);
          tp_inst._onTimeChange();
        }
      });

      this.second_slider = $tp.find('#ui_tpicker_second_'+ dp_id).slider({
        orientation: "horizontal",
        value: this.second,
        min: o.secondMin,
        max: secMax,
        step: o.stepSecond,
        slide: function(event, ui) {
          tp_inst.second_slider.slider( "option", "value", ui.value);
          tp_inst._onTimeChange();
        }
      });

      this.millisec_slider = $tp.find('#ui_tpicker_millisec_'+ dp_id).slider({
        orientation: "horizontal",
        value: this.millisec,
        min: o.millisecMin,
        max: millisecMax,
        step: o.stepMillisec,
        slide: function(event, ui) {
          tp_inst.millisec_slider.slider( "option", "value", ui.value);
          tp_inst._onTimeChange();
        }
      });

      this.timezone_select = $tp.find('#ui_tpicker_timezone_'+ dp_id).append('<select></select>').find("select");
      $.fn.append.apply(this.timezone_select,
          $.map(o.timezoneList, function(val, idx) {
            return $("<option />")
            .val(typeof val == "object" ? val.value : val)
            .text(typeof val == "object" ? val.label : val);
          })
          );
      if (typeof(this.timezone) != "undefined" && this.timezone !== null && this.timezone !== "") {
        var local_date = new Date(this.inst.selectedYear, this.inst.selectedMonth, this.inst.selectedDay, 12);
        var local_timezone = timeZoneString(local_date);
        if (local_timezone == this.timezone) {
          selectLocalTimeZone(tp_inst);
        } else {
          this.timezone_select.val(this.timezone);
        }
      } else {
        if (typeof(this.hour) != "undefined" && this.hour !== null && this.hour !== "") {
          this.timezone_select.val(o.defaultTimezone);
        } else {
          selectLocalTimeZone(tp_inst);
        }
      }
      this.timezone_select.change(function() {
        tp_inst._defaults.useLocalTimezone = false;
        tp_inst._onTimeChange();
      });

      // Add grid functionality
      if (o.showHour && o.hourGrid > 0) {
        size = 100 * hourGridSize * o.hourGrid / (hourMax - o.hourMin);

        $tp.find(".ui_tpicker_hour table").css({
          width: size + "%",
          marginLeft: (size / (-2 * hourGridSize)) + "%",
          borderCollapse: 'collapse'
        }).find("td").each( function(index) {
          $(this).click(function() {
            var h = $(this).html();
            if(o.ampm)  {
              var ap = h.substring(2).toLowerCase(),
            aph = parseInt(h.substring(0,2), 10);
          if (ap == 'a') {
            if (aph == 12) { h = 0; }
            else { h = aph; }
          } else if (aph == 12) { h = 12; }
          else { h = aph + 12; }
            }
            tp_inst.hour_slider.slider("option", "value", h);
            tp_inst._onTimeChange();
            tp_inst._onSelectHandler();
          }).css({
            cursor: 'pointer',
            width: (100 / hourGridSize) + '%',
            textAlign: 'center',
            overflow: 'hidden'
          });
        });
      }

      if (o.showMinute && o.minuteGrid > 0) {
        size = 100 * minuteGridSize * o.minuteGrid / (minMax - o.minuteMin);
        $tp.find(".ui_tpicker_minute table").css({
          width: size + "%",
          marginLeft: (size / (-2 * minuteGridSize)) + "%",
          borderCollapse: 'collapse'
        }).find("td").each(function(index) {
          $(this).click(function() {
            tp_inst.minute_slider.slider("option", "value", $(this).html());
            tp_inst._onTimeChange();
            tp_inst._onSelectHandler();
          }).css({
            cursor: 'pointer',
            width: (100 / minuteGridSize) + '%',
            textAlign: 'center',
            overflow: 'hidden'
          });
        });
      }

      if (o.showSecond && o.secondGrid > 0) {
        $tp.find(".ui_tpicker_second table").css({
          width: size + "%",
          marginLeft: (size / (-2 * secondGridSize)) + "%",
          borderCollapse: 'collapse'
        }).find("td").each(function(index) {
          $(this).click(function() {
            tp_inst.second_slider.slider("option", "value", $(this).html());
            tp_inst._onTimeChange();
            tp_inst._onSelectHandler();
          }).css({
            cursor: 'pointer',
            width: (100 / secondGridSize) + '%',
            textAlign: 'center',
            overflow: 'hidden'
          });
        });
      }

      if (o.showMillisec && o.millisecGrid > 0) {
        $tp.find(".ui_tpicker_millisec table").css({
          width: size + "%",
          marginLeft: (size / (-2 * millisecGridSize)) + "%",
          borderCollapse: 'collapse'
        }).find("td").each(function(index) {
          $(this).click(function() {
            tp_inst.millisec_slider.slider("option", "value", $(this).html());
            tp_inst._onTimeChange();
            tp_inst._onSelectHandler();
          }).css({
            cursor: 'pointer',
            width: (100 / millisecGridSize) + '%',
            textAlign: 'center',
            overflow: 'hidden'
          });
        });
      }

      var $buttonPanel = $dp.find('.ui-datepicker-buttonpane');
      if ($buttonPanel.length) { $buttonPanel.before($tp); }
      else { $dp.append($tp); }

      this.$timeObj = $tp.find('#ui_tpicker_time_'+ dp_id);

      if (this.inst !== null) {
        var timeDefined = this.timeDefined;
        this._onTimeChange();
        this.timeDefined = timeDefined;
      }

      //Emulate datepicker onSelect behavior. Call on slidestop.
      var onSelectDelegate = function() {
        tp_inst._onSelectHandler();
      };
      this.hour_slider.bind('slidestop',onSelectDelegate);
      this.minute_slider.bind('slidestop',onSelectDelegate);
      this.second_slider.bind('slidestop',onSelectDelegate);
      this.millisec_slider.bind('slidestop',onSelectDelegate);

      // slideAccess integration: http://trentrichardson.com/2011/11/11/jquery-ui-sliders-and-touch-accessibility/
      if (this._defaults.addSliderAccess){
        var sliderAccessArgs = this._defaults.sliderAccessArgs;
        setTimeout(function(){ // fix for inline mode
          if($tp.find('.ui-slider-access').length === 0){
            $tp.find('.ui-slider:visible').sliderAccess(sliderAccessArgs);

            // fix any grids since sliders are shorter
            var sliderAccessWidth = $tp.find('.ui-slider-access:eq(0)').outerWidth(true);
            if(sliderAccessWidth){
              $tp.find('table:visible').each(function(){
                var $g = $(this),
                oldWidth = $g.outerWidth(),
                oldMarginLeft = $g.css('marginLeft').toString().replace('%',''),
                newWidth = oldWidth - sliderAccessWidth,
                newMarginLeft = ((oldMarginLeft * newWidth)/oldWidth) + '%';

              $g.css({ width: newWidth, marginLeft: newMarginLeft });
              });
            }
          }
        },0);
      }
      // end slideAccess integration

    }
  },

  //########################################################################
  // This function tries to limit the ability to go outside the
  // min/max date range
  //########################################################################
  _limitMinMaxDateTime: function(dp_inst, adjustSliders){
    var o = this._defaults,
    dp_date = new Date(dp_inst.selectedYear, dp_inst.selectedMonth, dp_inst.selectedDay);

    if(!this._defaults.showTimepicker) { return; } // No time so nothing to check here

    if($.datepicker._get(dp_inst, 'minDateTime') !== null && $.datepicker._get(dp_inst, 'minDateTime') !== undefined && dp_date){
      var minDateTime = $.datepicker._get(dp_inst, 'minDateTime'),
        minDateTimeDate = new Date(minDateTime.getFullYear(), minDateTime.getMonth(), minDateTime.getDate(), 0, 0, 0, 0);

      if(this.hourMinOriginal === null || this.minuteMinOriginal === null || this.secondMinOriginal === null || this.millisecMinOriginal === null){
        this.hourMinOriginal = o.hourMin;
        this.minuteMinOriginal = o.minuteMin;
        this.secondMinOriginal = o.secondMin;
        this.millisecMinOriginal = o.millisecMin;
      }

      if(dp_inst.settings.timeOnly || minDateTimeDate.getTime() == dp_date.getTime()) {
        this._defaults.hourMin = minDateTime.getHours();
        if (this.hour <= this._defaults.hourMin) {
          this.hour = this._defaults.hourMin;
          this._defaults.minuteMin = minDateTime.getMinutes();
          if (this.minute <= this._defaults.minuteMin) {
            this.minute = this._defaults.minuteMin;
            this._defaults.secondMin = minDateTime.getSeconds();
          } else if (this.second <= this._defaults.secondMin){
            this.second = this._defaults.secondMin;
            this._defaults.millisecMin = minDateTime.getMilliseconds();
          } else {
            if(this.millisec < this._defaults.millisecMin) {
              this.millisec = this._defaults.millisecMin;
            }
            this._defaults.millisecMin = this.millisecMinOriginal;
          }
        } else {
          this._defaults.minuteMin = this.minuteMinOriginal;
          this._defaults.secondMin = this.secondMinOriginal;
          this._defaults.millisecMin = this.millisecMinOriginal;
        }
      }else{
        this._defaults.hourMin = this.hourMinOriginal;
        this._defaults.minuteMin = this.minuteMinOriginal;
        this._defaults.secondMin = this.secondMinOriginal;
        this._defaults.millisecMin = this.millisecMinOriginal;
      }
    }

    if($.datepicker._get(dp_inst, 'maxDateTime') !== null && $.datepicker._get(dp_inst, 'maxDateTime') !== undefined && dp_date){
      var maxDateTime = $.datepicker._get(dp_inst, 'maxDateTime'),
        maxDateTimeDate = new Date(maxDateTime.getFullYear(), maxDateTime.getMonth(), maxDateTime.getDate(), 0, 0, 0, 0);

      if(this.hourMaxOriginal === null || this.minuteMaxOriginal === null || this.secondMaxOriginal === null){
        this.hourMaxOriginal = o.hourMax;
        this.minuteMaxOriginal = o.minuteMax;
        this.secondMaxOriginal = o.secondMax;
        this.millisecMaxOriginal = o.millisecMax;
      }

      if(dp_inst.settings.timeOnly || maxDateTimeDate.getTime() == dp_date.getTime()){
        this._defaults.hourMax = maxDateTime.getHours();
        if (this.hour >= this._defaults.hourMax) {
          this.hour = this._defaults.hourMax;
          this._defaults.minuteMax = maxDateTime.getMinutes();
          if (this.minute >= this._defaults.minuteMax) {
            this.minute = this._defaults.minuteMax;
            this._defaults.secondMax = maxDateTime.getSeconds();
          } else if (this.second >= this._defaults.secondMax) {
            this.second = this._defaults.secondMax;
            this._defaults.millisecMax = maxDateTime.getMilliseconds();
          } else {
            if(this.millisec > this._defaults.millisecMax) { this.millisec = this._defaults.millisecMax; }
            this._defaults.millisecMax = this.millisecMaxOriginal;
          }
        } else {
          this._defaults.minuteMax = this.minuteMaxOriginal;
          this._defaults.secondMax = this.secondMaxOriginal;
          this._defaults.millisecMax = this.millisecMaxOriginal;
        }
      }else{
        this._defaults.hourMax = this.hourMaxOriginal;
        this._defaults.minuteMax = this.minuteMaxOriginal;
        this._defaults.secondMax = this.secondMaxOriginal;
        this._defaults.millisecMax = this.millisecMaxOriginal;
      }
    }

    if(adjustSliders !== undefined && adjustSliders === true){
      var hourMax = parseInt((this._defaults.hourMax - ((this._defaults.hourMax - this._defaults.hourMin) % this._defaults.stepHour)) ,10),
        minMax  = parseInt((this._defaults.minuteMax - ((this._defaults.minuteMax - this._defaults.minuteMin) % this._defaults.stepMinute)) ,10),
                secMax  = parseInt((this._defaults.secondMax - ((this._defaults.secondMax - this._defaults.secondMin) % this._defaults.stepSecond)) ,10),
                millisecMax  = parseInt((this._defaults.millisecMax - ((this._defaults.millisecMax - this._defaults.millisecMin) % this._defaults.stepMillisec)) ,10);

      if(this.hour_slider) {
        this.hour_slider.slider("option", { min: this._defaults.hourMin, max: hourMax }).slider('value', this.hour);
      }
      if(this.minute_slider) {
        this.minute_slider.slider("option", { min: this._defaults.minuteMin, max: minMax }).slider('value', this.minute);
      }
      if(this.second_slider){
        this.second_slider.slider("option", { min: this._defaults.secondMin, max: secMax }).slider('value', this.second);
      }
      if(this.millisec_slider) {
        this.millisec_slider.slider("option", { min: this._defaults.millisecMin, max: millisecMax }).slider('value', this.millisec);
      }
    }

  },


  //########################################################################
  // when a slider moves, set the internal time...
  // on time change is also called when the time is updated in the text field
  //########################################################################
  _onTimeChange: function() {
    var hour   = (this.hour_slider) ? this.hour_slider.slider('value') : false,
    minute = (this.minute_slider) ? this.minute_slider.slider('value') : false,
    second = (this.second_slider) ? this.second_slider.slider('value') : false,
    millisec = (this.millisec_slider) ? this.millisec_slider.slider('value') : false,
    timezone = (this.timezone_select) ? this.timezone_select.val() : false,
    o = this._defaults;

    if (typeof(hour) == 'object') { hour = false; }
    if (typeof(minute) == 'object') { minute = false; }
    if (typeof(second) == 'object') { second = false; }
    if (typeof(millisec) == 'object') { millisec = false; }
    if (typeof(timezone) == 'object') { timezone = false; }

    if (hour !== false) { hour = parseInt(hour,10); }
    if (minute !== false) { minute = parseInt(minute,10); }
    if (second !== false) { second = parseInt(second,10); }
    if (millisec !== false) { millisec = parseInt(millisec,10); }

    var ampm = o[hour < 12 ? 'amNames' : 'pmNames'][0];

    // If the update was done in the input field, the input field should not be updated.
    // If the update was done using the sliders, update the input field.
    var hasChanged = (hour != this.hour || minute != this.minute ||
        second != this.second || millisec != this.millisec ||
        (this.ampm.length > 0 &&
         (hour < 12) != ($.inArray(this.ampm.toUpperCase(), this.amNames) !== -1)) ||
        timezone != this.timezone);

    if (hasChanged) {

      if (hour !== false) { this.hour = hour; }
      if (minute !== false) { this.minute = minute; }
      if (second !== false) { this.second = second; }
      if (millisec !== false) { this.millisec = millisec; }
      if (timezone !== false) { this.timezone = timezone; }

      if (!this.inst) { this.inst = $.datepicker._getInst(this.$input[0]); }

      this._limitMinMaxDateTime(this.inst, true);
    }
    if (o.ampm) { this.ampm = ampm; }

    //this._formatTime();
    this.formattedTime = $.datepicker.formatTime(this._defaults.timeFormat, this, this._defaults);
    if (this.$timeObj) { this.$timeObj.text(this.formattedTime + o.timeSuffix); }
    this.timeDefined = true;
    if (hasChanged) { this._updateDateTime(); }
  },

  //########################################################################
  // call custom onSelect.
  // bind to sliders slidestop, and grid click.
  //########################################################################
  _onSelectHandler: function() {
    var onSelect = this._defaults.onSelect;
    var inputEl = this.$input ? this.$input[0] : null;
    if (onSelect && inputEl) {
      onSelect.apply(inputEl, [this.formattedDateTime, this]);
    }
  },

  //########################################################################
  // left for any backwards compatibility
  //########################################################################
  _formatTime: function(time, format) {
    time = time || { hour: this.hour, minute: this.minute, second: this.second, millisec: this.millisec, ampm: this.ampm, timezone: this.timezone };
    var tmptime = (format || this._defaults.timeFormat).toString();

    tmptime = $.datepicker.formatTime(tmptime, time, this._defaults);

    if (arguments.length) { return tmptime; }
    else { this.formattedTime = tmptime; }
  },

  //########################################################################
  // update our input with the new date time..
  //########################################################################
  _updateDateTime: function(dp_inst) {
    dp_inst = this.inst || dp_inst;
    var dt = $.datepicker._daylightSavingAdjust(new Date(dp_inst.selectedYear, dp_inst.selectedMonth, dp_inst.selectedDay)),
        dateFmt = $.datepicker._get(dp_inst, 'dateFormat'),
        formatCfg = $.datepicker._getFormatConfig(dp_inst),
        timeAvailable = dt !== null && this.timeDefined;
    this.formattedDate = $.datepicker.formatDate(dateFmt, (dt === null ? new Date() : dt), formatCfg);
    var formattedDateTime = this.formattedDate;
    // remove following lines to force every changes in date picker to change the input value
    // Bug descriptions: when an input field has a default value, and click on the field to pop up the date picker. 
    // If the user manually empty the value in the input field, the date picker will never change selected value.
    //if (dp_inst.lastVal !== undefined && (dp_inst.lastVal.length > 0 && this.$input.val().length === 0)) {
    //  return;
    //}

    if (this._defaults.timeOnly === true) {
      formattedDateTime = this.formattedTime;
    } else if (this._defaults.timeOnly !== true && (this._defaults.alwaysSetTime || timeAvailable)) {
      formattedDateTime += this._defaults.separator + this.formattedTime + this._defaults.timeSuffix;
    }

    this.formattedDateTime = formattedDateTime;

    if(!this._defaults.showTimepicker) {
      this.$input.val(this.formattedDate);
    } else if (this.$altInput && this._defaults.altFieldTimeOnly === true) {
      this.$altInput.val(this.formattedTime);
      this.$input.val(this.formattedDate);
    } else if(this.$altInput) {
      this.$altInput.val(formattedDateTime);
      this.$input.val(formattedDateTime);
    } else {
      this.$input.val(formattedDateTime);
    }

    this.$input.trigger("change");
  }

  });

  $.fn.extend({
    //########################################################################
    // shorthand just to use timepicker..
    //########################################################################
    timepicker: function(o) {
      o = o || {};
      var tmp_args = arguments;

      if (typeof o == 'object') { tmp_args[0] = $.extend(o, { timeOnly: true }); }

      return $(this).each(function() {
        $.fn.datetimepicker.apply($(this), tmp_args);
      });
    },

    //########################################################################
    // extend timepicker to datepicker
    //########################################################################
    datetimepicker: function(o) {
      o = o || {};
      var tmp_args = arguments;

      if (typeof(o) == 'string'){
        if(o == 'getDate') {
          return $.fn.datepicker.apply($(this[0]), tmp_args);
        }
        else {
          return this.each(function() {
            var $t = $(this);
            $t.datepicker.apply($t, tmp_args);
          });
        }
      }
      else {
        return this.each(function() {
          var $t = $(this);
          $t.datepicker($.timepicker._newInst($t, o)._defaults);
        });
      }
    }
  });

  $.datepicker.parseDateTime = function(dateFormat, timeFormat, dateTimeString, dateSettings, timeSettings) {
    var parseRes = parseDateTimeInternal(dateFormat, timeFormat, dateTimeString, dateSettings, timeSettings);
    if (parseRes.timeObj)
    {
      var t = parseRes.timeObj;
      parseRes.date.setHours(t.hour, t.minute, t.second, t.millisec);
    }

    return parseRes.date;
  };

  $.datepicker.parseTime = function(timeFormat, timeString, options) {

    //########################################################################
    // pattern for standard and localized AM/PM markers
    //########################################################################
    var getPatternAmpm = function(amNames, pmNames) {
      var markers = [];
      if (amNames) {
        $.merge(markers, amNames);
      }
      if (pmNames) {
        $.merge(markers, pmNames);
      }
      markers = $.map(markers, function(val) { return val.replace(/[.*+?|()\[\]{}\\]/g, '\\$&'); });
      return '(' + markers.join('|') + ')?';
    };

    //########################################################################
    // figure out position of time elements.. cause js cant do named captures
    //########################################################################
    var getFormatPositions = function( timeFormat ) {
      var finds = timeFormat.toLowerCase().match(/(h{1,2}|m{1,2}|s{1,2}|l{1}|t{1,2}|z)/g),
          orders = { h: -1, m: -1, s: -1, l: -1, t: -1, z: -1 };

      if (finds) {
        for (var i = 0; i < finds.length; i++) {
          if (orders[finds[i].toString().charAt(0)] == -1) {
            orders[finds[i].toString().charAt(0)] = i + 1;
          }
        }
      }
      return orders;
    };

    var o = extendRemove(extendRemove({}, $.timepicker._defaults), options || {});

    var regstr = '^' + timeFormat.toString()
      .replace(/h{1,2}/ig, '(\\d?\\d)')
      .replace(/m{1,2}/ig, '(\\d?\\d)')
      .replace(/s{1,2}/ig, '(\\d?\\d)')
      .replace(/l{1}/ig, '(\\d?\\d?\\d)')
      .replace(/t{1,2}/ig, getPatternAmpm(o.amNames, o.pmNames))
      .replace(/z{1}/ig, '(z|[-+]\\d\\d:?\\d\\d)?')
      .replace(/\s/g, '\\s?') + o.timeSuffix + '$',
      order = getFormatPositions(timeFormat),
      ampm = '',
      treg;

    treg = timeString.match(new RegExp(regstr, 'i'));

    var resTime = {hour: 0, minute: 0, second: 0, millisec: 0};

    if (treg) {
      if (order.t !== -1) {
        if (treg[order.t] === undefined || treg[order.t].length === 0) {
          ampm = '';
          resTime.ampm = '';
        } else {
          ampm = $.inArray(treg[order.t], o.amNames) !== -1 ? 'AM' : 'PM';
          resTime.ampm = o[ampm == 'AM' ? 'amNames' : 'pmNames'][0];
        }
      }

      if (order.h !== -1) {
        if (ampm == 'AM' && treg[order.h] == '12') {
          resTime.hour = 0; // 12am = 0 hour
        } else {
          if (ampm == 'PM' && treg[order.h] != '12') {
            resTime.hour = parseInt(treg[order.h],10) + 12; // 12pm = 12 hour, any other pm = hour + 12
          }
          else { resTime.hour = Number(treg[order.h]); }
        }
      }

      if (order.m !== -1) { resTime.minute = Number(treg[order.m]); }
      if (order.s !== -1) { resTime.second = Number(treg[order.s]); }
      if (order.l !== -1) { resTime.millisec = Number(treg[order.l]); }
      if (order.z !== -1 && treg[order.z] !== undefined) {
        var tz = treg[order.z].toUpperCase();
        switch (tz.length) {
          case 1:  // Z
            tz = o.timezoneIso8601 ? 'Z' : '+0000';
            break;
          case 5:  // +hhmm
            if (o.timezoneIso8601) {
              tz = tz.substring(1) == '0000' ?
                'Z' :
                tz.substring(0, 3) + ':' + tz.substring(3);
            }
            break;
          case 6:  // +hh:mm
            if (!o.timezoneIso8601) {
              tz = tz == 'Z' || tz.substring(1) == '00:00' ?
                '+0000' :
                tz.replace(/:/, '');
            } else {
              if (tz.substring(1) == '00:00') {
                tz = 'Z';
              }
            }
            break;
        }
        resTime.timezone = tz;
      }


      return resTime;
    }

    return false;
  };

  //########################################################################
  // format the time all pretty...
  // format = string format of the time
  // time = a {}, not a Date() for timezones
  // options = essentially the regional[].. amNames, pmNames, ampm
  //########################################################################
  $.datepicker.formatTime = function(format, time, options) {
    options = options || {};
    options = $.extend($.timepicker._defaults, options);
    time = $.extend({hour:0, minute:0, second:0, millisec:0, timezone:'+0000'}, time);

    var tmptime = format;
    var ampmName = options.amNames[0];

    var hour = parseInt(time.hour, 10);
    if (options.ampm) {
      if (hour > 11){
        ampmName = options.pmNames[0];
        if(hour > 12) {
          hour = hour % 12;
        }
      }
      if (hour === 0) {
        hour = 12;
      }
    }
    tmptime = tmptime.replace(/(?:hh?|mm?|ss?|[tT]{1,2}|[lz])/g, function(match) {
      switch (match.toLowerCase()) {
        case 'hh': return ('0' + hour).slice(-2);
        case 'h':  return hour;
        case 'mm': return ('0' + time.minute).slice(-2);
        case 'm':  return time.minute;
        case 'ss': return ('0' + time.second).slice(-2);
        case 's':  return time.second;
        case 'l':  return ('00' + time.millisec).slice(-3);
        case 'z':  return time.timezone;
        case 't': case 'tt':
                   if (options.ampm) {
                     if (match.length == 1) {
                       ampmName = ampmName.charAt(0);
                     }
                     return match.charAt(0) == 'T' ? ampmName.toUpperCase() : ampmName.toLowerCase();
                   }
                   return '';
      }
    });

    tmptime = $.trim(tmptime);
    return tmptime;
  };

  //########################################################################
  // the bad hack :/ override datepicker so it doesnt close on select
  // inspired: http://stackoverflow.com/questions/1252512/jquery-datepicker-prevent-closing-picker-when-clicking-a-date/1762378#1762378
  //########################################################################
  $.datepicker._base_selectDate = $.datepicker._selectDate;
  $.datepicker._selectDate = function (id, dateStr) {
    var inst = this._getInst($(id)[0]),
        tp_inst = this._get(inst, 'timepicker');

    if (tp_inst) {
      tp_inst._limitMinMaxDateTime(inst, true);
      inst.inline = inst.stay_open = true;
      //This way the onSelect handler called from calendarpicker get the full dateTime
      this._base_selectDate(id, dateStr);
      inst.inline = inst.stay_open = false;
      this._notifyChange(inst);
      this._updateDatepicker(inst);
    }
    else { this._base_selectDate(id, dateStr); }
  };

  //#############################################################################################
  // second bad hack :/ override datepicker so it triggers an event when changing the input field
  // and does not redraw the datepicker on every selectDate event
  //#############################################################################################
  $.datepicker._base_updateDatepicker = $.datepicker._updateDatepicker;
  $.datepicker._updateDatepicker = function(inst) {

    // don't popup the datepicker if there is another instance already opened
    var input = inst.input[0];
    if($.datepicker._curInst &&
        $.datepicker._curInst != inst &&
        $.datepicker._datepickerShowing &&
        $.datepicker._lastInput != input) {
          return;
        }

    if (typeof(inst.stay_open) !== 'boolean' || inst.stay_open === false) {

      this._base_updateDatepicker(inst);

      // Reload the time control when changing something in the input text field.
      var tp_inst = this._get(inst, 'timepicker');
      if(tp_inst) {
        tp_inst._addTimePicker(inst);

        if (tp_inst._defaults.useLocalTimezone) { //checks daylight saving with the new date.
          var date = new Date(inst.selectedYear, inst.selectedMonth, inst.selectedDay, 12);
          selectLocalTimeZone(tp_inst, date);
          tp_inst._onTimeChange();
        }
      }
    }
  };

  //#######################################################################################
  // third bad hack :/ override datepicker so it allows spaces and colon in the input field
  //#######################################################################################
  $.datepicker._base_doKeyPress = $.datepicker._doKeyPress;
  $.datepicker._doKeyPress = function(event) {
    var inst = $.datepicker._getInst(event.target),
        tp_inst = $.datepicker._get(inst, 'timepicker');

    if (tp_inst) {
      if ($.datepicker._get(inst, 'constrainInput')) {
        var ampm = tp_inst._defaults.ampm,
          dateChars = $.datepicker._possibleChars($.datepicker._get(inst, 'dateFormat')),
                    datetimeChars = tp_inst._defaults.timeFormat.toString()
                      .replace(/[hms]/g, '')
                      .replace(/TT/g, ampm ? 'APM' : '')
                      .replace(/Tt/g, ampm ? 'AaPpMm' : '')
                      .replace(/tT/g, ampm ? 'AaPpMm' : '')
                      .replace(/T/g, ampm ? 'AP' : '')
                      .replace(/tt/g, ampm ? 'apm' : '')
                      .replace(/t/g, ampm ? 'ap' : '') +
                      " " +
                      tp_inst._defaults.separator +
                      tp_inst._defaults.timeSuffix +
                      (tp_inst._defaults.showTimezone ? tp_inst._defaults.timezoneList.join('') : '') +
                      (tp_inst._defaults.amNames.join('')) +
                      (tp_inst._defaults.pmNames.join('')) +
                      dateChars,
                    chr = String.fromCharCode(event.charCode === undefined ? event.keyCode : event.charCode);
        return event.ctrlKey || (chr < ' ' || !dateChars || datetimeChars.indexOf(chr) > -1);
      }
    }

    return $.datepicker._base_doKeyPress(event);
  };

  //#######################################################################################
  // Override key up event to sync manual input changes.
  //#######################################################################################
  $.datepicker._base_doKeyUp = $.datepicker._doKeyUp;
  $.datepicker._doKeyUp = function (event) {
    var inst = $.datepicker._getInst(event.target),
        tp_inst = $.datepicker._get(inst, 'timepicker');

    if (tp_inst) {
      if (tp_inst._defaults.timeOnly && (inst.input.val() != inst.lastVal)) {
        try {
          $.datepicker._updateDatepicker(inst);
        }
        catch (err) {
          $.datepicker.log(err);
        }
      }
    }

    return $.datepicker._base_doKeyUp(event);
  };

  //#######################################################################################
  // override "Today" button to also grab the time.
  //#######################################################################################
  $.datepicker._base_gotoToday = $.datepicker._gotoToday;
  $.datepicker._gotoToday = function(id) {
    var inst = this._getInst($(id)[0]),
        $dp = inst.dpDiv;
    this._base_gotoToday(id);
    var tp_inst = this._get(inst, 'timepicker');
    selectLocalTimeZone(tp_inst);
    var now = new Date();
    this._setTime(inst, now);
    $( '.ui-datepicker-today', $dp).click();
  };

  //#######################################################################################
  // Disable & enable the Time in the datetimepicker
  //#######################################################################################
  $.datepicker._disableTimepickerDatepicker = function(target) {
    var inst = this._getInst(target);
    if (!inst) { return; }

    var tp_inst = this._get(inst, 'timepicker');
    $(target).datepicker('getDate'); // Init selected[Year|Month|Day]
    if (tp_inst) {
      tp_inst._defaults.showTimepicker = false;
      tp_inst._updateDateTime(inst);
    }
  };

  $.datepicker._enableTimepickerDatepicker = function(target) {
    var inst = this._getInst(target);
    if (!inst) { return; }

    var tp_inst = this._get(inst, 'timepicker');
    $(target).datepicker('getDate'); // Init selected[Year|Month|Day]
    if (tp_inst) {
      tp_inst._defaults.showTimepicker = true;
      tp_inst._addTimePicker(inst); // Could be disabled on page load
      tp_inst._updateDateTime(inst);
    }
  };

  //#######################################################################################
  // Create our own set time function
  //#######################################################################################
  $.datepicker._setTime = function(inst, date) {
    var tp_inst = this._get(inst, 'timepicker');
    if (tp_inst) {
      var defaults = tp_inst._defaults,
        // calling _setTime with no date sets time to defaults
        hour = date ? date.getHours() : defaults.hour,
             minute = date ? date.getMinutes() : defaults.minute,
             second = date ? date.getSeconds() : defaults.second,
             millisec = date ? date.getMilliseconds() : defaults.millisec;
      //check if within min/max times..
      // correct check if within min/max times.   
      // Rewritten by Scott A. Woodward
      var hourEq = hour === defaults.hourMin,
          minuteEq = minute === defaults.minuteMin,
          secondEq = second === defaults.secondMin;
      var reset = false;
      if(hour < defaults.hourMin || hour > defaults.hourMax)  
        reset = true;
      else if( (minute < defaults.minuteMin || minute > defaults.minuteMax) && hourEq)
        reset = true;
      else if( (second < defaults.secondMin || second > defaults.secondMax ) && hourEq && minuteEq)
        reset = true;
      else if( (millisec < defaults.millisecMin || millisec > defaults.millisecMax) && hourEq && minuteEq && secondEq)
        reset = true;
      if(reset) {
        hour = defaults.hourMin;
        minute = defaults.minuteMin;
        second = defaults.secondMin;
        millisec = defaults.millisecMin;
      }
      tp_inst.hour = hour;
      tp_inst.minute = minute;
      tp_inst.second = second;
      tp_inst.millisec = millisec;
      if (tp_inst.hour_slider) tp_inst.hour_slider.slider('value', hour);
      if (tp_inst.minute_slider) tp_inst.minute_slider.slider('value', minute);
      if (tp_inst.second_slider) tp_inst.second_slider.slider('value', second);
      if (tp_inst.millisec_slider) tp_inst.millisec_slider.slider('value', millisec);

      tp_inst._onTimeChange();
      tp_inst._updateDateTime(inst);
    }
  };

  //#######################################################################################
  // Create new public method to set only time, callable as $().datepicker('setTime', date)
  //#######################################################################################
  $.datepicker._setTimeDatepicker = function(target, date, withDate) {
    var inst = this._getInst(target);
    if (!inst) { return; }

    var tp_inst = this._get(inst, 'timepicker');

    if (tp_inst) {
      this._setDateFromField(inst);
      var tp_date;
      if (date) {
        if (typeof date == "string") {
          tp_inst._parseTime(date, withDate);
          tp_date = new Date();
          tp_date.setHours(tp_inst.hour, tp_inst.minute, tp_inst.second, tp_inst.millisec);
        }
        else { tp_date = new Date(date.getTime()); }
        if (tp_date.toString() == 'Invalid Date') { tp_date = undefined; }
        this._setTime(inst, tp_date);
      }
    }

  };

  //#######################################################################################
  // override setDate() to allow setting time too within Date object
  //#######################################################################################
  $.datepicker._base_setDateDatepicker = $.datepicker._setDateDatepicker;
  $.datepicker._setDateDatepicker = function(target, date) {
    var inst = this._getInst(target);
    if (!inst) { return; }

    var tp_date = (date instanceof Date) ? new Date(date.getTime()) : date;

    this._updateDatepicker(inst);
    this._base_setDateDatepicker.apply(this, arguments);
    this._setTimeDatepicker(target, tp_date, true);
  };

  //#######################################################################################
  // override getDate() to allow getting time too within Date object
  //#######################################################################################
  $.datepicker._base_getDateDatepicker = $.datepicker._getDateDatepicker;
  $.datepicker._getDateDatepicker = function(target, noDefault) {
    var inst = this._getInst(target);
    if (!inst) { return; }

    var tp_inst = this._get(inst, 'timepicker');

    if (tp_inst) {
      this._setDateFromField(inst, noDefault);
      var date = this._getDate(inst);
      if (date && tp_inst._parseTime($(target).val(), tp_inst.timeOnly)) { date.setHours(tp_inst.hour, tp_inst.minute, tp_inst.second, tp_inst.millisec); }
      return date;
    }
    return this._base_getDateDatepicker(target, noDefault);
  };

  //#######################################################################################
  // override parseDate() because UI 1.8.14 throws an error about "Extra characters"
  // An option in datapicker to ignore extra format characters would be nicer.
  //#######################################################################################
  $.datepicker._base_parseDate = $.datepicker.parseDate;
  $.datepicker.parseDate = function(format, value, settings) {
    var splitRes = splitDateTime(format, value, settings);
    return $.datepicker._base_parseDate(format, splitRes[0], settings);
  };

  //#######################################################################################
  // override formatDate to set date with time to the input
  //#######################################################################################
  $.datepicker._base_formatDate = $.datepicker._formatDate;
  $.datepicker._formatDate = function(inst, day, month, year){
    var tp_inst = this._get(inst, 'timepicker');
    if(tp_inst) {
      tp_inst._updateDateTime(inst);
      return tp_inst.$input.val();
    }
    return this._base_formatDate(inst);
  };

  //#######################################################################################
  // override options setter to add time to maxDate(Time) and minDate(Time). MaxDate
  //#######################################################################################
  $.datepicker._base_optionDatepicker = $.datepicker._optionDatepicker;
  $.datepicker._optionDatepicker = function(target, name, value) {
    var inst = this._getInst(target);
    if (!inst) { return null; }

    var tp_inst = this._get(inst, 'timepicker');
    if (tp_inst) {
      var min = null, max = null, onselect = null;
      if (typeof name == 'string') { // if min/max was set with the string
        if (name === 'minDate' || name === 'minDateTime' ) {
          min = value;
        }
        else {
          if (name === 'maxDate' || name === 'maxDateTime') {
            max = value;
          }
          else {
            if (name === 'onSelect') {
              onselect = value;
            }
          }
        }
      } else {
        if (typeof name == 'object') { //if min/max was set with the JSON
          if (name.minDate) {
            min = name.minDate;
          } else {
            if (name.minDateTime) {
              min = name.minDateTime;
            } else {
              if (name.maxDate) {
                max = name.maxDate;
              } else {
                if (name.maxDateTime) {
                  max = name.maxDateTime;
                }
              }
            }
          }
        }
      }
      if(min) { //if min was set
        if (min === 0) {
          min = new Date();
        } else {
          min = new Date(min);
        }

        tp_inst._defaults.minDate = min;
        tp_inst._defaults.minDateTime = min;
      } else if (max) { //if max was set
        if(max===0) {
          max=new Date();
        } else {
          max= new Date(max);
        }
        tp_inst._defaults.maxDate = max;
        tp_inst._defaults.maxDateTime = max;
      } else if (onselect) {
        tp_inst._defaults.onSelect = onselect;
      }
    }
    if (value === undefined) {
      return this._base_optionDatepicker(target, name);
    }
    return this._base_optionDatepicker(target, name, value);
  };

  //#######################################################################################
  // jQuery extend now ignores nulls!
  //#######################################################################################
  function extendRemove(target, props) {
    $.extend(target, props);
    for (var name in props) {
      if (props[name] === null || props[name] === undefined) {
        target[name] = props[name];
      }
    }
    return target;
  }

  //#######################################################################################
  // Splits datetime string into date ans time substrings.
  // Throws exception when date can't be parsed
  // If only date is present, time substring eill be '' 
  //#######################################################################################
  var splitDateTime = function(dateFormat, dateTimeString, dateSettings)
  {
    try {
      var date = $.datepicker._base_parseDate(dateFormat, dateTimeString, dateSettings);
    } catch (err) {
      if (err.indexOf(":") >= 0) {
        // Hack!  The error message ends with a colon, a space, and
        // the "extra" characters.  We rely on that instead of
        // attempting to perfectly reproduce the parsing algorithm.
        var dateStringLength = dateTimeString.length-(err.length-err.indexOf(':')-2);
        var timeString = dateTimeString.substring(dateStringLength);

        return [dateTimeString.substring(0, dateStringLength), dateTimeString.substring(dateStringLength)];

      } else {
        throw err;
      }
    }
    return [dateTimeString, ''];
  };

  //#######################################################################################
  // Internal function to parse datetime interval
  // Returns: {date: Date, timeObj: Object}, where
  //   date - parsed date without time (type Date)
  //   timeObj = {hour: , minute: , second: , millisec: } - parsed time. Optional
  //#######################################################################################
  var parseDateTimeInternal = function(dateFormat, timeFormat, dateTimeString, dateSettings, timeSettings)
  {
    var date;
    var splitRes = splitDateTime(dateFormat, dateTimeString, dateSettings);
    date = $.datepicker._base_parseDate(dateFormat, splitRes[0], dateSettings);
    if (splitRes[1] !== '')
    {
      var timeString = splitRes[1];
      var separator = timeSettings && timeSettings.separator ? timeSettings.separator : $.timepicker._defaults.separator;            
      if ( timeString.indexOf(separator) !== 0) {
        throw 'Missing time separator';
      }
      timeString = timeString.substring(separator.length);
      var parsedTime = $.datepicker.parseTime(timeFormat, timeString, timeSettings);
      if (parsedTime === null) {
        throw 'Wrong time format';
      }
      return {date: date, timeObj: parsedTime};
    } else {
      return {date: date};
    }
  };

  //#######################################################################################
  // Internal function to set timezone_select to the local timezone
  //#######################################################################################
  var selectLocalTimeZone = function(tp_inst, date)
  {
    if (tp_inst && tp_inst.timezone_select) {
      tp_inst._defaults.useLocalTimezone = true;
      var now = typeof date !== 'undefined' ? date : new Date();
      var tzoffset = timeZoneString(now);
      if (tp_inst._defaults.timezoneIso8601) {
        tzoffset = tzoffset.substring(0, 3) + ':' + tzoffset.substring(3);
      }
      tp_inst.timezone_select.val(tzoffset);
    }
  };

  // Input: Date Object
  // Output: String with timezone offset, e.g. '+0100'
  var timeZoneString = function(date)
  {
    var off = date.getTimezoneOffset() * -10100 / 60;
    var timezone = (off >= 0 ? '+' : '-') + Math.abs(off).toString().substr(1);
    return timezone;
  };

  $.timepicker = new Timepicker(); // singleton instance
  $.timepicker.version = "1.0.1";

  })(jQuery);

  (function($){
    $.getQuery = function( query ) {
      query = query.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
      var expr = "[\\?&]"+query+"=([^&#]*)";
      var regex = new RegExp( expr );
      var results = regex.exec( window.location.href );
      if( results !== null ) {
        return results[1];
        return decodeURIComponent(results[1].replace(/\+/g, " "));
      } else {
        return false;
      }
    };
  })(jQuery);

  function show_alert(msg) {
    alert(msg);
  }


  /*!
   * jQCloud Plugin for jQuery
   *
   * Version 1.0.0
   *
   * Copyright 2011, Luca Ongaro
   * Licensed under the MIT license.
   *
   * Date: Tue Apr 17 15:06:02 +0200 2012
   */
  (function(a){"use strict",a.fn.jQCloud=function(b,c){var d=this,e=d.attr("id")||Math.floor(Math.random()*1e6).toString(36),f={width:d.width(),height:d.height(),center:{x:(c&&c.width?c.width:d.width())/2,y:(c&&c.height?c.height:d.height())/2},delayedMode:b.length>50,shape:!1};c=a.extend(f,c||{}),d.addClass("jqcloud").width(c.width).height(c.height),d.css("position")==="static"&&d.css("position","relative");var g=function(){var f=function(a,b){var c=function(a,b){return Math.abs(2*a.offsetLeft+a.offsetWidth-2*b.offsetLeft-b.offsetWidth)<a.offsetWidth+b.offsetWidth&&Math.abs(2*a.offsetTop+a.offsetHeight-2*b.offsetTop-b.offsetHeight)<a.offsetHeight+b.offsetHeight?!0:!1},d=0;for(d=0;d<b.length;d++)if(c(a,b[d]))return!0;return!1};for(var g=0;g<b.length;g++)b[g].weight=parseFloat(b[g].weight,10);b.sort(function(a,b){return a.weight<b.weight?1:a.weight>b.weight?-1:0});var h=c.shape==="rectangular"?18:2,i=[],j=c.width/c.height,k=function(g,k){var l=e+"_word_"+g,m="#"+l,n=6.28*Math.random(),o=0,p=0,q=0,r=5,s="",t="",u="";k.html=a.extend(k.html,{id:l}),k.html&&k.html["class"]&&(s=k.html["class"],delete k.html["class"]),b[0].weight>b[b.length-1].weight&&(r=Math.round((k.weight-b[b.length-1].weight)/(b[0].weight-b[b.length-1].weight)*9)+1),u=a("<span>").attr(k.html).addClass("w"+r+" "+s),k.link?(typeof k["link"]=="string"&&(k.link={href:k.link}),k.link=a.extend(k.link,{href:encodeURI(k.link.href).replace(/'/g,"%27")}),t=a("<a>").attr(k.link).text(k.text)):t=k.text,u.append(t);if(!!k.handlers)for(var v in k.handlers)k.handlers.hasOwnProperty(v)&&typeof k.handlers[v]=="function"&&a(u).bind(v,k.handlers[v]);d.append(u);var w=u.width(),x=u.height(),y=c.center.x-w/2,z=c.center.y-x/2,A=u[0].style;A.position="absolute",A.left=y+"px",A.top=z+"px";while(f(document.getElementById(l),i)){if(c.shape==="rectangular"){p++,p*h>(1+Math.floor(q/2))*h*(q%4%2===0?1:j)&&(p=0,q++);switch(q%4){case 1:y+=h*j+Math.random()*2;break;case 2:z-=h+Math.random()*2;break;case 3:y-=h*j+Math.random()*2;break;case 0:z+=h+Math.random()*2}}else o+=h,n+=(g%2===0?1:-1)*h,y=c.center.x-w/2+o*Math.cos(n)*j,z=c.center.y+o*Math.sin(n)-x/2;A.left=y+"px",A.top=z+"px"}i.push(document.getElementById(l)),a.isFunction(k.afterWordRender)&&k.afterWordRender.call(u)},l=function(e){e=e||0,e<b.length?(k(e,b[e]),setTimeout(function(){l(e+1)},10)):a.isFunction(c.afterCloudRender)&&c.afterCloudRender.call(d)};c.delayedMode?l():(a.each(b,k),a.isFunction(c.afterCloudRender)&&c.afterCloudRender.call(d))};return setTimeout(function(){g()},10),d}})(jQuery);



  /**
   * jQuery Galleriffic plugin
   *
   * Copyright (c) 2008 Trent Foley (http://trentacular.com)
   * Licensed under the MIT License:
   *   http://www.opensource.org/licenses/mit-license.php
   *
   * Much thanks to primary contributer Ponticlaro (http://www.ponticlaro.com)
   */
  ;

  (function($) {
    // Globally keep track of all images by their unique hash.  Each item is an image data object.
    var allImages = {};
    var imageCounter = 0;

    // Galleriffic static class
    $.galleriffic = {
      version: '2.0.1',

    // Strips invalid characters and any leading # characters
    normalizeHash: function(hash) {
      return hash.replace(/^.*#/, '').replace(/\?.*$/, '');
    },

    getImage: function(hash) {
      if (!hash)
    return undefined;

  hash = $.galleriffic.normalizeHash(hash);
  return allImages[hash];
    },

    // Global function that looks up an image by its hash and displays the image.
    // Returns false when an image is not found for the specified hash.
    // @param {String} hash This is the unique hash value assigned to an image.
    gotoImage: function(hash) {
      var imageData = $.galleriffic.getImage(hash);
      if (!imageData)
        return false;

      var gallery = imageData.gallery;
      gallery.gotoImage(imageData);

      return true;
    },

    // Removes an image from its respective gallery by its hash.
    // Returns false when an image is not found for the specified hash or the
    // specified owner gallery does match the located images gallery.
    // @param {String} hash This is the unique hash value assigned to an image.
    // @param {Object} ownerGallery (Optional) When supplied, the located images
    // gallery is verified to be the same as the specified owning gallery before
    // performing the remove operation.
    removeImageByHash: function(hash, ownerGallery) {
      var imageData = $.galleriffic.getImage(hash);
      if (!imageData)
        return false;

      var gallery = imageData.gallery;
      if (ownerGallery && ownerGallery != gallery)
        return false;

      return gallery.removeImageByIndex(imageData.index);
    }
    };

    var defaults = {
      delay:                     3000,
      numThumbs:                 20,
      preloadAhead:              40, // Set to -1 to preload all images
      enableTopPager:            false,
      enableBottomPager:         true,
      maxPagesToShow:            7,
      imageContainerSel:         '',
      captionContainerSel:       '',
      controlsContainerSel:      '',
      loadingContainerSel:       '',
      renderSSControls:          true,
      renderNavControls:         true,
      playLinkText:              'Play',
      pauseLinkText:             'Pause',
      prevLinkText:              'Previous',
      nextLinkText:              'Next',
      nextPageLinkText:          'Next &rsaquo;',
      prevPageLinkText:          '&lsaquo; Prev',
      enableHistory:             false,
      enableKeyboardNavigation:  true,
      autoStart:                 false,
      syncTransitions:           false,
      defaultTransitionDuration: 1000,
      onSlideChange:             undefined, // accepts a delegate like such: function(prevIndex, nextIndex) { ... }
        onTransitionOut:           undefined, // accepts a delegate like such: function(slide, caption, isSync, callback) { ... }
        onTransitionIn:            undefined, // accepts a delegate like such: function(slide, caption, isSync) { ... }
        onPageTransitionOut:       undefined, // accepts a delegate like such: function(callback) { ... }
        onPageTransitionIn:        undefined, // accepts a delegate like such: function() { ... }
        onImageAdded:              undefined, // accepts a delegate like such: function(imageData, $li) { ... }
        onImageRemoved:            undefined  // accepts a delegate like such: function(imageData, $li) { ... }
    };

    // Primary Galleriffic initialization function that should be called on the thumbnail container.
    $.fn.galleriffic = function(settings) {
      //  Extend Gallery Object
      $.extend(this, {
        // Returns the version of the script
        version: $.galleriffic.version,

        // Current state of the slideshow
        isSlideshowRunning: false,
        slideshowTimeout: undefined,

        // This function is attached to the click event of generated hyperlinks within the gallery
        clickHandler: function(e, link) {
          this.pause();

          if (!this.enableHistory) {
            // The href attribute holds the unique hash for an image
            var hash = $.galleriffic.normalizeHash($(link).attr('href'));
            $.galleriffic.gotoImage(hash);
            e.preventDefault();
          }
        },

        // Appends an image to the end of the set of images.  Argument listItem can be either a jQuery DOM element or arbitrary html.
        // @param listItem Either a jQuery object or a string of html of the list item that is to be added to the gallery.
        appendImage: function(listItem) {
          this.addImage(listItem, false, false);
          return this;
        },

        // Inserts an image into the set of images.  Argument listItem can be either a jQuery DOM element or arbitrary html.
        // @param listItem Either a jQuery object or a string of html of the list item that is to be added to the gallery.
        // @param {Integer} position The index within the gallery where the item shouold be added.
        insertImage: function(listItem, position) {
          this.addImage(listItem, false, true, position);
          return this;
        },

        // Adds an image to the gallery and optionally inserts/appends it to the DOM (thumbExists)
        // @param listItem Either a jQuery object or a string of html of the list item that is to be added to the gallery.
        // @param {Boolean} thumbExists Specifies whether the thumbnail already exists in the DOM or if it needs to be added.
        // @param {Boolean} insert Specifies whether the the image is appended to the end or inserted into the gallery.
        // @param {Integer} position The index within the gallery where the item shouold be added.
        addImage: function(listItem, thumbExists, insert, position) {
          var $li = ( typeof listItem === "string" ) ? $(listItem) : listItem;        
          var $aThumb = $li.find('a.thumb');
          var slideUrl = $aThumb.attr('href');
          var title = $aThumb.attr('title');
          var $caption = $li.find('.caption').remove();
          var hash = $aThumb.attr('name');

          // Increment the image counter
          imageCounter++;

          // Autogenerate a hash value if none is present or if it is a duplicate
          if (!hash || allImages[''+hash]) {
            hash = imageCounter;
          }

          // Set position to end when not specified
          if (!insert)
            position = this.data.length;

          var imageData = {
            title:title,
            slideUrl:slideUrl,
            caption:$caption,
            hash:hash,
            gallery:this,
            index:position
          };

          // Add the imageData to this gallery's array of images
          if (insert) {
            this.data.splice(position, 0, imageData);

            // Reset index value on all imageData objects
            this.updateIndices(position);
          }
          else {
            this.data.push(imageData);
          }

          var gallery = this;

          // Add the element to the DOM
          if (!thumbExists) {
            // Update thumbs passing in addition post transition out handler
            this.updateThumbs(function() {
              var $thumbsUl = gallery.find('ul.thumbs');
              if (insert)
              $thumbsUl.children(':eq('+position+')').before($li);
                else
                $thumbsUl.append($li);

                if (gallery.onImageAdded)
                gallery.onImageAdded(imageData, $li);
                });
              }

              // Register the image globally
              allImages[''+hash] = imageData;

              // Setup attributes and click handler
              $aThumb.attr('rel', 'history')
              .attr('href', '#'+hash)
              .removeAttr('name')
              .click(function(e) {
                gallery.clickHandler(e, this);
              });

              return this;
        },

        // Removes an image from the gallery based on its index.
        // Returns false when the index is out of range.
        removeImageByIndex: function(index) {
          if (index < 0 || index >= this.data.length)
            return false;

          var imageData = this.data[index];
          if (!imageData)
            return false;

          this.removeImage(imageData);

          return true;
        },

        // Convenience method that simply calls the global removeImageByHash method.
        removeImageByHash: function(hash) {
          return $.galleriffic.removeImageByHash(hash, this);
        },

        // Removes an image from the gallery.
        removeImage: function(imageData) {
          var index = imageData.index;

          // Remove the image from the gallery data array
          this.data.splice(index, 1);

          // Remove the global registration
          delete allImages[''+imageData.hash];

          // Remove the image's list item from the DOM
          this.updateThumbs(function() {
            var $li = gallery.find('ul.thumbs')
            .children(':eq('+index+')')
              .remove();

              if (gallery.onImageRemoved)
              gallery.onImageRemoved(imageData, $li);
              });

            // Update each image objects index value
            this.updateIndices(index);

            return this;
            },

            // Updates the index values of the each of the images in the gallery after the specified index
            updateIndices: function(startIndex) {
              for (i = startIndex; i < this.data.length; i++) {
                this.data[i].index = i;
              }

              return this;
            },

            // Scraped the thumbnail container for thumbs and adds each to the gallery
            initializeThumbs: function() {
              this.data = [];
              var gallery = this;

              this.find('ul.thumbs > li').each(function(i) {
                gallery.addImage($(this), true, false);
              });

              return this;
            },

            isPreloadComplete: false,

            // Initalizes the image preloader
            preloadInit: function() {
              if (this.preloadAhead == 0) return this;

              this.preloadStartIndex = this.currentImage.index;
              var nextIndex = this.getNextIndex(this.preloadStartIndex);
              return this.preloadRecursive(this.preloadStartIndex, nextIndex);
            },

            // Changes the location in the gallery the preloader should work
            // @param {Integer} index The index of the image where the preloader should restart at.
            preloadRelocate: function(index) {
              // By changing this startIndex, the current preload script will restart
              this.preloadStartIndex = index;
              return this;
            },

            // Recursive function that performs the image preloading
            // @param {Integer} startIndex The index of the first image the current preloader started on.
            // @param {Integer} currentIndex The index of the current image to preload.
            preloadRecursive: function(startIndex, currentIndex) {
              // Check if startIndex has been relocated
              if (startIndex != this.preloadStartIndex) {
                var nextIndex = this.getNextIndex(this.preloadStartIndex);
                return this.preloadRecursive(this.preloadStartIndex, nextIndex);
              }

              var gallery = this;

              // Now check for preloadAhead count
              var preloadCount = currentIndex - startIndex;
              if (preloadCount < 0)
                preloadCount = this.data.length-1-startIndex+currentIndex;
              if (this.preloadAhead >= 0 && preloadCount > this.preloadAhead) {
                // Do this in order to keep checking for relocated start index
                setTimeout(function() { gallery.preloadRecursive(startIndex, currentIndex); }, 500);
                return this;
              }

              var imageData = this.data[currentIndex];
              if (!imageData)
                return this;

              // If already loaded, continue
              if (imageData.image)
                return this.preloadNext(startIndex, currentIndex); 

              // Preload the image
              var image = new Image();

              image.onload = function() {
                imageData.image = this;
                gallery.preloadNext(startIndex, currentIndex);
              };

              image.alt = imageData.title;
              image.src = imageData.slideUrl;

              return this;
            },

            // Called by preloadRecursive in order to preload the next image after the previous has loaded.
            // @param {Integer} startIndex The index of the first image the current preloader started on.
            // @param {Integer} currentIndex The index of the current image to preload.
            preloadNext: function(startIndex, currentIndex) {
              var nextIndex = this.getNextIndex(currentIndex);
              if (nextIndex == startIndex) {
                this.isPreloadComplete = true;
              } else {
                // Use setTimeout to free up thread
                var gallery = this;
                setTimeout(function() { gallery.preloadRecursive(startIndex, nextIndex); }, 100);
              }

              return this;
            },

            // Safe way to get the next image index relative to the current image.
            // If the current image is the last, returns 0
            getNextIndex: function(index) {
              var nextIndex = index+1;
              if (nextIndex >= this.data.length)
                nextIndex = 0;
              return nextIndex;
            },

            // Safe way to get the previous image index relative to the current image.
            // If the current image is the first, return the index of the last image in the gallery.
            getPrevIndex: function(index) {
              var prevIndex = index-1;
              if (prevIndex < 0)
                prevIndex = this.data.length-1;
              return prevIndex;
            },

            // Pauses the slideshow
            pause: function() {
              this.isSlideshowRunning = false;
              if (this.slideshowTimeout) {
                clearTimeout(this.slideshowTimeout);
                this.slideshowTimeout = undefined;
              }

              if (this.$controlsContainer) {
                this.$controlsContainer
                  .find('div.ss-controls a').removeClass().addClass('play')
                  .attr('title', this.playLinkText)
                  .attr('href', '#play')
                  .html(this.playLinkText);
              }

              return this;
            },

            // Plays the slideshow
            play: function() {
              this.isSlideshowRunning = true;

              if (this.$controlsContainer) {
                this.$controlsContainer
                  .find('div.ss-controls a').removeClass().addClass('pause')
                  .attr('title', this.pauseLinkText)
                  .attr('href', '#pause')
                  .html(this.pauseLinkText);
              }

              if (!this.slideshowTimeout) {
                var gallery = this;
                this.slideshowTimeout = setTimeout(function() { gallery.ssAdvance(); }, this.delay);
              }

              return this;
            },

            // Toggles the state of the slideshow (playing/paused)
            toggleSlideshow: function() {
              if (this.isSlideshowRunning)
                this.pause();
              else
                this.play();

              return this;
            },

            // Advances the slideshow to the next image and delegates navigation to the
            // history plugin when history is enabled
            // enableHistory is true
            ssAdvance: function() {
              if (this.isSlideshowRunning)
                this.next(true);

              return this;
            },

            // Advances the gallery to the next image.
            // @param {Boolean} dontPause Specifies whether to pause the slideshow.
            // @param {Boolean} bypassHistory Specifies whether to delegate navigation to the history plugin when history is enabled.  
            next: function(dontPause, bypassHistory) {
              this.gotoIndex(this.getNextIndex(this.currentImage.index), dontPause, bypassHistory);
              return this;
            },

            // Navigates to the previous image in the gallery.
            // @param {Boolean} dontPause Specifies whether to pause the slideshow.
            // @param {Boolean} bypassHistory Specifies whether to delegate navigation to the history plugin when history is enabled.
            previous: function(dontPause, bypassHistory) {
              this.gotoIndex(this.getPrevIndex(this.currentImage.index), dontPause, bypassHistory);
              return this;
            },

            // Navigates to the next page in the gallery.
            // @param {Boolean} dontPause Specifies whether to pause the slideshow.
            // @param {Boolean} bypassHistory Specifies whether to delegate navigation to the history plugin when history is enabled.
            nextPage: function(dontPause, bypassHistory) {
              var page = this.getCurrentPage();
              var lastPage = this.getNumPages() - 1;
              if (page < lastPage) {
                var startIndex = page * this.numThumbs;
                var nextPage = startIndex + this.numThumbs;
                this.gotoIndex(nextPage, dontPause, bypassHistory);
              }

              return this;
            },

            // Navigates to the previous page in the gallery.
            // @param {Boolean} dontPause Specifies whether to pause the slideshow.
            // @param {Boolean} bypassHistory Specifies whether to delegate navigation to the history plugin when history is enabled.
            previousPage: function(dontPause, bypassHistory) {
              var page = this.getCurrentPage();
              if (page > 0) {
                var startIndex = page * this.numThumbs;
                var prevPage = startIndex - this.numThumbs;        
                this.gotoIndex(prevPage, dontPause, bypassHistory);
              }

              return this;
            },

            // Navigates to the image at the specified index in the gallery
            // @param {Integer} index The index of the image in the gallery to display.
            // @param {Boolean} dontPause Specifies whether to pause the slideshow.
            // @param {Boolean} bypassHistory Specifies whether to delegate navigation to the history plugin when history is enabled.
            gotoIndex: function(index, dontPause, bypassHistory) {
              if (!dontPause)
                this.pause();

              if (index < 0) index = 0;
              else if (index >= this.data.length) index = this.data.length-1;

              var imageData = this.data[index];

              if (!bypassHistory && this.enableHistory)
                $.historyLoad(String(imageData.hash));  // At the moment, historyLoad only accepts string arguments
              else
                this.gotoImage(imageData);

              return this;
            },

            // This function is garaunteed to be called anytime a gallery slide changes.
            // @param {Object} imageData An object holding the image metadata of the image to navigate to.
            gotoImage: function(imageData) {
              var index = imageData.index;

              if (this.onSlideChange)
                this.onSlideChange(this.currentImage.index, index);

              this.currentImage = imageData;
              this.preloadRelocate(index);

              this.refresh();

              return this;
            },

            // Returns the default transition duration value.  The value is halved when not
            // performing a synchronized transition.
            // @param {Boolean} isSync Specifies whether the transitions are synchronized.
            getDefaultTransitionDuration: function(isSync) {
              if (isSync)
                return this.defaultTransitionDuration;
              return this.defaultTransitionDuration / 2;
            },

            // Rebuilds the slideshow image and controls and performs transitions
            refresh: function() {
              var imageData = this.currentImage;
              if (!imageData)
                return this;

              var index = imageData.index;

              // Update Controls
              if (this.$controlsContainer) {
                this.$controlsContainer
                  .find('div.nav-controls a.prev').attr('href', '#'+this.data[this.getPrevIndex(index)].hash).end()
                  .find('div.nav-controls a.next').attr('href', '#'+this.data[this.getNextIndex(index)].hash);
              }

              var previousSlide = this.$imageContainer.find('span.current').addClass('previous').removeClass('current');
              var previousCaption = 0;

              if (this.$captionContainer) {
                previousCaption = this.$captionContainer.find('span.current').addClass('previous').removeClass('current');
              }

              // Perform transitions simultaneously if syncTransitions is true and the next image is already preloaded
              var isSync = this.syncTransitions && imageData.image;

              // Flag we are transitioning
              var isTransitioning = true;
              var gallery = this;

              var transitionOutCallback = function() {
                // Flag that the transition has completed
                isTransitioning = false;

                // Remove the old slide
                previousSlide.remove();

                // Remove old caption
                if (previousCaption)
                  previousCaption.remove();

                if (!isSync) {
                  if (imageData.image && imageData.hash == gallery.data[gallery.currentImage.index].hash) {
                    gallery.buildImage(imageData, isSync);
                  } else {
                    // Show loading container
                    if (gallery.$loadingContainer) {
                      gallery.$loadingContainer.show();
                    }
                  }
                }
              };

              if (previousSlide.length == 0) {
                // For the first slide, the previous slide will be empty, so we will call the callback immediately
                transitionOutCallback();
              } else {
                if (this.onTransitionOut) {
                  this.onTransitionOut(previousSlide, previousCaption, isSync, transitionOutCallback);
                } else {
                  previousSlide.fadeTo(this.getDefaultTransitionDuration(isSync), 0.0, transitionOutCallback);
                  if (previousCaption)
                    previousCaption.fadeTo(this.getDefaultTransitionDuration(isSync), 0.0);
                }
              }

              // Go ahead and begin transitioning in of next image
              if (isSync)
                this.buildImage(imageData, isSync);

              if (!imageData.image) {
                var image = new Image();

                // Wire up mainImage onload event
                image.onload = function() {
                  imageData.image = this;

                  // Only build image if the out transition has completed and we are still on the same image hash
                  if (!isTransitioning && imageData.hash == gallery.data[gallery.currentImage.index].hash) {
                    gallery.buildImage(imageData, isSync);
                  }
                };

                // set alt and src
                image.alt = imageData.title;
                image.src = imageData.slideUrl;
              }

              // This causes the preloader (if still running) to relocate out from the currentIndex
              this.relocatePreload = true;

              return this.syncThumbs();
            },

            // Called by the refresh method after the previous image has been transitioned out or at the same time
            // as the out transition when performing a synchronous transition.
            // @param {Object} imageData An object holding the image metadata of the image to build.
            // @param {Boolean} isSync Specifies whether the transitions are synchronized.
            buildImage: function(imageData, isSync) {
              var gallery = this;
              var nextIndex = this.getNextIndex(imageData.index);

              // Construct new hidden span for the image
              var newSlide = this.$imageContainer
                .append('<span class="image-wrapper current"><a class="advance-link" rel="history" href="#'+this.data[nextIndex].hash+'" title="'+imageData.title+'">&nbsp;</a></span>')
                .find('span.current').css('opacity', '0');

              newSlide.find('a')
                .append(imageData.image)
                .click(function(e) {
                  gallery.clickHandler(e, this);
                });

              var newCaption = 0;
              if (this.$captionContainer) {
                // Construct new hidden caption for the image
                newCaption = this.$captionContainer
                  .append('<span class="image-caption current"></span>')
                  .find('span.current').css('opacity', '0')
                  .append(imageData.caption);
              }

              // Hide the loading conatiner
              if (this.$loadingContainer) {
                this.$loadingContainer.hide();
              }

              // Transition in the new image
              if (this.onTransitionIn) {
                this.onTransitionIn(newSlide, newCaption, isSync);
              } else {
                newSlide.fadeTo(this.getDefaultTransitionDuration(isSync), 1.0);
                if (newCaption)
                  newCaption.fadeTo(this.getDefaultTransitionDuration(isSync), 1.0);
              }

              if (this.isSlideshowRunning) {
                if (this.slideshowTimeout)
                  clearTimeout(this.slideshowTimeout);

                this.slideshowTimeout = setTimeout(function() { gallery.ssAdvance(); }, this.delay);
              }

              return this;
            },

            // Returns the current page index that should be shown for the currentImage
            getCurrentPage: function() {
              return Math.floor(this.currentImage.index / this.numThumbs);
            },

            // Applies the selected class to the current image's corresponding thumbnail.
            // Also checks if the current page has changed and updates the displayed page of thumbnails if necessary.
            syncThumbs: function() {
              var page = this.getCurrentPage();
              if (page != this.displayedPage)
                this.updateThumbs();

              // Remove existing selected class and add selected class to new thumb
              var $thumbs = this.find('ul.thumbs').children();
              $thumbs.filter('.selected').removeClass('selected');
              $thumbs.eq(this.currentImage.index).addClass('selected');

              return this;
            },

            // Performs transitions on the thumbnails container and updates the set of
            // thumbnails that are to be displayed and the navigation controls.
            // @param {Delegate} postTransitionOutHandler An optional delegate that is called after
            // the thumbnails container has transitioned out and before the thumbnails are rebuilt.
            updateThumbs: function(postTransitionOutHandler) {
              var gallery = this;
              var transitionOutCallback = function() {
                // Call the Post-transition Out Handler
                if (postTransitionOutHandler)
                  postTransitionOutHandler();

                gallery.rebuildThumbs();

                // Transition In the thumbsContainer
                if (gallery.onPageTransitionIn)
                  gallery.onPageTransitionIn();
                else
                  gallery.show();
              };

              // Transition Out the thumbsContainer
              if (this.onPageTransitionOut) {
                this.onPageTransitionOut(transitionOutCallback);
              } else {
                this.hide();
                transitionOutCallback();
              }

              return this;
            },

            // Updates the set of thumbnails that are to be displayed and the navigation controls.
            rebuildThumbs: function() {
              var needsPagination = this.data.length > this.numThumbs;

              // Rebuild top pager
              if (this.enableTopPager) {
                var $topPager = this.find('div.top');
                if ($topPager.length == 0)
                  $topPager = this.prepend('<div class="top pagination"></div>').find('div.top');
                else
                  $topPager.empty();

                if (needsPagination)
                  this.buildPager($topPager);
              }

              // Rebuild bottom pager
              if (this.enableBottomPager) {
                var $bottomPager = this.find('div.bottom');
                if ($bottomPager.length == 0)
                  $bottomPager = this.append('<div class="bottom pagination"></div>').find('div.bottom');
                else
                  $bottomPager.empty();

                if (needsPagination)
                  this.buildPager($bottomPager);
              }

              var page = this.getCurrentPage();
              var startIndex = page*this.numThumbs;
              var stopIndex = startIndex+this.numThumbs-1;
              if (stopIndex >= this.data.length)
                stopIndex = this.data.length-1;

              // Show/Hide thumbs
              var $thumbsUl = this.find('ul.thumbs');
              $thumbsUl.find('li').each(function(i) {
                var $li = $(this);
                if (i >= startIndex && i <= stopIndex) {
                  $li.show();
                } else {
                  $li.hide();
                }
              });

              this.displayedPage = page;

              // Remove the noscript class from the thumbs container ul
              $thumbsUl.removeClass('noscript');

              return this;
            },

            // Returns the total number of pages required to display all the thumbnails.
            getNumPages: function() {
              return Math.ceil(this.data.length/this.numThumbs);
            },

            // Rebuilds the pager control in the specified matched element.
            // @param {jQuery} pager A jQuery element set matching the particular pager to be rebuilt.
            buildPager: function(pager) {
              var gallery = this;
              var numPages = this.getNumPages();
              var page = this.getCurrentPage();
              var startIndex = page * this.numThumbs;
              var pagesRemaining = this.maxPagesToShow - 1;

              var pageNum = page - Math.floor((this.maxPagesToShow - 1) / 2) + 1;
              if (pageNum > 0) {
                var remainingPageCount = numPages - pageNum;
                if (remainingPageCount < pagesRemaining) {
                  pageNum = pageNum - (pagesRemaining - remainingPageCount);
                }
              }

              if (pageNum < 0) {
                pageNum = 0;
              }

              // Prev Page Link
              if (page > 0) {
                var prevPage = startIndex - this.numThumbs;
                pager.append('<a rel="history" href="#'+this.data[prevPage].hash+'" title="'+this.prevPageLinkText+'">'+this.prevPageLinkText+'</a>');
              }

              // Create First Page link if needed
              if (pageNum > 0) {
                this.buildPageLink(pager, 0, numPages);
                if (pageNum > 1)
                  pager.append('<span class="ellipsis">&hellip;</span>');

                pagesRemaining--;
              }

              // Page Index Links
              while (pagesRemaining > 0) {
                this.buildPageLink(pager, pageNum, numPages);
                pagesRemaining--;
                pageNum++;
              }

              // Create Last Page link if needed
              if (pageNum < numPages) {
                var lastPageNum = numPages - 1;
                if (pageNum < lastPageNum)
                  pager.append('<span class="ellipsis">&hellip;</span>');

                this.buildPageLink(pager, lastPageNum, numPages);
              }

              // Next Page Link
              var nextPage = startIndex + this.numThumbs;
              if (nextPage < this.data.length) {
                pager.append('<a rel="history" href="#'+this.data[nextPage].hash+'" title="'+this.nextPageLinkText+'">'+this.nextPageLinkText+'</a>');
              }

              pager.find('a').click(function(e) {
                gallery.clickHandler(e, this);
              });

              return this;
            },

            // Builds a single page link within a pager.  This function is called by buildPager
            // @param {jQuery} pager A jQuery element set matching the particular pager to be rebuilt.
            // @param {Integer} pageNum The page number of the page link to build.
            // @param {Integer} numPages The total number of pages required to display all thumbnails.
            buildPageLink: function(pager, pageNum, numPages) {
              var pageLabel = pageNum + 1;
              var currentPage = this.getCurrentPage();
              if (pageNum == currentPage)
                pager.append('<span class="current">'+pageLabel+'</span>');
              else if (pageNum < numPages) {
                var imageIndex = pageNum*this.numThumbs;
                pager.append('<a rel="history" href="#'+this.data[imageIndex].hash+'" title="'+pageLabel+'">'+pageLabel+'</a>');
              }

              return this;
            }
      });

      // Now initialize the gallery
      $.extend(this, defaults, settings);

      // Verify the history plugin is available
      if (this.enableHistory && !$.historyInit)
        this.enableHistory = false;

      // Select containers
      if (this.imageContainerSel) this.$imageContainer = $(this.imageContainerSel);
      if (this.captionContainerSel) this.$captionContainer = $(this.captionContainerSel);
      if (this.loadingContainerSel) this.$loadingContainer = $(this.loadingContainerSel);

      // Initialize the thumbails
      this.initializeThumbs();

      if (this.maxPagesToShow < 3)
        this.maxPagesToShow = 3;

      this.displayedPage = -1;
      this.currentImage = this.data[0];
      var gallery = this;

      // Hide the loadingContainer
      if (this.$loadingContainer)
        this.$loadingContainer.hide();

      // Setup controls
      if (this.controlsContainerSel) {
        this.$controlsContainer = $(this.controlsContainerSel).empty();

        if (this.renderSSControls) {
          if (this.autoStart) {
            this.$controlsContainer
              .append('<div class="ss-controls"><a href="#pause" class="pause" title="'+this.pauseLinkText+'">'+this.pauseLinkText+'</a></div>');
          } else {
            this.$controlsContainer
              .append('<div class="ss-controls"><a href="#play" class="play" title="'+this.playLinkText+'">'+this.playLinkText+'</a></div>');
          }

          this.$controlsContainer.find('div.ss-controls a')
            .click(function(e) {
              gallery.toggleSlideshow();
              e.preventDefault();
              return false;
            });
        }

        if (this.renderNavControls) {
          this.$controlsContainer
            .append('<div class="nav-controls"><a class="prev" rel="history" title="'+this.prevLinkText+'">'+this.prevLinkText+'</a><a class="next" rel="history" title="'+this.nextLinkText+'">'+this.nextLinkText+'</a></div>')
            .find('div.nav-controls a')
            .click(function(e) {
              gallery.clickHandler(e, this);
            });
        }
      }

      var initFirstImage = !this.enableHistory || !location.hash;
      if (this.enableHistory && location.hash) {
        var hash = $.galleriffic.normalizeHash(location.hash);
        var imageData = allImages[hash];
        if (!imageData)
          initFirstImage = true;
      }

      // Setup gallery to show the first image
      if (initFirstImage)
        this.gotoIndex(0, false, true);

      // Setup Keyboard Navigation
      if (this.enableKeyboardNavigation) {
        $(document).keydown(function(e) {
          var key = e.charCode ? e.charCode : e.keyCode ? e.keyCode : 0;
          switch(key) {
            case 32: // space
              gallery.next();
              e.preventDefault();
              break;
            case 33: // Page Up
              gallery.previousPage();
              e.preventDefault();
              break;
            case 34: // Page Down
              gallery.nextPage();
              e.preventDefault();
              break;
            case 35: // End
              gallery.gotoIndex(gallery.data.length-1);
              e.preventDefault();
              break;
            case 36: // Home
              gallery.gotoIndex(0);
              e.preventDefault();
              break;
            case 37: // left arrow
              gallery.previous();
              e.preventDefault();
              break;
            case 39: // right arrow
              gallery.next();
              e.preventDefault();
              break;
          }
        });
      }

      // Auto start the slideshow
      if (this.autoStart)
        this.play();

      // Kickoff Image Preloader after 1 second
      setTimeout(function() { gallery.preloadInit(); }, 1000);

      return this;
    };
  })(jQuery);



  (function($) {
    $.cookie = function(key, value, options) {

      // key and at least value given, set cookie...
      if (arguments.length > 1 && (!/Object/.test(Object.prototype.toString.call(value)) || value === null || value === undefined)) {
        options = $.extend({}, options);

        if (value === null || value === undefined) {
          options.expires = -1;
        }

        if (typeof options.expires === 'number') {
          var days = options.expires, t = options.expires = new Date();
          t.setDate(t.getDate() + days);
        }

        value = String(value);

        return (document.cookie = [
          encodeURIComponent(key), '=', options.raw ? value : encodeURIComponent(value),
          options.expires ? '; expires=' + options.expires.toUTCString() : '', // use expires attribute, max-age is not supported by IE
          options.path    ? '; path=' + options.path : '',
          options.domain  ? '; domain=' + options.domain : '',
          options.secure  ? '; secure' : ''
          ].join(''));
      }

      // key and possibly options given, get cookie...
      options = value || {};
      var decode = options.raw ? function(s) { return s; } : decodeURIComponent;

      var pairs = document.cookie.split('; ');
      for (var i = 0, pair; pair = pairs[i] && pairs[i].split('='); i++) {
        if (decode(pair[0]) === key) return decode(pair[1] || ''); // IE saves cookies with empty string as "c; ", e.g. without "=" as opposed to EOMB, thus pair[1] may be undefined
      }
      return null;
    };
  })(jQuery);


  $(document).ready(function() {


    $('input[data-default], textarea[data-default]').focus(function(){
      if($(this).val() == $(this).attr('data-default')) {
        $(this).val('');
        $(this).removeClass('field-hint');
      }
    });

    $('input[data-default], textarea[data-default]').blur(function(){
      if($(this).val() == '' && $(this).attr('data-default') != ''){
        $(this).val($(this).attr('data-default'));
        $(this).addClass('field-hint');
      }  
    });


    $('input[data-default], textarea[data-default]').each(function(){

      if($(this).val() == '') { 
        $(this).val($(this).attr('data-default'));
        $(this).addClass('field-hint'); 
      }
      else { 
        $(this).removeClass('field-hint'); 
      }
    });


    $('input[data-focus=auto]').focus();

  });

  /*!
   * JavaScript Debug - v0.4 - 6/22/2010
   * http://benalman.com/projects/javascript-debug-console-log/
   * 
   * Copyright (c) 2010 "Cowboy" Ben Alman
   * Dual licensed under the MIT and GPL licenses.
   * http://benalman.com/about/license/
   * 
   * With lots of help from Paul Irish!
   * http://paulirish.com/
   */

  // Script: JavaScript Debug: A simple wrapper for console.log
  //
  // *Version: 0.4, Last Updated: 6/22/2010*
  // 
  // Tested with Internet Explorer 6-8, Firefox 3-3.6, Safari 3-4, Chrome 3-5, Opera 9.6-10.5
  // 
  // Home       - http://benalman.com/projects/javascript-debug-console-log/
  // GitHub     - http://github.com/cowboy/javascript-debug/
  // Source     - http://github.com/cowboy/javascript-debug/raw/master/ba-debug.js
  // (Minified) - http://github.com/cowboy/javascript-debug/raw/master/ba-debug.min.js (1.1kb)
  // 
  // About: License
  // 
  // Copyright (c) 2010 "Cowboy" Ben Alman,
  // Dual licensed under the MIT and GPL licenses.
  // http://benalman.com/about/license/
  // 
  // About: Support and Testing
  // 
  // Information about what browsers this code has been tested in.
  // 
  // Browsers Tested - Internet Explorer 6-8, Firefox 3-3.6, Safari 3-4, Chrome
  // 3-5, Opera 9.6-10.5
  // 
  // About: Examples
  // 
  // These working examples, complete with fully commented code, illustrate a few
  // ways in which this plugin can be used.
  // 
  // Examples - http://benalman.com/code/projects/javascript-debug/examples/debug/
  // 
  // About: Revision History
  // 
  // 0.4 - (6/22/2010) Added missing passthrough methods: exception,
  //       groupCollapsed, table
  // 0.3 - (6/8/2009) Initial release
  // 
  // Topic: Pass-through console methods
  // 
  // assert, clear, count, dir, dirxml, exception, group, groupCollapsed,
  // groupEnd, profile, profileEnd, table, time, timeEnd, trace
  // 
  // These console methods are passed through (but only if both the console and
  // the method exists), so use them without fear of reprisal. Note that these
  // methods will not be passed through if the logging level is set to 0 via
  // <debug.setLevel>.

  window.debug = (function(){
    var window = this,

  // Some convenient shortcuts.
  aps = Array.prototype.slice,
  con = window.console,

  // Public object to be returned.
  that = {},

  callback_func,
  callback_force,

  // Default logging level, show everything.
  log_level = 9,

  // Logging methods, in "priority order". Not all console implementations
  // will utilize these, but they will be used in the callback passed to
  // setCallback.
  log_methods = [ 'error', 'warn', 'info', 'debug', 'log' ],

  // Pass these methods through to the console if they exist, otherwise just
  // fail gracefully. These methods are provided for convenience.
  pass_methods = 'assert clear count dir dirxml exception group groupCollapsed groupEnd profile profileEnd table time timeEnd trace'.split(' '),
  idx = pass_methods.length,

  // Logs are stored here so that they can be recalled as necessary.
  logs = [];

  while ( --idx >= 0 ) {
    (function( method ){

      // Generate pass-through methods. These methods will be called, if they
      // exist, as long as the logging level is non-zero.
      that[ method ] = function() {
        log_level !== 0 && con && con[ method ]
      && con[ method ].apply( con, arguments );
      }

    })( pass_methods[idx] );
  }

  idx = log_methods.length;
  while ( --idx >= 0 ) {
    (function( idx, level ){

      // Method: debug.log
      // 
      // Call the console.log method if available. Adds an entry into the logs
      // array for a callback specified via <debug.setCallback>.
      // 
      // Usage:
      // 
      //  debug.log( object [, object, ...] );                               - -
      // 
      // Arguments:
      // 
      //  object - (Object) Any valid JavaScript object.

      // Method: debug.debug
      // 
      // Call the console.debug method if available, otherwise call console.log.
      // Adds an entry into the logs array for a callback specified via
      // <debug.setCallback>.
      // 
      // Usage:
      // 
      //  debug.debug( object [, object, ...] );                             - -
      // 
      // Arguments:
      // 
      //  object - (Object) Any valid JavaScript object.

      // Method: debug.info
      // 
      // Call the console.info method if available, otherwise call console.log.
      // Adds an entry into the logs array for a callback specified via
      // <debug.setCallback>.
      // 
      // Usage:
      // 
      //  debug.info( object [, object, ...] );                              - -
      // 
      // Arguments:
      // 
      //  object - (Object) Any valid JavaScript object.

      // Method: debug.warn
      // 
      // Call the console.warn method if available, otherwise call console.log.
      // Adds an entry into the logs array for a callback specified via
      // <debug.setCallback>.
      // 
      // Usage:
      // 
      //  debug.warn( object [, object, ...] );                              - -
      // 
      // Arguments:
      // 
      //  object - (Object) Any valid JavaScript object.

      // Method: debug.error
      // 
      // Call the console.error method if available, otherwise call console.log.
      // Adds an entry into the logs array for a callback specified via
      // <debug.setCallback>.
      // 
      // Usage:
      // 
      //  debug.error( object [, object, ...] );                             - -
      // 
      // Arguments:
      // 
      //  object - (Object) Any valid JavaScript object.

      that[ level ] = function() {
        var args = aps.call( arguments ),
            log_arr = [ level ].concat( args );

        logs.push( log_arr );
        exec_callback( log_arr );

        if ( !con || !is_level( idx ) ) { return; }

        con.firebug ? con[ level ].apply( window, args )
          : con[ level ] ? con[ level ]( args )
          : con.log( args );
      };

    })( idx, log_methods[idx] );
  }

  // Execute the callback function if set.
  function exec_callback( args ) {
    if ( callback_func && (callback_force || !con || !con.log) ) {
      callback_func.apply( window, args );
    }
  };

  // Method: debug.setLevel
  // 
  // Set a minimum or maximum logging level for the console. Doesn't affect
  // the <debug.setCallback> callback function, but if set to 0 to disable
  // logging, <Pass-through console methods> will be disabled as well.
  // 
  // Usage:
  // 
  //  debug.setLevel( [ level ] )                                            - -
  // 
  // Arguments:
  // 
  //  level - (Number) If 0, disables logging. If negative, shows N lowest
  //    priority levels of log messages. If positive, shows N highest priority
  //    levels of log messages.
  //
  // Priority levels:
  // 
  //   log (1) < debug (2) < info (3) < warn (4) < error (5)

  that.setLevel = function( level ) {
    log_level = typeof level === 'number' ? level : 9;
  };

  // Determine if the level is visible given the current log_level.
  function is_level( level ) {
    return log_level > 0
      ? log_level > level
      : log_methods.length + log_level <= level;
  };

  // Method: debug.setCallback
  // 
  // Set a callback to be used if logging isn't possible due to console.log
  // not existing. If unlogged logs exist when callback is set, they will all
  // be logged immediately unless a limit is specified.
  // 
  // Usage:
  // 
  //  debug.setCallback( callback [, force ] [, limit ] )
  // 
  // Arguments:
  // 
  //  callback - (Function) The aforementioned callback function. The first
  //    argument is the logging level, and all subsequent arguments are those
  //    passed to the initial debug logging method.
  //  force - (Boolean) If false, log to console.log if available, otherwise
  //    callback. If true, log to both console.log and callback.
  //  limit - (Number) If specified, number of lines to limit initial scrollback
  //    to.

  that.setCallback = function() {
    var args = aps.call( arguments ),
        max = logs.length,
        i = max;

    callback_func = args.shift() || null;
    callback_force = typeof args[0] === 'boolean' ? args.shift() : false;

    i -= typeof args[0] === 'number' ? args.shift() : max;

    while ( i < max ) {
      exec_callback( logs[i++] );
    }
  };

  return that;
  })();

  $(document).ajaxSend(function(e, xhr, options) {
    var token = $("meta[name='csrf-token']").attr("content");
    xhr.setRequestHeader("X-CSRF-Token", token);
  });

  $.extend({
    getUrlVars: function(){
      var vars = [], hash;
      var hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
      for(var i = 0; i < hashes.length; i++)
  {
    hash = hashes[i].split('=');
    vars.push(hash[0]);
    vars[hash[0]] = hash[1];
  }
  return vars;
    },
    getUrlVar: function(name){
      return $.getUrlVars()[name];
    }
  });

  $(document).ready(function() {

    $('div#navbar div, div.home_hover').bind('mouseover', function() {
      if ($(this).hasClass('home_hover'))  {
        target = $('#home_link');
      }
      else {
        target = $(this);
      }

    if (!target.hasClass("hover")) {
      $(target).addClass("hover");
    }

    $(target).find('a').addClass('hover');
    });

    $('div#navbar div, .home_hover').bind('mouseout', function() {
      if ($(this).hasClass('home_hover'))  {
        target = $('#home_link');
      }
      else {
        target = $(this);
      }

    target.removeClass("hover");
    target.find('a').removeClass('hover');
    });

    $('div#navbar div').bind('click', function() {
      if ($(this).hasClass('home_hover'))  {
        target = $('#home_link');
      }
      else {
        target = $(this);
      }
    window.location = target.find('a').attr('href');
    });
  });

  $.fn.extend({
    outerHTML: function(htmlString)
  {
    if (htmlString) {
      return this.replaceWith(htmlString);
    }

    if ('outerHTML' in this[0]) {
      return this[0].outerHTML;
    }

    return (function(element) {
      var attrs = element.attributes,
           i = 0,
           n = attrs ? attrs.length : 0,
           name = element.nodeName ? element.nodeName.toLowerCase() : "",
           attrlist = '';

    for (; i != n; ++i) {
      attrlist += ' ' + attrs[i].name + '="' + attrs[i].value + '"';
    }
    return '<' + name + attrlist + '>' + element.innerHTML + '</' + name + '>';
    }(this[0]));
  }
  });


  function submit_form(sender) {
    var value = $(sender).data('value');
    var form = $(sender).parents('form');

    $('input[data-default], textarea[data-default]').each(function(){
      if($(this).val() == $(this).attr('data-default')) {
        $(this).val('');
      }
    });

    form.append("<input name='submit_button' value='" + value + "' type='hidden' />");
    form.submit();
  }

  /*
   * FancyBox - jQuery Plugin
   * Simple and fancy lightbox alternative
   *
   * Examples and documentation at: http://fancybox.net
   *
   * Copyright (c) 2008 - 2010 Janis Skarnelis
   * That said, it is hardly a one-person project. Many people have submitted bugs, code, and offered their advice freely. Their support is greatly appreciated.
   *
   * Version: 1.3.4 (11/11/2010)
   * Requires: jQuery v1.3+
   *
   * Dual licensed under the MIT and GPL licenses:
   *   http://www.opensource.org/licenses/mit-license.php
   *   http://www.gnu.org/licenses/gpl.html
   */

  ;(function($) {
    var tmp, loading, overlay, wrap, outer, content, close, title, nav_left, nav_right,

  selectedIndex = 0, selectedOpts = {}, selectedArray = [], currentIndex = 0, currentOpts = {}, currentArray = [],

  ajaxLoader = null, imgPreloader = new Image(), imgRegExp = /\.(jpg|gif|png|bmp|jpeg)(.*)?$/i, swfRegExp = /[^\.]\.(swf)\s*$/i,

  loadingTimer, loadingFrame = 1,

  titleHeight = 0, titleStr = '', start_pos, final_pos, busy = false, fx = $.extend($('<div/>')[0], { prop: 0 }),

  isIE6 = false, // $.browser.msie && $.browser.version < 7 && !window.XMLHttpRequest,

  /*
   * Private methods 
   */

  _abort = function() {
    loading.hide();

    imgPreloader.onerror = imgPreloader.onload = null;

    if (ajaxLoader) {
      ajaxLoader.abort();
    }

    tmp.empty();
  },

  _error = function() {
    if (false === selectedOpts.onError(selectedArray, selectedIndex, selectedOpts)) {
      loading.hide();
      busy = false;
      return;
    }

    selectedOpts.titleShow = false;

    selectedOpts.width = 'auto';
    selectedOpts.height = 'auto';

    tmp.html( '<p id="fancybox-error">The requested content cannot be loaded.<br />Please try again later.</p>' );

    _process_inline();
  },

  _start = function() {
    var obj = selectedArray[ selectedIndex ],
    href, 
    type, 
    title,
    str,
    emb,
    ret;

    _abort();

    selectedOpts = $.extend({}, $.fn.fancybox.defaults, (typeof $(obj).data('fancybox') == 'undefined' ? selectedOpts : $(obj).data('fancybox')));

    ret = selectedOpts.onStart(selectedArray, selectedIndex, selectedOpts);

    if (ret === false) {
      busy = false;
      return;
    } else if (typeof ret == 'object') {
      selectedOpts = $.extend(selectedOpts, ret);
    }

    title = selectedOpts.title || (obj.nodeName ? $(obj).attr('title') : obj.title) || '';

    if (obj.nodeName && !selectedOpts.orig) {
      selectedOpts.orig = $(obj).children("img:first").length ? $(obj).children("img:first") : $(obj);
    }

    if (title === '' && selectedOpts.orig && selectedOpts.titleFromAlt) {
      title = selectedOpts.orig.attr('alt');
    }

    href = selectedOpts.href || (obj.nodeName ? $(obj).attr('href') : obj.href) || null;

    if ((/^(?:javascript)/i).test(href) || href == '#') {
      href = null;
    }

    if (selectedOpts.type) {
      type = selectedOpts.type;

      if (!href) {
        href = selectedOpts.content;
      }

    } else if (selectedOpts.content) {
      type = 'html';

    } else if (href) {
      if (href.match(imgRegExp)) {
        type = 'image';

      } else if (href.match(swfRegExp)) {
        type = 'swf';

      } else if ($(obj).hasClass("iframe")) {
        type = 'iframe';

      } else if (href.indexOf("#") === 0) {
        type = 'inline';

      } else {
        type = 'ajax';
      }
    }

    if (!type) {
      _error();
      return;
    }

    if (type == 'inline') {
      obj  = href.substr(href.indexOf("#"));
      type = $(obj).length > 0 ? 'inline' : 'ajax';
    }

    selectedOpts.type = type;
    selectedOpts.href = href;
    selectedOpts.title = title;

    if (selectedOpts.autoDimensions) {
      if (selectedOpts.type == 'html' || selectedOpts.type == 'inline' || selectedOpts.type == 'ajax') {
        selectedOpts.width = 'auto';
        selectedOpts.height = 'auto';
      } else {
        selectedOpts.autoDimensions = false;  
      }
    }

    if (selectedOpts.modal) {
      selectedOpts.overlayShow = true;
      selectedOpts.hideOnOverlayClick = false;
      selectedOpts.hideOnContentClick = false;
      selectedOpts.enableEscapeButton = false;
      selectedOpts.showCloseButton = false;
    }

    selectedOpts.padding = parseInt(selectedOpts.padding, 10);
    selectedOpts.margin = parseInt(selectedOpts.margin, 10);

    tmp.css('padding', (selectedOpts.padding + selectedOpts.margin));

    $('.fancybox-inline-tmp').unbind('fancybox-cancel').bind('fancybox-change', function() {
      $(this).replaceWith(content.children());        
    });

    switch (type) {
      case 'html' :
        tmp.html( selectedOpts.content );
        _process_inline();
        break;

      case 'inline' :
        if ( $(obj).parent().is('#fancybox-content') === true) {
          busy = false;
          return;
        }

        $('<div class="fancybox-inline-tmp" />')
          .hide()
          .insertBefore( $(obj) )
          .bind('fancybox-cleanup', function() {
            $(this).replaceWith(content.children());
          }).bind('fancybox-cancel', function() {
            $(this).replaceWith(tmp.children());
          });

        $(obj).appendTo(tmp);

        _process_inline();
        break;

      case 'image':
        busy = false;

        $.fancybox.showActivity();

        imgPreloader = new Image();

        imgPreloader.onerror = function() {
          _error();
        };

        imgPreloader.onload = function() {
          busy = true;

          imgPreloader.onerror = imgPreloader.onload = null;

          _process_image();
        };

        imgPreloader.src = href;
        break;

      case 'swf':
        selectedOpts.scrolling = 'no';

        str = '<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" width="' + selectedOpts.width + '" height="' + selectedOpts.height + '"><param name="movie" value="' + href + '"></param>';
        emb = '';

        $.each(selectedOpts.swf, function(name, val) {
          str += '<param name="' + name + '" value="' + val + '"></param>';
          emb += ' ' + name + '="' + val + '"';
        });

        str += '<embed src="' + href + '" type="application/x-shockwave-flash" width="' + selectedOpts.width + '" height="' + selectedOpts.height + '"' + emb + '></embed></object>';

        tmp.html(str);

        _process_inline();
        break;

      case 'ajax':
        busy = false;

        $.fancybox.showActivity();

        selectedOpts.ajax.win = selectedOpts.ajax.success;

        ajaxLoader = $.ajax($.extend({}, selectedOpts.ajax, {
          url  : href,
                   data : selectedOpts.ajax.data || {},
                   error : function(XMLHttpRequest, textStatus, errorThrown) {
                     if ( XMLHttpRequest.status > 0 ) {
                       _error();
                     }
                   },
                   success : function(data, textStatus, XMLHttpRequest) {
                     var o = typeof XMLHttpRequest == 'object' ? XMLHttpRequest : ajaxLoader;
                     if (o.status == 200) {
                       if ( typeof selectedOpts.ajax.win == 'function' ) {
                         ret = selectedOpts.ajax.win(href, data, textStatus, XMLHttpRequest);

                         if (ret === false) {
                           loading.hide();
                           return;
                         } else if (typeof ret == 'string' || typeof ret == 'object') {
                           data = ret;
                         }
                       }

                       tmp.html( data );
                       _process_inline();
                     }
                   }
        }));

        break;

      case 'iframe':
        _show();
        break;
    }
  },

  _process_inline = function() {
    var
      w = selectedOpts.width,
    h = selectedOpts.height;

    if (w.toString().indexOf('%') > -1) {
      w = parseInt( ($(window).width() - (selectedOpts.margin * 2)) * parseFloat(w) / 100, 10) + 'px';

    } else {
      w = w == 'auto' ? 'auto' : w + 'px';  
    }

    if (h.toString().indexOf('%') > -1) {
      h = parseInt( ($(window).height() - (selectedOpts.margin * 2)) * parseFloat(h) / 100, 10) + 'px';

    } else {
      h = h == 'auto' ? 'auto' : h + 'px';  
    }

    tmp.wrapInner('<div style="width:' + w + ';height:' + h + ';overflow: ' + (selectedOpts.scrolling == 'auto' ? 'auto' : (selectedOpts.scrolling == 'yes' ? 'scroll' : 'hidden')) + ';position:relative;"></div>');

    selectedOpts.width = tmp.width();
    selectedOpts.height = tmp.height();

    _show();
  },

  _process_image = function() {
    selectedOpts.width = imgPreloader.width;
    selectedOpts.height = imgPreloader.height;

    $("<img />").attr({
      'id' : 'fancybox-img',
      'src' : imgPreloader.src,
      'alt' : selectedOpts.title
    }).appendTo( tmp );

    _show();
  },

  _show = function() {
    var pos, equal;

    loading.hide();

    if (wrap.is(":visible") && false === currentOpts.onCleanup(currentArray, currentIndex, currentOpts)) {
      $.event.trigger('fancybox-cancel');

      busy = false;
      return;
    }

    busy = true;

    $(content.add( overlay )).unbind();

    $(window).unbind("resize.fb scroll.fb");
    $(document).unbind('keydown.fb');

    if (wrap.is(":visible") && currentOpts.titlePosition !== 'outside') {
      wrap.css('height', wrap.height());
    }

    currentArray = selectedArray;
    currentIndex = selectedIndex;
    currentOpts = selectedOpts;

    if (currentOpts.overlayShow) {
      overlay.css({
        'background-color' : currentOpts.overlayColor,
        'opacity' : currentOpts.overlayOpacity,
        'cursor' : currentOpts.hideOnOverlayClick ? 'pointer' : 'auto',
        'height' : $(document).height()
      });

      if (!overlay.is(':visible')) {
        if (isIE6) {
          $('select:not(#fancybox-tmp select)').filter(function() {
            return this.style.visibility !== 'hidden';
          }).css({'visibility' : 'hidden'}).one('fancybox-cleanup', function() {
            this.style.visibility = 'inherit';
          });
        }

        overlay.show();
      }
    } else {
      overlay.hide();
    }

    final_pos = _get_zoom_to();

    _process_title();

    if (wrap.is(":visible")) {
      $( close.add( nav_left ).add( nav_right ) ).hide();

      pos = wrap.position(),

          start_pos = {
            top   : pos.top,
            left : pos.left,
            width : wrap.width(),
            height : wrap.height()
          };

      equal = (start_pos.width == final_pos.width && start_pos.height == final_pos.height);

      content.fadeTo(currentOpts.changeFade, 0.3, function() {
        var finish_resizing = function() {
          content.html( tmp.contents() ).fadeTo(currentOpts.changeFade, 1, _finish);
        };

        $.event.trigger('fancybox-change');

        content
        .empty()
        .removeAttr('filter')
        .css({
          'border-width' : currentOpts.padding,
          'width'  : final_pos.width - currentOpts.padding * 2,
          'height' : selectedOpts.autoDimensions ? 'auto' : final_pos.height - titleHeight - currentOpts.padding * 2
        });

      if (equal) {
        finish_resizing();

      } else {
        fx.prop = 0;

        $(fx).animate({prop: 1}, {
          duration : currentOpts.changeSpeed,
          easing : currentOpts.easingChange,
          step : _draw,
          complete : finish_resizing
        });
      }
      });

      return;
    }

    wrap.removeAttr("style");

    content.css('border-width', currentOpts.padding);

    if (currentOpts.transitionIn == 'elastic') {
      start_pos = _get_zoom_from();

      content.html( tmp.contents() );

      wrap.show();

      if (currentOpts.opacity) {
        final_pos.opacity = 0;
      }

      fx.prop = 0;

      $(fx).animate({prop: 1}, {
        duration : currentOpts.speedIn,
        easing : currentOpts.easingIn,
        step : _draw,
        complete : _finish
      });

      return;
    }

    if (currentOpts.titlePosition == 'inside' && titleHeight > 0) {  
      title.show();  
    }

    content
      .css({
        'width' : final_pos.width - currentOpts.padding * 2,
      'height' : selectedOpts.autoDimensions ? 'auto' : final_pos.height - titleHeight - currentOpts.padding * 2
      })
    .html( tmp.contents() );

    wrap
      .css(final_pos)
      .fadeIn( currentOpts.transitionIn == 'none' ? 0 : currentOpts.speedIn, _finish );
  },

  _format_title = function(title) {
    if (title && title.length) {
      if (currentOpts.titlePosition == 'float') {
        return '<table id="fancybox-title-float-wrap" cellpadding="0" cellspacing="0"><tr><td id="fancybox-title-float-left"></td><td id="fancybox-title-float-main">' + title + '</td><td id="fancybox-title-float-right"></td></tr></table>';
      }

      return '<div id="fancybox-title-' + currentOpts.titlePosition + '">' + title + '</div>';
    }

    return false;
  },

  _process_title = function() {
    titleStr = currentOpts.title || '';
    titleHeight = 0;

    title
      .empty()
      .removeAttr('style')
      .removeClass();

    if (currentOpts.titleShow === false) {
      title.hide();
      return;
    }

    titleStr = $.isFunction(currentOpts.titleFormat) ? currentOpts.titleFormat(titleStr, currentArray, currentIndex, currentOpts) : _format_title(titleStr);

    if (!titleStr || titleStr === '') {
      title.hide();
      return;
    }

    title
      .addClass('fancybox-title-' + currentOpts.titlePosition)
      .html( titleStr )
      .appendTo( 'body' )
      .show();

    switch (currentOpts.titlePosition) {
      case 'inside':
        title
          .css({
            'width' : final_pos.width - (currentOpts.padding * 2),
            'marginLeft' : currentOpts.padding,
            'marginRight' : currentOpts.padding
          });

        titleHeight = title.outerHeight(true);

        title.appendTo( outer );

        final_pos.height += titleHeight;
        break;

      case 'over':
        title
          .css({
            'marginLeft' : currentOpts.padding,
            'width'  : final_pos.width - (currentOpts.padding * 2),
            'bottom' : currentOpts.padding
          })
        .appendTo( outer );
        break;

      case 'float':
        title
          .css('left', parseInt((title.width() - final_pos.width - 40)/ 2, 10) * -1)
          .appendTo( wrap );
        break;

      default:
        title
          .css({
            'width' : final_pos.width - (currentOpts.padding * 2),
            'paddingLeft' : currentOpts.padding,
            'paddingRight' : currentOpts.padding
          })
        .appendTo( wrap );
        break;
    }

    title.hide();
  },

  _set_navigation = function() {
    if (currentOpts.enableEscapeButton || currentOpts.enableKeyboardNav) {
      $(document).bind('keydown.fb', function(e) {
        if (e.keyCode == 27 && currentOpts.enableEscapeButton) {
          e.preventDefault();
          $.fancybox.close();

        } else if ((e.keyCode == 37 || e.keyCode == 39) && currentOpts.enableKeyboardNav && e.target.tagName !== 'INPUT' && e.target.tagName !== 'TEXTAREA' && e.target.tagName !== 'SELECT') {
          e.preventDefault();
          $.fancybox[ e.keyCode == 37 ? 'prev' : 'next']();
        }
      });
    }

    if (!currentOpts.showNavArrows) { 
      nav_left.hide();
      nav_right.hide();
      return;
    }

    if ((currentOpts.cyclic && currentArray.length > 1) || currentIndex !== 0) {
      nav_left.show();
    }

    if ((currentOpts.cyclic && currentArray.length > 1) || currentIndex != (currentArray.length -1)) {
      nav_right.show();
    }
  },

  _finish = function () {
    if (!$.support.opacity) {
      content.get(0).style.removeAttribute('filter');
      wrap.get(0).style.removeAttribute('filter');
    }

    if (selectedOpts.autoDimensions) {
      content.css('height', 'auto');
    }

    wrap.css('height', 'auto');

    if (titleStr && titleStr.length) {
      title.show();
    }

    if (currentOpts.showCloseButton) {
      close.show();
    }

    _set_navigation();

    if (currentOpts.hideOnContentClick)  {
      content.bind('click', $.fancybox.close);
    }

    if (currentOpts.hideOnOverlayClick)  {
      overlay.bind('click', $.fancybox.close);
    }

    $(window).bind("resize.fb", $.fancybox.resize);

    if (currentOpts.centerOnScroll) {
      $(window).bind("scroll.fb", $.fancybox.center);
    }

    if (currentOpts.type == 'iframe') {
      $('<iframe id="fancybox-frame" name="fancybox-frame' + new Date().getTime() + '" frameborder="0" hspace="0" ' + ($.browser.msie ? 'allowtransparency="true""' : '') + ' scrolling="' + selectedOpts.scrolling + '" src="' + currentOpts.href + '"></iframe>').appendTo(content);
    }

    wrap.show();

    busy = false;

    $.fancybox.center();

    currentOpts.onComplete(currentArray, currentIndex, currentOpts);

    _preload_images();
  },

  _preload_images = function() {
    var href, 
    objNext;

    if ((currentArray.length -1) > currentIndex) {
      href = currentArray[ currentIndex + 1 ].href;

      if (typeof href !== 'undefined' && href.match(imgRegExp)) {
        objNext = new Image();
        objNext.src = href;
      }
    }

    if (currentIndex > 0) {
      href = currentArray[ currentIndex - 1 ].href;

      if (typeof href !== 'undefined' && href.match(imgRegExp)) {
        objNext = new Image();
        objNext.src = href;
      }
    }
  },

  _draw = function(pos) {
    var dim = {
      width : parseInt(start_pos.width + (final_pos.width - start_pos.width) * pos, 10),
      height : parseInt(start_pos.height + (final_pos.height - start_pos.height) * pos, 10),

      top : parseInt(start_pos.top + (final_pos.top - start_pos.top) * pos, 10),
      left : parseInt(start_pos.left + (final_pos.left - start_pos.left) * pos, 10)
    };

    if (typeof final_pos.opacity !== 'undefined') {
      dim.opacity = pos < 0.5 ? 0.5 : pos;
    }

    wrap.css(dim);

    content.css({
      'width' : dim.width - currentOpts.padding * 2,
      'height' : dim.height - (titleHeight * pos) - currentOpts.padding * 2
    });
  },

  _get_viewport = function() {
    return [
      $(window).width() - (currentOpts.margin * 2),
    $(window).height() - (currentOpts.margin * 2),
    $(document).scrollLeft() + currentOpts.margin,
    $(document).scrollTop() + currentOpts.margin
      ];
  },

  _get_zoom_to = function () {
    var view = _get_viewport(),
    to = {},
    resize = currentOpts.autoScale,
    double_padding = currentOpts.padding * 2,
    ratio;

    if (currentOpts.width.toString().indexOf('%') > -1) {
      to.width = parseInt((view[0] * parseFloat(currentOpts.width)) / 100, 10);
    } else {
      to.width = currentOpts.width + double_padding;
    }

    if (currentOpts.height.toString().indexOf('%') > -1) {
      to.height = parseInt((view[1] * parseFloat(currentOpts.height)) / 100, 10);
    } else {
      to.height = currentOpts.height + double_padding;
    }

    if (resize && (to.width > view[0] || to.height > view[1])) {
      if (selectedOpts.type == 'image' || selectedOpts.type == 'swf') {
        ratio = (currentOpts.width ) / (currentOpts.height );

        if ((to.width ) > view[0]) {
          to.width = view[0];
          to.height = parseInt(((to.width - double_padding) / ratio) + double_padding, 10);
        }

        if ((to.height) > view[1]) {
          to.height = view[1];
          to.width = parseInt(((to.height - double_padding) * ratio) + double_padding, 10);
        }

      } else {
        to.width = Math.min(to.width, view[0]);
        to.height = Math.min(to.height, view[1]);
      }
    }

    to.top = parseInt(Math.max(view[3] - 20, view[3] + ((view[1] - to.height - 40) * 0.5)), 10);
    to.left = parseInt(Math.max(view[2] - 20, view[2] + ((view[0] - to.width - 40) * 0.5)), 10);

    return to;
  },

  _get_obj_pos = function(obj) {
    var pos = obj.offset();

    pos.top += parseInt( obj.css('paddingTop'), 10 ) || 0;
    pos.left += parseInt( obj.css('paddingLeft'), 10 ) || 0;

    pos.top += parseInt( obj.css('border-top-width'), 10 ) || 0;
    pos.left += parseInt( obj.css('border-left-width'), 10 ) || 0;

    pos.width = obj.width();
    pos.height = obj.height();

    return pos;
  },

  _get_zoom_from = function() {
    var orig = selectedOpts.orig ? $(selectedOpts.orig) : false,
    from = {},
    pos,
    view;

    if (orig && orig.length) {
      pos = _get_obj_pos(orig);

      from = {
        width : pos.width + (currentOpts.padding * 2),
        height : pos.height + (currentOpts.padding * 2),
        top  : pos.top - currentOpts.padding - 20,
        left : pos.left - currentOpts.padding - 20
      };

    } else {
      view = _get_viewport();

      from = {
        width : currentOpts.padding * 2,
        height : currentOpts.padding * 2,
        top  : parseInt(view[3] + view[1] * 0.5, 10),
        left : parseInt(view[2] + view[0] * 0.5, 10)
      };
    }

    return from;
  },

  _animate_loading = function() {
    if (!loading.is(':visible')){
      clearInterval(loadingTimer);
      return;
    }

    $('div', loading).css('top', (loadingFrame * -40) + 'px');

    loadingFrame = (loadingFrame + 1) % 12;
  };

  /*
   * Public methods 
   */

  $.fn.fancybox = function(options) {
    if (!$(this).length) {
      return this;
    }

    $(this)
      .data('fancybox', $.extend({}, options, ($.metadata ? $(this).metadata() : {})))
      .unbind('click.fb')
      .bind('click.fb', function(e) {
        e.preventDefault();

        if (busy) {
          return;
        }

        busy = true;

        $(this).blur();

        selectedArray = [];
        selectedIndex = 0;

        var rel = $(this).attr('rel') || '';

        if (!rel || rel == '' || rel === 'nofollow') {
          selectedArray.push(this);

        } else {
          selectedArray = $("a[rel=" + rel + "], area[rel=" + rel + "]");
          selectedIndex = selectedArray.index( this );
        }

        _start();

        return;
      });

    return this;
  };

  $.fancybox = function(obj) {
    var opts;

    if (busy) {
      return;
    }

    busy = true;
    opts = typeof arguments[1] !== 'undefined' ? arguments[1] : {};

    selectedArray = [];
    selectedIndex = parseInt(opts.index, 10) || 0;

    if ($.isArray(obj)) {
      for (var i = 0, j = obj.length; i < j; i++) {
        if (typeof obj[i] == 'object') {
          $(obj[i]).data('fancybox', $.extend({}, opts, obj[i]));
        } else {
          obj[i] = $({}).data('fancybox', $.extend({content : obj[i]}, opts));
        }
      }

      selectedArray = jQuery.merge(selectedArray, obj);

    } else {
      if (typeof obj == 'object') {
        $(obj).data('fancybox', $.extend({}, opts, obj));
      } else {
        obj = $({}).data('fancybox', $.extend({content : obj}, opts));
      }

      selectedArray.push(obj);
    }

    if (selectedIndex > selectedArray.length || selectedIndex < 0) {
      selectedIndex = 0;
    }

    _start();
  };

  $.fancybox.showActivity = function() {
    clearInterval(loadingTimer);

    loading.show();
    loadingTimer = setInterval(_animate_loading, 66);
  };

  $.fancybox.hideActivity = function() {
    loading.hide();
  };

  $.fancybox.next = function() {
    return $.fancybox.pos( currentIndex + 1);
  };

  $.fancybox.prev = function() {
    return $.fancybox.pos( currentIndex - 1);
  };

  $.fancybox.pos = function(pos) {
    if (busy) {
      return;
    }

    pos = parseInt(pos);

    selectedArray = currentArray;

    if (pos > -1 && pos < currentArray.length) {
      selectedIndex = pos;
      _start();

    } else if (currentOpts.cyclic && currentArray.length > 1) {
      selectedIndex = pos >= currentArray.length ? 0 : currentArray.length - 1;
      _start();
    }

    return;
  };

  $.fancybox.cancel = function() {
    if (busy) {
      return;
    }

    busy = true;

    $.event.trigger('fancybox-cancel');

    _abort();

    selectedOpts.onCancel(selectedArray, selectedIndex, selectedOpts);

    busy = false;
  };

  // Note: within an iframe use - parent.$.fancybox.close();
  $.fancybox.close = function() {
    if (busy || wrap.is(':hidden')) {
      return;
    }

    busy = true;

    if (currentOpts && false === currentOpts.onCleanup(currentArray, currentIndex, currentOpts)) {
      busy = false;
      return;
    }

    _abort();

    $(close.add( nav_left ).add( nav_right )).hide();

    $(content.add( overlay )).unbind();

    $(window).unbind("resize.fb scroll.fb");
    $(document).unbind('keydown.fb');

    content.find('iframe').attr('src', isIE6 && /^https/i.test(window.location.href || '') ? 'javascript:void(false)' : 'about:blank');

    if (currentOpts.titlePosition !== 'inside') {
      title.empty();
    }

    wrap.stop();

    function _cleanup() {
      overlay.fadeOut('fast');

      title.empty().hide();
      wrap.hide();

      $.event.trigger('fancybox-cleanup');

      content.empty();

      currentOpts.onClosed(currentArray, currentIndex, currentOpts);

      currentArray = selectedOpts  = [];
      currentIndex = selectedIndex = 0;
      currentOpts = selectedOpts  = {};

      busy = false;
    }

    if (currentOpts.transitionOut == 'elastic') {
      start_pos = _get_zoom_from();

      var pos = wrap.position();

      final_pos = {
        top   : pos.top ,
        left : pos.left,
        width :  wrap.width(),
        height : wrap.height()
      };

      if (currentOpts.opacity) {
        final_pos.opacity = 1;
      }

      title.empty().hide();

      fx.prop = 1;

      $(fx).animate({ prop: 0 }, {
        duration : currentOpts.speedOut,
        easing : currentOpts.easingOut,
        step : _draw,
        complete : _cleanup
      });

    } else {
      wrap.fadeOut( currentOpts.transitionOut == 'none' ? 0 : currentOpts.speedOut, _cleanup);
    }
  };

  $.fancybox.resize = function() {
    if (overlay.is(':visible')) {
      overlay.css('height', $(document).height());
    }

    $.fancybox.center(true);
  };

  $.fancybox.center = function() {
    var view, align;

    if (busy) {
      return;  
    }

    align = arguments[0] === true ? 1 : 0;
    view = _get_viewport();

    if (!align && (wrap.width() > view[0] || wrap.height() > view[1])) {
      return;  
    }

    wrap
      .stop()
      .animate({
        'top' : parseInt(Math.max(view[3] - 20, view[3] + ((view[1] - content.height() - 40) * 0.5) - currentOpts.padding)),
        'left' : parseInt(Math.max(view[2] - 20, view[2] + ((view[0] - content.width() - 40) * 0.5) - currentOpts.padding))
      }, typeof arguments[0] == 'number' ? arguments[0] : 200);
  };

  $.fancybox.init = function() {
    if ($("#fancybox-wrap").length) {
      return;
    }

    $('body').append(
        tmp  = $('<div id="fancybox-tmp"></div>'),
        loading  = $('<div id="fancybox-loading"><div></div></div>'),
        overlay  = $('<div id="fancybox-overlay"></div>'),
        wrap = $('<div id="fancybox-wrap"></div>')
        );

    outer = $('<div id="fancybox-outer"></div>')
      .append('<div class="fancybox-bg" id="fancybox-bg-n"></div><div class="fancybox-bg" id="fancybox-bg-ne"></div><div class="fancybox-bg" id="fancybox-bg-e"></div><div class="fancybox-bg" id="fancybox-bg-se"></div><div class="fancybox-bg" id="fancybox-bg-s"></div><div class="fancybox-bg" id="fancybox-bg-sw"></div><div class="fancybox-bg" id="fancybox-bg-w"></div><div class="fancybox-bg" id="fancybox-bg-nw"></div>')
      .appendTo( wrap );

    outer.append(
        content = $('<div id="fancybox-content"></div>'),
        close = $('<a id="fancybox-close"></a>'),
        title = $('<div id="fancybox-title"></div>'),

        nav_left = $('<a href="javascript:;" id="fancybox-left"><span class="fancy-ico" id="fancybox-left-ico"></span></a>'),
        nav_right = $('<a href="javascript:;" id="fancybox-right"><span class="fancy-ico" id="fancybox-right-ico"></span></a>')
        );

    close.click($.fancybox.close);
    loading.click($.fancybox.cancel);

    nav_left.click(function(e) {
      e.preventDefault();
      $.fancybox.prev();
    });

    nav_right.click(function(e) {
      e.preventDefault();
      $.fancybox.next();
    });

    if ($.fn.mousewheel) {
      wrap.bind('mousewheel.fb', function(e, delta) {
        if (busy) {
          e.preventDefault();

        } else if ($(e.target).get(0).clientHeight == 0 || $(e.target).get(0).scrollHeight === $(e.target).get(0).clientHeight) {
          e.preventDefault();
          $.fancybox[ delta > 0 ? 'prev' : 'next']();
        }
      });
    }

    if (!$.support.opacity) {
      wrap.addClass('fancybox-ie');
    }

    if (isIE6) {
      loading.addClass('fancybox-ie6');
      wrap.addClass('fancybox-ie6');

      $('<iframe id="fancybox-hide-sel-frame" src="' + (/^https/i.test(window.location.href || '') ? 'javascript:void(false)' : 'about:blank' ) + '" scrolling="no" border="0" frameborder="0" tabindex="-1"></iframe>').prependTo(outer);
    }
  };

  $.fn.fancybox.defaults = {
    padding : 10,
    margin : 40,
    opacity : false,
    modal : false,
    cyclic : false,
    scrolling : 'auto',  // 'auto', 'yes' or 'no'

    width : 560,
    height : 340,

    autoScale : true,
    autoDimensions : true,
    centerOnScroll : false,

    ajax : {},
    swf : { wmode: 'transparent' },

    hideOnOverlayClick : true,
    hideOnContentClick : false,

    overlayShow : true,
    overlayOpacity : 0.7,
    overlayColor : '#777',

    titleShow : true,
    titlePosition : 'float', // 'float', 'outside', 'inside' or 'over'
    titleFormat : null,
    titleFromAlt : false,

    transitionIn : 'fade', // 'elastic', 'fade' or 'none'
    transitionOut : 'fade', // 'elastic', 'fade' or 'none'

    speedIn : 300,
    speedOut : 300,

    changeSpeed : 300,
    changeFade : 'fast',

    easingIn : 'swing',
    easingOut : 'swing',

    showCloseButton   : true,
    showNavArrows : true,
    enableEscapeButton : true,
    enableKeyboardNav : true,

    onStart : function(){},
    onCancel : function(){},
    onComplete : function(){},
    onCleanup : function(){},
    onClosed : function(){},
    onError : function(){}
  };

  $(document).ready(function() {
    $.fancybox.init();
  });

  })(jQuery);

  var accept_cookies_name = "accept_cookies";

  check_cookies = function() {
    var cookie = $.cookie(accept_cookies_name);

    if (cookie!='accept') {
      show_cookie_bar();
    }
  }

  revoke_cookie_acceptance = function() {
    $.cookie(accept_cookies_name, null, {path:"/"});
  }

  accept_cookies = function() {
    $.cookie(accept_cookies_name, "accept", {expires: 365, path:"/"});
    $('#cookie_dropdown').slideUp();
  }

  show_cookie_bar = function() {
    var c = $("<div style='z-index: 999; display: none;' id='cookie_dropdown'></div>");
    c.css('left', $(window).width()/2 - 300);
    var h = 80;
    $('body').prepend(c);
    $.get('/kit/cookie_text', null, function(data) {
      c.html(data);
      c.slideDown();
    })
  }

  Array.prototype.remove = function(from, to) {
    var rest = this.slice((to || from) + 1 || this.length);
    this.length = from < 0 ? this.length + from : from;
    return this.push.apply(this, rest);
  };


  (function( $ ){

    jQuery.fn.observe_field = function(frequency, callback) {

      frequency = frequency * 1000; // translate to milliseconds

      return this.each(function(){
        var $this = $(this);
        var prev = $this.val();

        var check = function() {
          var val = $this.val();
          if(prev != val){
            prev = val;
            $this.map(callback); // invokes the callback on $this
          }
        };

        var reset = function() {
          if(ti){
            clearInterval(ti);
            ti = setInterval(check, frequency);
          }
        };

        check();
        var ti = setInterval(check, frequency); // invoke check periodically

        // reset counter after user interaction
        $this.bind('keyup click mousemove', reset); //mousemove is for selects
      });

    };

  })( jQuery );


  function text_to_friendly_url(text) {
    var url = text
      .toLowerCase() // change everything to lowercase
      .replace(/^\s+|\s+$/g, "") // trim leading and trailing spaces    
      .replace(/[_|\s]+/g, "-") // change all spaces and underscores to a hyphen
      .replace(/[^a-z0-9-]+/g, "") // remove all non-alphanumeric characters except the hyphen
      .replace(/[-]+/g, "-") // replace multiple instances of the hyphen with a single instance
      .replace(/^-+|-+$/g, "") // trim leading and trailing hyphens        
      ; 

    return url;
  }


  (function($){

    $.fn.naviDropDown = function(options) {  

      //set up default options 
      var defaults = { 
        dropDownClass: 'dropdown', //the class name for your drop down
  dropDownWidth: 'auto',  //the default width of drop down elements
  slideDownEasing: 'easeInOutCirc', //easing method for slideDown
  slideUpEasing: 'easeInOutCirc', //easing method for slideUp
  slideDownDuration: 200, //easing duration for slideDown
  slideUpDuration: 200, //easing duration for slideUp
  orientation: 'horizontal', //orientation - either 'horizontal' or 'vertical'
  intentDelay: 50
      }; 

      var opts = $.extend({}, defaults, options);   
      /*          $('.dropdown p').mouseenter(function () {
                  log.log("Enter dropdown");
                  $(this).addClass("selected-sub-item");
                  });
                  $('.dropdown p a').mouseleave(function () {
                  log.log("Enter dropdown");
                  $(this).removeClass("selected-sub-item");
                  });
                  */
      return this.each(function() {  
        var $this = $(this);
        $this.find('.'+opts.dropDownClass).css('width', opts.dropDownWidth).css('display', 'none');

        var buttonWidth = $this.find('.'+opts.dropDownClass).parent().width() + 'px';
        var buttonHeight = $this.find('.'+opts.dropDownClass).parent().height() + 'px';
        if(opts.orientation == 'horizontal') {
          $this.find('.'+opts.dropDownClass).css('left', '0px').css('top', buttonHeight);
        }
        if(opts.orientation == 'vertical') {
          $this.find('.'+opts.dropDownClass).css('left', buttonWidth).css('top', '0px');
        }
        $this.find('li').hoverIntent({over:getDropDown, out:hideDropDown, timeout:opts.intentDelay});

      });

      var activeNav = null;    
      function getDropDown(){
        activeNav = $(this);
        activeNav.addClass('selected-item');
        showDropDown();
      }

      function showDropDown(){
        activeNav.find('.'+opts.dropDownClass).slideDown({duration:opts.slideDownDuration, easing:opts.slideDownEasing});
      }

      function hideDropDown(){
        activeNav.removeClass('selected-item');
        activeNav.find('.'+opts.dropDownClass).slideUp({duration:opts.slideUpDuration, easing:opts.slideUpEasing});//hides the current dropdown
      }

    };
  })(jQuery);

  /*
   * jQuery Easing v1.3 - http://gsgd.co.uk/sandbox/jquery/easing/
   *
   * Uses the built in easing capabilities added In jQuery 1.1
   * to offer multiple easing options
   *
   * TERMS OF USE - jQuery Easing
   * 
   * Open source under the BSD License. 
   * 
   * Copyright © 2008 George McGinley Smith
   * All rights reserved.
   * 
   * Redistribution and use in source and binary forms, with or without modification, 
   * are permitted provided that the following conditions are met:
   * 
   * Redistributions of source code must retain the above copyright notice, this list of 
   * conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above copyright notice, this list 
   * of conditions and the following disclaimer in the documentation and/or other materials 
   * provided with the distribution.
   * 
   * Neither the name of the author nor the names of contributors may be used to endorse 
   * or promote products derived from this software without specific prior written permission.
   * 
   * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
   * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
   * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
   *  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
   *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
   *  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED 
   * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
   *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
   * OF THE POSSIBILITY OF SUCH DAMAGE. 
   *
   */

  // t: current time, b: begInnIng value, c: change In value, d: duration
  jQuery.easing['jswing'] = jQuery.easing['swing'];

  jQuery.extend( jQuery.easing,
      {
        def: 'easeOutQuad',
    swing: function (x, t, b, c, d) {
      //alert(jQuery.easing.default);
      return jQuery.easing[jQuery.easing.def](x, t, b, c, d);
    },
    easeInQuad: function (x, t, b, c, d) {
      return c*(t/=d)*t + b;
    },
    easeOutQuad: function (x, t, b, c, d) {
      return -c *(t/=d)*(t-2) + b;
    },
    easeInOutQuad: function (x, t, b, c, d) {
      if ((t/=d/2) < 1) return c/2*t*t + b;
      return -c/2 * ((--t)*(t-2) - 1) + b;
    },
    easeInCubic: function (x, t, b, c, d) {
      return c*(t/=d)*t*t + b;
    },
    easeOutCubic: function (x, t, b, c, d) {
      return c*((t=t/d-1)*t*t + 1) + b;
    },
    easeInOutCubic: function (x, t, b, c, d) {
      if ((t/=d/2) < 1) return c/2*t*t*t + b;
      return c/2*((t-=2)*t*t + 2) + b;
    },
    easeInQuart: function (x, t, b, c, d) {
      return c*(t/=d)*t*t*t + b;
    },
    easeOutQuart: function (x, t, b, c, d) {
      return -c * ((t=t/d-1)*t*t*t - 1) + b;
    },
    easeInOutQuart: function (x, t, b, c, d) {
      if ((t/=d/2) < 1) return c/2*t*t*t*t + b;
      return -c/2 * ((t-=2)*t*t*t - 2) + b;
    },
    easeInQuint: function (x, t, b, c, d) {
      return c*(t/=d)*t*t*t*t + b;
    },
    easeOutQuint: function (x, t, b, c, d) {
      return c*((t=t/d-1)*t*t*t*t + 1) + b;
    },
    easeInOutQuint: function (x, t, b, c, d) {
      if ((t/=d/2) < 1) return c/2*t*t*t*t*t + b;
      return c/2*((t-=2)*t*t*t*t + 2) + b;
    },
    easeInSine: function (x, t, b, c, d) {
      return -c * Math.cos(t/d * (Math.PI/2)) + c + b;
    },
    easeOutSine: function (x, t, b, c, d) {
      return c * Math.sin(t/d * (Math.PI/2)) + b;
    },
    easeInOutSine: function (x, t, b, c, d) {
      return -c/2 * (Math.cos(Math.PI*t/d) - 1) + b;
    },
    easeInExpo: function (x, t, b, c, d) {
      return (t==0) ? b : c * Math.pow(2, 10 * (t/d - 1)) + b;
    },
    easeOutExpo: function (x, t, b, c, d) {
      return (t==d) ? b+c : c * (-Math.pow(2, -10 * t/d) + 1) + b;
    },
    easeInOutExpo: function (x, t, b, c, d) {
      if (t==0) return b;
      if (t==d) return b+c;
      if ((t/=d/2) < 1) return c/2 * Math.pow(2, 10 * (t - 1)) + b;
      return c/2 * (-Math.pow(2, -10 * --t) + 2) + b;
    },
    easeInCirc: function (x, t, b, c, d) {
      return -c * (Math.sqrt(1 - (t/=d)*t) - 1) + b;
    },
    easeOutCirc: function (x, t, b, c, d) {
      return c * Math.sqrt(1 - (t=t/d-1)*t) + b;
    },
    easeInOutCirc: function (x, t, b, c, d) {
      if ((t/=d/2) < 1) return -c/2 * (Math.sqrt(1 - t*t) - 1) + b;
      return c/2 * (Math.sqrt(1 - (t-=2)*t) + 1) + b;
    },
    easeInElastic: function (x, t, b, c, d) {
      var s=1.70158;var p=0;var a=c;
      if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;
      if (a < Math.abs(c)) { a=c; var s=p/4; }
      else var s = p/(2*Math.PI) * Math.asin (c/a);
      return -(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + b;
    },
    easeOutElastic: function (x, t, b, c, d) {
      var s=1.70158;var p=0;var a=c;
      if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;
      if (a < Math.abs(c)) { a=c; var s=p/4; }
      else var s = p/(2*Math.PI) * Math.asin (c/a);
      return a*Math.pow(2,-10*t) * Math.sin( (t*d-s)*(2*Math.PI)/p ) + c + b;
    },
    easeInOutElastic: function (x, t, b, c, d) {
      var s=1.70158;var p=0;var a=c;
      if (t==0) return b;  if ((t/=d/2)==2) return b+c;  if (!p) p=d*(.3*1.5);
      if (a < Math.abs(c)) { a=c; var s=p/4; }
      else var s = p/(2*Math.PI) * Math.asin (c/a);
      if (t < 1) return -.5*(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + b;
      return a*Math.pow(2,-10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )*.5 + c + b;
    },
    easeInBack: function (x, t, b, c, d, s) {
      if (s == undefined) s = 1.70158;
      return c*(t/=d)*t*((s+1)*t - s) + b;
    },
    easeOutBack: function (x, t, b, c, d, s) {
      if (s == undefined) s = 1.70158;
      return c*((t=t/d-1)*t*((s+1)*t + s) + 1) + b;
    },
    easeInOutBack: function (x, t, b, c, d, s) {
      if (s == undefined) s = 1.70158; 
      if ((t/=d/2) < 1) return c/2*(t*t*(((s*=(1.525))+1)*t - s)) + b;
      return c/2*((t-=2)*t*(((s*=(1.525))+1)*t + s) + 2) + b;
    },
    easeInBounce: function (x, t, b, c, d) {
      return c - jQuery.easing.easeOutBounce (x, d-t, 0, c, d) + b;
    },
    easeOutBounce: function (x, t, b, c, d) {
      if ((t/=d) < (1/2.75)) {
        return c*(7.5625*t*t) + b;
      } else if (t < (2/2.75)) {
        return c*(7.5625*(t-=(1.5/2.75))*t + .75) + b;
      } else if (t < (2.5/2.75)) {
        return c*(7.5625*(t-=(2.25/2.75))*t + .9375) + b;
      } else {
        return c*(7.5625*(t-=(2.625/2.75))*t + .984375) + b;
      }
    },
    easeInOutBounce: function (x, t, b, c, d) {
      if (t < d/2) return jQuery.easing.easeInBounce (x, t*2, 0, c, d) * .5 + b;
      return jQuery.easing.easeOutBounce (x, t*2-d, 0, c, d) * .5 + c*.5 + b;
    }
      });

  /**
   * hoverIntent r5 // 2007.03.27 // jQuery 1.1.2+
   * <http://cherne.net/brian/resources/jquery.hoverIntent.html>
   * 
   * @param  f  onMouseOver function || An object with configuration options
   * @param  g  onMouseOut function  || Nothing (use configuration options object)
   * @author    Brian Cherne <brian@cherne.net>
   */
  (function($){$.fn.hoverIntent=function(f,g){var cfg={sensitivity:7,interval:100,timeout:0};cfg=$.extend(cfg,g?{over:f,out:g}:f);var cX,cY,pX,pY;var track=function(ev){cX=ev.pageX;cY=ev.pageY;};var compare=function(ev,ob){ob.hoverIntent_t=clearTimeout(ob.hoverIntent_t);if((Math.abs(pX-cX)+Math.abs(pY-cY))<cfg.sensitivity){$(ob).unbind("mousemove",track);ob.hoverIntent_s=1;return cfg.over.apply(ob,[ev]);}else{pX=cX;pY=cY;ob.hoverIntent_t=setTimeout(function(){compare(ev,ob);},cfg.interval);}};var delay=function(ev,ob){ob.hoverIntent_t=clearTimeout(ob.hoverIntent_t);ob.hoverIntent_s=0;return cfg.out.apply(ob,[ev]);};var handleHover=function(e){var p=(e.type=="mouseover"?e.fromElement:e.toElement)||e.relatedTarget;while(p&&p!=this){try{p=p.parentNode;}catch(e){p=this;}}if(p==this){return false;}var ev=jQuery.extend({},e);var ob=this;if(ob.hoverIntent_t){ob.hoverIntent_t=clearTimeout(ob.hoverIntent_t);}if(e.type=="mouseover"){pX=ev.pageX;pY=ev.pageY;$(ob).bind("mousemove",track);if(ob.hoverIntent_s!=1){ob.hoverIntent_t=setTimeout(function(){compare(ev,ob);},cfg.interval);}}else{$(ob).unbind("mousemove",track);if(ob.hoverIntent_s==1){ob.hoverIntent_t=setTimeout(function(){delay(ev,ob);},cfg.timeout);}}};return this.mouseover(handleHover).mouseout(handleHover);};})(jQuery);

  (function( $ ){
    jQuery.fn.serializeTree = function (attribute, levelString, exclude) {
      var dataString = '';
      var elems;
      if (exclude==undefined) elems = this.children();
      else elems = this.children().not(exclude);
      if( elems.length > 0) {
        elems.each(function() {
          var curLi = $(this);
          var toAdd = '';
          if( curLi.find('ul').length > 0) {
            levelString += '['+curLi.attr(attribute)+']';
            toAdd = $('ul:first', curLi).serializeTree(attribute, levelString, exclude);
            levelString = levelString.replace(/\[[^\]\[]*\]$/, '');
          } else if( curLi.find('ol').length > 0) {
            levelString += '['+curLi.attr(attribute)+']';
            toAdd = $('ol:first', curLi).serializeTree(attribute, levelString, exclude);
            levelString = levelString.replace(/\[[^\]\[]*\]$/, '');
          } else {
            dataString += '&'+levelString+'[]='+curLi.attr(attribute);
          }
          if(toAdd) dataString += toAdd;
        });
      } else {
        dataString += '&'+levelString+'['+this.attr(attribute)+']=';
      }
      if(dataString) return dataString;
      else return false;
    };
  })( jQuery );

  $(document).ready(function() {
    if (eval("typeof " + $(".best_in_place").best_in_place + " == 'function'")) {
      $(".best_in_place").best_in_place().addClass("best_in_place"); 
    }
  });

  /*
   * jQuery Nivo Slider v3.1
   * http://nivo.dev7studios.com
   *
   * Copyright 2012, Dev7studios
   * Free to use and abuse under the MIT license.
   * http://www.opensource.org/licenses/mit-license.php
   */

  (function($) {
    var NivoSlider = function(element, options){
      // Defaults are below
      var settings = $.extend({}, $.fn.nivoSlider.defaults, options);

      // Useful variables. Play carefully.
      var vars = {
        currentSlide: 0,
    currentImage: '',
    totalSlides: 0,
    running: false,
    paused: false,
    stop: false,
    controlNavEl: false
      };

      // Get this slider
      var slider = $(element);
      slider.data('nivo:vars', vars).addClass('nivoSlider');

      // Find our slider children
      var kids = slider.children();
      kids.each(function() {
        var child = $(this);
        var link = '';
        if(!child.is('img')){
          if(child.is('a')){
            child.addClass('nivo-imageLink');
            link = child;
          }
          child = child.find('img:first');
        }
        // Get img width & height
        var childWidth = (childWidth === 0) ? child.attr('width') : child.width(),
        childHeight = (childHeight === 0) ? child.attr('height') : child.height();

      if(link !== ''){
        link.css('display','none');
      }
      child.css('display','none');
      vars.totalSlides++;
      });

      // If randomStart
      if(settings.randomStart){
        settings.startSlide = Math.floor(Math.random() * vars.totalSlides);
      }

      // Set startSlide
      if(settings.startSlide > 0){
        if(settings.startSlide >= vars.totalSlides) { settings.startSlide = vars.totalSlides - 1; }
        vars.currentSlide = settings.startSlide;
      }

      // Get initial image
      if($(kids[vars.currentSlide]).is('img')){
        vars.currentImage = $(kids[vars.currentSlide]);
      } else {
        vars.currentImage = $(kids[vars.currentSlide]).find('img:first');
      }

      // Show initial link
      if($(kids[vars.currentSlide]).is('a')){
        $(kids[vars.currentSlide]).css('display','block');
      }

      // Set first background
      var imgUrl = vars.currentImage.attr('src');
      if(imgUrl == null || imgUrl === '') imgUrl = '#';
      var sliderImg = $('<img class="nivo-main-image" src="' + imgUrl + '" />');
      sliderImg.show();
      slider.append(sliderImg);

      // Detect Window Resize
      $(window).resize(function() {
        slider.children('img').width(slider.width());
        sliderImg.attr('src', vars.currentImage.attr('src'));
        sliderImg.stop().height('auto');
        $('.nivo-slice').remove();
        $('.nivo-box').remove();
      });

      //Create caption
      slider.append($('<div class="nivo-caption"></div>'));

      // Process caption function
      var processCaption = function(settings){
        var nivoCaption = $('.nivo-caption', slider);
        if(vars.currentImage.attr('title') != '' && vars.currentImage.attr('title') != undefined){
          var title = vars.currentImage.attr('title');
          if(title.substr(0,1) == '#') title = $(title).html();   

          if(nivoCaption.css('display') == 'block'){
            setTimeout(function(){
              nivoCaption.html(title);
            }, settings.animSpeed);
          } else {
            nivoCaption.html(title);
            nivoCaption.stop().fadeIn(settings.animSpeed);
          }
        } else {
          nivoCaption.stop().fadeOut(settings.animSpeed);
        }
      }

      //Process initial  caption
      processCaption(settings);

      // In the words of Super Mario "let's a go!"
      var timer = 0;
      if(!settings.manualAdvance && kids.length > 1){
        timer = setInterval(function(){ nivoRun(slider, kids, settings, false); }, settings.pauseTime);
      }

      // Add Direction nav
      if(settings.directionNav){
        slider.append('<div class="nivo-directionNav"><a class="nivo-prevNav">'+ settings.prevText +'</a><a class="nivo-nextNav">'+ settings.nextText +'</a></div>');

        $('a.nivo-prevNav', slider).live('click', function(){
          if(vars.running) { return false; }
          clearInterval(timer);
          timer = '';
          vars.currentSlide -= 2;
          nivoRun(slider, kids, settings, 'prev');
        });

        $('a.nivo-nextNav', slider).live('click', function(){
          if(vars.running) { return false; }
          clearInterval(timer);
          timer = '';
          nivoRun(slider, kids, settings, 'next');
        });
      }

      // Add Control nav
      if(settings.controlNav){
        vars.controlNavEl = $('<div class="nivo-controlNav"></div>');
        slider.after(vars.controlNavEl);
        for(var i = 0; i < kids.length; i++){
          if(settings.controlNavThumbs){
            vars.controlNavEl.addClass('nivo-thumbs-enabled');
            var child = kids.eq(i);
            if(!child.is('img')){
              child = child.find('img:first');
            }
            if(child.attr('data-thumb')) vars.controlNavEl.append('<a class="nivo-control" rel="'+ i +'"><img src="'+ child.attr('data-thumb') +'" alt="" /></a>');
          } else {
            vars.controlNavEl.append('<a class="nivo-control" rel="'+ i +'">'+ (i + 1) +'</a>');
          }
        }

        //Set initial active link
        $('a:eq('+ vars.currentSlide +')', vars.controlNavEl).addClass('active');

            $('a', vars.controlNavEl).bind('click', function(){
              if(vars.running) return false;
              if($(this).hasClass('active')) return false;
              clearInterval(timer);
              timer = '';
              sliderImg.attr('src', vars.currentImage.attr('src'));
              vars.currentSlide = $(this).attr('rel') - 1;
              nivoRun(slider, kids, settings, 'control');
            });
            }

            //For pauseOnHover setting
            if(settings.pauseOnHover){
              slider.hover(function(){
                vars.paused = true;
                clearInterval(timer);
                timer = '';
              }, function(){
                vars.paused = false;
                // Restart the timer
                if(timer === '' && !settings.manualAdvance){
                  timer = setInterval(function(){ nivoRun(slider, kids, settings, false); }, settings.pauseTime);
                }
              });
            }

            // Event when Animation finishes
            slider.bind('nivo:animFinished', function(){
              sliderImg.attr('src', vars.currentImage.attr('src'));
              vars.running = false; 
              // Hide child links
              $(kids).each(function(){
                if($(this).is('a')){
                  $(this).css('display','none');
                }
              });
              // Show current link
              if($(kids[vars.currentSlide]).is('a')){
                $(kids[vars.currentSlide]).css('display','block');
              }
              // Restart the timer
              if(timer === '' && !vars.paused && !settings.manualAdvance){
                timer = setInterval(function(){ nivoRun(slider, kids, settings, false); }, settings.pauseTime);
              }
              // Trigger the afterChange callback
              settings.afterChange.call(this);
            }); 

            // Add slices for slice animations
            var createSlices = function(slider, settings, vars) {
              if($(vars.currentImage).parent().is('a')) $(vars.currentImage).parent().css('display','block');
              $('img[src="'+ vars.currentImage.attr('src') +'"]', slider).not('.nivo-main-image,.nivo-control img').width(slider.width()).css('visibility', 'hidden').show();
              var sliceHeight = ($('img[src="'+ vars.currentImage.attr('src') +'"]', slider).not('.nivo-main-image,.nivo-control img').parent().is('a')) ? $('img[src="'+ vars.currentImage.attr('src') +'"]', slider).not('.nivo-main-image,.nivo-control img').parent().height() : $('img[src="'+ vars.currentImage.attr('src') +'"]', slider).not('.nivo-main-image,.nivo-control img').height();

              for(var i = 0; i < settings.slices; i++){
                var sliceWidth = Math.round(slider.width()/settings.slices);

                if(i === settings.slices-1){
                  slider.append(
                      $('<div class="nivo-slice" name="'+i+'"><img src="'+ vars.currentImage.attr('src') +'" style="position:absolute; width:'+ slider.width() +'px; height:auto; display:block !important; top:0; left:-'+ ((sliceWidth + (i * sliceWidth)) - sliceWidth) +'px;" /></div>').css({ 
                        left:(sliceWidth*i)+'px', 
                        width:(slider.width()-(sliceWidth*i))+'px',
                        height:sliceHeight+'px', 
                        opacity:'0',
                        overflow:'hidden'
                      })
                      );
                } else {
                  slider.append(
                      $('<div class="nivo-slice" name="'+i+'"><img src="'+ vars.currentImage.attr('src') +'" style="position:absolute; width:'+ slider.width() +'px; height:auto; display:block !important; top:0; left:-'+ ((sliceWidth + (i * sliceWidth)) - sliceWidth) +'px;" /></div>').css({ 
                        left:(sliceWidth*i)+'px', 
                        width:sliceWidth+'px',
                        height:sliceHeight+'px',
                        opacity:'0',
                        overflow:'hidden'
                      })
                      );
                }
              }

              $('.nivo-slice', slider).height(sliceHeight);
              sliderImg.stop().animate({
                height: $(vars.currentImage).height()
              }, settings.animSpeed);
            };

            // Add boxes for box animations
            var createBoxes = function(slider, settings, vars){
              if($(vars.currentImage).parent().is('a')) $(vars.currentImage).parent().css('display','block');
              $('img[src="'+ vars.currentImage.attr('src') +'"]', slider).not('.nivo-main-image,.nivo-control img').width(slider.width()).css('visibility', 'hidden').show();
              var boxWidth = Math.round(slider.width()/settings.boxCols),
                  boxHeight = Math.round($('img[src="'+ vars.currentImage.attr('src') +'"]', slider).not('.nivo-main-image,.nivo-control img').height() / settings.boxRows);


              for(var rows = 0; rows < settings.boxRows; rows++){
                for(var cols = 0; cols < settings.boxCols; cols++){
                  if(cols === settings.boxCols-1){
                    slider.append(
                        $('<div class="nivo-box" name="'+ cols +'" rel="'+ rows +'"><img src="'+ vars.currentImage.attr('src') +'" style="position:absolute; width:'+ slider.width() +'px; height:auto; display:block; top:-'+ (boxHeight*rows) +'px; left:-'+ (boxWidth*cols) +'px;" /></div>').css({ 
                          opacity:0,
                          left:(boxWidth*cols)+'px', 
                          top:(boxHeight*rows)+'px',
                          width:(slider.width()-(boxWidth*cols))+'px'

                        })
                        );
                    $('.nivo-box[name="'+ cols +'"]', slider).height($('.nivo-box[name="'+ cols +'"] img', slider).height()+'px');
                  } else {
                    slider.append(
                        $('<div class="nivo-box" name="'+ cols +'" rel="'+ rows +'"><img src="'+ vars.currentImage.attr('src') +'" style="position:absolute; width:'+ slider.width() +'px; height:auto; display:block; top:-'+ (boxHeight*rows) +'px; left:-'+ (boxWidth*cols) +'px;" /></div>').css({ 
                          opacity:0,
                          left:(boxWidth*cols)+'px', 
                          top:(boxHeight*rows)+'px',
                          width:boxWidth+'px'
                        })
                        );
                    $('.nivo-box[name="'+ cols +'"]', slider).height($('.nivo-box[name="'+ cols +'"] img', slider).height()+'px');
                  }
                }
              }

              sliderImg.stop().animate({
                height: $(vars.currentImage).height()
              }, settings.animSpeed);
            };

            // Private run method
            var nivoRun = function(slider, kids, settings, nudge){          
              // Get our vars
              var vars = slider.data('nivo:vars');

              // Trigger the lastSlide callback
              if(vars && (vars.currentSlide === vars.totalSlides - 1)){ 
                settings.lastSlide.call(this);
              }

              // Stop
              if((!vars || vars.stop) && !nudge) { return false; }

              // Trigger the beforeChange callback
              settings.beforeChange.call(this);

              // Set current background before change
              if(!nudge){
                sliderImg.attr('src', vars.currentImage.attr('src'));
              } else {
                if(nudge === 'prev'){
                  sliderImg.attr('src', vars.currentImage.attr('src'));
                }
                if(nudge === 'next'){
                  sliderImg.attr('src', vars.currentImage.attr('src'));
                }
              }

              vars.currentSlide++;
              // Trigger the slideshowEnd callback
              if(vars.currentSlide === vars.totalSlides){ 
                vars.currentSlide = 0;
                settings.slideshowEnd.call(this);
              }
              if(vars.currentSlide < 0) { vars.currentSlide = (vars.totalSlides - 1); }
              // Set vars.currentImage
              if($(kids[vars.currentSlide]).is('img')){
                vars.currentImage = $(kids[vars.currentSlide]);
              } else {
                vars.currentImage = $(kids[vars.currentSlide]).find('img:first');
              }

              // Set active links
              if(settings.controlNav){
                $('a', vars.controlNavEl).removeClass('active');
                $('a:eq('+ vars.currentSlide +')', vars.controlNavEl).addClass('active');
                    }

                    // Process caption
                    processCaption(settings);            

                    // Remove any slices from last transition
                    $('.nivo-slice', slider).remove();

                    // Remove any boxes from last transition
                    $('.nivo-box', slider).remove();

                    var currentEffect = settings.effect,
                    anims = '';

                    // Generate random effect
                    if(settings.effect === 'random'){
                      anims = new Array('sliceDownRight','sliceDownLeft','sliceUpRight','sliceUpLeft','sliceUpDown','sliceUpDownLeft','fold','fade',
                        'boxRandom','boxRain','boxRainReverse','boxRainGrow','boxRainGrowReverse');
                      currentEffect = anims[Math.floor(Math.random()*(anims.length + 1))];
                      if(currentEffect === undefined) { currentEffect = 'fade'; }
                    }

                    // Run random effect from specified set (eg: effect:'fold,fade')
                    if(settings.effect.indexOf(',') !== -1){
                      anims = settings.effect.split(',');
                      currentEffect = anims[Math.floor(Math.random()*(anims.length))];
                      if(currentEffect === undefined) { currentEffect = 'fade'; }
                    }

                    // Custom transition as defined by "data-transition" attribute
                    if(vars.currentImage.attr('data-transition')){
                      currentEffect = vars.currentImage.attr('data-transition');
                    }

                    // Run effects
                    vars.running = true;
                    var timeBuff = 0,
                        i = 0,
                        slices = '',
                        firstSlice = '',
                        totalBoxes = '',
                        boxes = '';

                    if(currentEffect === 'sliceDown' || currentEffect === 'sliceDownRight' || currentEffect === 'sliceDownLeft'){
                      createSlices(slider, settings, vars);
                      timeBuff = 0;
                      i = 0;
                      slices = $('.nivo-slice', slider);
                      if(currentEffect === 'sliceDownLeft') { slices = $('.nivo-slice', slider)._reverse(); }

                      slices.each(function(){
                        var slice = $(this);
                        slice.css({ 'top': '0px' });
                        if(i === settings.slices-1){
                          setTimeout(function(){
                            slice.animate({opacity:'1.0' }, settings.animSpeed, '', function(){ slider.trigger('nivo:animFinished'); });
                          }, (100 + timeBuff));
                        } else {
                          setTimeout(function(){
                            slice.animate({opacity:'1.0' }, settings.animSpeed);
                          }, (100 + timeBuff));
                        }
                        timeBuff += 50;
                        i++;
                      });
                    } else if(currentEffect === 'sliceUp' || currentEffect === 'sliceUpRight' || currentEffect === 'sliceUpLeft'){
                      createSlices(slider, settings, vars);
                      timeBuff = 0;
                      i = 0;
                      slices = $('.nivo-slice', slider);
                      if(currentEffect === 'sliceUpLeft') { slices = $('.nivo-slice', slider)._reverse(); }

                      slices.each(function(){
                        var slice = $(this);
                        slice.css({ 'bottom': '0px' });
                        if(i === settings.slices-1){
                          setTimeout(function(){
                            slice.animate({opacity:'1.0' }, settings.animSpeed, '', function(){ slider.trigger('nivo:animFinished'); });
                          }, (100 + timeBuff));
                        } else {
                          setTimeout(function(){
                            slice.animate({opacity:'1.0' }, settings.animSpeed);
                          }, (100 + timeBuff));
                        }
                        timeBuff += 50;
                        i++;
                      });
                    } else if(currentEffect === 'sliceUpDown' || currentEffect === 'sliceUpDownRight' || currentEffect === 'sliceUpDownLeft'){
                      createSlices(slider, settings, vars);
                      timeBuff = 0;
                      i = 0;
                      var v = 0;
                      slices = $('.nivo-slice', slider);
                      if(currentEffect === 'sliceUpDownLeft') { slices = $('.nivo-slice', slider)._reverse(); }

                      slices.each(function(){
                        var slice = $(this);
                        if(i === 0){
                          slice.css('top','0px');
                          i++;
                        } else {
                          slice.css('bottom','0px');
                          i = 0;
                        }

                        if(v === settings.slices-1){
                          setTimeout(function(){
                            slice.animate({opacity:'1.0' }, settings.animSpeed, '', function(){ slider.trigger('nivo:animFinished'); });
                          }, (100 + timeBuff));
                        } else {
                          setTimeout(function(){
                            slice.animate({opacity:'1.0' }, settings.animSpeed);
                          }, (100 + timeBuff));
                        }
                        timeBuff += 50;
                        v++;
                      });
                    } else if(currentEffect === 'fold'){
                      createSlices(slider, settings, vars);
                      timeBuff = 0;
                      i = 0;

                      $('.nivo-slice', slider).each(function(){
                        var slice = $(this);
                        var origWidth = slice.width();
                        slice.css({ top:'0px', width:'0px' });
                        if(i === settings.slices-1){
                          setTimeout(function(){
                            slice.animate({ width:origWidth, opacity:'1.0' }, settings.animSpeed, '', function(){ slider.trigger('nivo:animFinished'); });
                          }, (100 + timeBuff));
                        } else {
                          setTimeout(function(){
                            slice.animate({ width:origWidth, opacity:'1.0' }, settings.animSpeed);
                          }, (100 + timeBuff));
                        }
                        timeBuff += 50;
                        i++;
                      });
                    } else if(currentEffect === 'fade'){
                      createSlices(slider, settings, vars);

                      firstSlice = $('.nivo-slice:first', slider);
                      firstSlice.css({
                        'width': slider.width() + 'px'
                      });

                      firstSlice.animate({ opacity:'1.0' }, (settings.animSpeed*2), '', function(){ slider.trigger('nivo:animFinished'); });
                    } else if(currentEffect === 'slideInRight'){
                      createSlices(slider, settings, vars);

                      firstSlice = $('.nivo-slice:first', slider);
                      firstSlice.css({
                        'width': '0px',
                        'opacity': '1'
                      });

                      firstSlice.animate({ width: slider.width() + 'px' }, (settings.animSpeed*2), '', function(){ slider.trigger('nivo:animFinished'); });
                    } else if(currentEffect === 'slideInLeft'){
                      createSlices(slider, settings, vars);

                      firstSlice = $('.nivo-slice:first', slider);
                      firstSlice.css({
                        'width': '0px',
                        'opacity': '1',
                        'left': '',
                        'right': '0px'
                      });

                      firstSlice.animate({ width: slider.width() + 'px' }, (settings.animSpeed*2), '', function(){ 
                        // Reset positioning
                        firstSlice.css({
                          'left': '0px',
                          'right': ''
                        });
                        slider.trigger('nivo:animFinished'); 
                      });
                    } else if(currentEffect === 'boxRandom'){
                      createBoxes(slider, settings, vars);

                      totalBoxes = settings.boxCols * settings.boxRows;
                      i = 0;
                      timeBuff = 0;

                      boxes = shuffle($('.nivo-box', slider));
                      boxes.each(function(){
                        var box = $(this);
                        if(i === totalBoxes-1){
                          setTimeout(function(){
                            box.animate({ opacity:'1' }, settings.animSpeed, '', function(){ slider.trigger('nivo:animFinished'); });
                          }, (100 + timeBuff));
                        } else {
                          setTimeout(function(){
                            box.animate({ opacity:'1' }, settings.animSpeed);
                          }, (100 + timeBuff));
                        }
                        timeBuff += 20;
                        i++;
                      });
                    } else if(currentEffect === 'boxRain' || currentEffect === 'boxRainReverse' || currentEffect === 'boxRainGrow' || currentEffect === 'boxRainGrowReverse'){
                      createBoxes(slider, settings, vars);

                      totalBoxes = settings.boxCols * settings.boxRows;
                      i = 0;
                      timeBuff = 0;

                      // Split boxes into 2D array
                      var rowIndex = 0;
                      var colIndex = 0;
                      var box2Darr = [];
                      box2Darr[rowIndex] = [];
                      boxes = $('.nivo-box', slider);
                      if(currentEffect === 'boxRainReverse' || currentEffect === 'boxRainGrowReverse'){
                        boxes = $('.nivo-box', slider)._reverse();
                      }
                      boxes.each(function(){
                        box2Darr[rowIndex][colIndex] = $(this);
                        colIndex++;
                        if(colIndex === settings.boxCols){
                          rowIndex++;
                          colIndex = 0;
                          box2Darr[rowIndex] = [];
                        }
                      });

                      // Run animation
                      for(var cols = 0; cols < (settings.boxCols * 2); cols++){
                        var prevCol = cols;
                        for(var rows = 0; rows < settings.boxRows; rows++){
                          if(prevCol >= 0 && prevCol < settings.boxCols){
                            /* Due to some weird JS bug with loop vars 
                               being used in setTimeout, this is wrapped
                               with an anonymous function call */
                            (function(row, col, time, i, totalBoxes) {
                              var box = $(box2Darr[row][col]);
                              var w = box.width();
                              var h = box.height();
                              if(currentEffect === 'boxRainGrow' || currentEffect === 'boxRainGrowReverse'){
                                box.width(0).height(0);
                              }
                              if(i === totalBoxes-1){
                                setTimeout(function(){
                                  box.animate({ opacity:'1', width:w, height:h }, settings.animSpeed/1.3, '', function(){ slider.trigger('nivo:animFinished'); });
                                }, (100 + time));
                              } else {
                                setTimeout(function(){
                                  box.animate({ opacity:'1', width:w, height:h }, settings.animSpeed/1.3);
                                }, (100 + time));
                              }
                            })(rows, prevCol, timeBuff, i, totalBoxes);
                            i++;
                          }
                          prevCol--;
                        }
                        timeBuff += 100;
                      }
                    }           
            };

            // Shuffle an array
            var shuffle = function(arr){
              for(var j, x, i = arr.length; i; j = parseInt(Math.random() * i, 10), x = arr[--i], arr[i] = arr[j], arr[j] = x);
              return arr;
            };

            // For debugging
            var trace = function(msg){
              if(this.console && typeof console.log !== 'undefined') { console.log(msg); }
            };

            // Start / Stop
            this.stop = function(){
              if(!$(element).data('nivo:vars').stop){
                $(element).data('nivo:vars').stop = true;
                trace('Stop Slider');
              }
            };

            this.start = function(){
              if($(element).data('nivo:vars').stop){
                $(element).data('nivo:vars').stop = false;
                trace('Start Slider');
              }
            };

            // Trigger the afterLoad callback
            settings.afterLoad.call(this);

            return this;
    };

    $.fn.nivoSlider = function(options) {
      return this.each(function(key, value){
        var element = $(this);
        // Return early if this element already has a plugin instance
        if (element.data('nivoslider')) { return element.data('nivoslider'); }
        // Pass options to plugin constructor
        var nivoslider = new NivoSlider(this, options);
        // Store plugin object in this element's data
        element.data('nivoslider', nivoslider);
      });
    };

    //Default settings
    $.fn.nivoSlider.defaults = {
      effect: 'random',
      slices: 15,
      boxCols: 8,
      boxRows: 4,
      animSpeed: 500,
      pauseTime: 3000,
      startSlide: 0,
      directionNav: true,
      controlNav: true,
      controlNavThumbs: false,
      pauseOnHover: true,
      manualAdvance: false,
      prevText: 'Prev',
      nextText: 'Next',
      randomStart: false,
      beforeChange: function(){},
      afterChange: function(){},
      slideshowEnd: function(){},
      lastSlide: function(){},
      afterLoad: function(){}
    };

    $.fn._reverse = [].reverse;

  })(jQuery);

