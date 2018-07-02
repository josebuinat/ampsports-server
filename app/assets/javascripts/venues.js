// ######################
// DROPZONE -- EDIT VENUE
// ######################

$(function() {

  var myDropZone;

  var $photosModal = $('#manage-photos');
  if ($photosModal.length) {
    $photosModal.on('shown.bs.modal', function () {
      window.dispatchEvent(new Event('resize'));
    });
  }

  var $form = $("#edit-venue");
  if ($form.length) {
    $form.validate();
    $form.on("ajax:success", updateSuccess);
    $form.on("ajax:error", updateFail);
    $form.on('ajax:beforeSend', disableButton($('button[type=submit]')));
  }

  var $colors_form = $("#edit-venue-colors");
  if ($colors_form.length) {
    $colors_form.on("ajax:success", updateSuccess);
    $colors_form.on("ajax:error", updateFail);
    $colors_form.on('ajax:beforeSend', disableButton($('button[type=submit]')));
  };

  $colors_form.find('.venue-color-selector').on('change', function() {
    var type = $(this).data('type');
    var color = $(this).val();
    if (color) {
      $('.venue-color-example-' + type).html('');
    }
    $('.venue-color-example-' + type).css('background-color', color);
  });

  $colors_form.find('.venue-color-clear').on('click', function() {
    var type = $(this).data('type');
    var color = $(this).data('color');
    $('.venue-color-example-' + type).css('background-color', color);
    if (!color) {
      $('.venue-color-example-' + type).html(I18n.t('venues.edit.no_color'));
    }
    $colors_form.find('.venue-color-selector[data-type="' + type + '"]').val(color);
  });

  $('.del-img-btn').bind('ajax:beforeSend', function(event) {
    var $btn = $(event.target);
    $btn.hide();
    $btn.siblings('.sk-spinner').show();
  });


  if ($('#listed').length) {
    $('#listed').change(switchListed);
  }

  $(document).on('click', '.admin-show-reservation-log-JS', function(e) {
    e.preventDefault();
    loadResvLog($(this).prop('href'));
    return false;
  });

  $(document).on('click', '.admin-show-resell-to-user-JS', function(e) {
    e.preventDefault();
    loadSellResv($(this).prop('href'))
    return false;
  });
});

function updateSuccess(e, data) {
  toastr.success("Updated...");
  enableButton($("button[type='submit']"))();
}

function updateFail(e, data) {
  toastr.error("Something went wrong! Check data for errors...!");
  enableButton($("button[type='submit']"))();
}

// handles custom colors for customers; initialized in venues edit page
function ColorContainer(baseElement, initialColors, initialOptions) {
  var self = this;
  const USER = "USER";
  const DISCOUNT = "DISCOUNT";

  var init = function(baseElement, initialColors, initialOptions) {
    self.baseElement = $(baseElement);
    self.type = baseElement.toLowerCase().includes("user") ? USER : DISCOUNT;
    self.colorContainer = self.baseElement.find('.colors-container')
    self.initialColors = initialColors; //{id: colors}
    self.initialOptions = initialOptions; //{id: label}
    self.AddBtn = self.baseElement.find('.add-row');
    self.AddBtn.off().on('click', addRow);

    self.new_item = self.colorContainer.find('.row.color-item:hidden').detach();
    self.new_item.css('visibility', 'visible');
    self.items = [];
    initItems();
  }

  var initItems = function() {
    const idKey = self.type == USER ? 'user_id' : 'discount_id'
    $.each(self.initialColors, function(index, colorInfo){
      const item = self.new_item.clone();
      const id = colorInfo[idKey];
      item.find('select').append(
        '<option value='+ id + ' selected>' + self.initialOptions[id] + '</option>'
      )
      item.data('id', id);
      self.items.push(item);
    })
    render();

    $.each(self.initialColors, function(index, colorInfo){
      var item = self.items[index];
      item.find('.venue-color-selector').val(colorInfo.color).trigger('change');
      item.find('select').trigger('change');
    })
  }

  var addRow = function(){
    self.items.push(self.new_item.clone());
    render();
  }

  var removeRow = function(index){
    self.items.splice(index, 1);
    render();
  }

  var render = function() {
    self.colorContainer.children().detach();
    $.each(self.items, function(index, item){
      self.colorContainer.append(item);
      activateFields(item, index);
    });
  }

  var activateFields = function(item, index) {
    initSelect(item);
    initRemoveBtn(item, index);
    initColorSelector(item);
    initClearColor(item);
  }

  var initRemoveBtn = function(item, index){
    item.find('.remove-row').off().on('click', function(){ removeRow(index)});
  }

  var initColorSelector = function(item){
    item.find('.venue-color-selector').off().on('change', function(){
      var color = $(this).val();
      var color_example = item.find('.color-example');
      if (color) {
        $(color_example).html('');
      }
      $(color_example).css('background-color', color);
    });
  }

  var initClearColor = function(item){
    const idKey = self.type == USER ? 'user_id' : 'discount_id'
    item.find('.venue-color-clear').off().on('click', function(){
      var id = item.data('id');
      var color = null;
      $.each(self.initialColors, function(index, colorInfo){
        if (colorInfo[idKey] == id) {
          color = colorInfo.color;
        }
      });

      item.find('.color-example').css('background-color', color);
      if (!color) {
        item.find('.color-example').css('background-color', '');
        item.find('.color-example').html(I18n.t('venues.edit.no_color'));
      }
      item.find('.venue-color-selector').val(color);
      if(self.initialOptions[id]) {
        item.find('select').val(id).trigger('change');
      }
    });
  }


  var initSelect = function(item) {
    var select = item.find('select');
    if (select.next().hasClass('select2-container')) {
      select.next().remove();
    }

    select.select2({
      placeholder: 'Select Option',
      allowClear: true,
      ajax: {
        url: self.baseElement.data('url'),
        dataType: 'json',
        delay: 250,
        data: function (params) {
          return {
            q: params.term, // search term
            page: params.page
          };
        },
        processResults: function(data, params) {
          var results = $.map(data, function(item) {
            if(self.type == USER) {
              return { id: item.value, text: item.label };
            } else if (self.type == DISCOUNT){
              return { id: item.id, text: item.name };
            }
          });

          return {
            results: results
          }
        },
        cache: true
      }
    });

    select.on('change', function(){
      var id = $(this).val();
      var color_input = $(this).closest('.row').find("input.venue-color-selector")
      var name = color_input.data('name') + '[' + id + ']'
      color_input.prop('name', name);
    })
  }

  init(baseElement, initialColors, initialOptions);
};

// ##########################
// FullCalendar -- VENUE VIEW
// ##########################

// init function
// =============

$(function () {
  window.reservations_cart_store = new ReservationsCartStore($("#calendar").data('venue-id'));

  $('#resv-view').on('hide.bs.modal', function () {
    // because modal form will be wiped out on the next show
    remove_cart_booking_form_list()

    if (reservations_cart_store.use_cart()) {
      $('#calendar').fullCalendar('refetchEvents')
    }
  })

  $.fn.modal.Constructor.prototype.enforceFocus = function () {};

  $("#reservationPrice").hide();
  $("#priceIcon").hide();

  $('.reservationSuccess').click(function(){
  });

  var $calendar = $('#calendar');
  var fullCalendarSetting = {
    selectable: true,
    selectOverlap: false,
    selectHelper: true,
    editable: true,
    resizable: true,
    eventOverlap: false,
    select: calendar_select_action,
    eventClick: loadResv,
    eventResize: change_reservation_duration,
    eventDrop: move_reservation,
    eventMouseover: show_note_tooltip,
    eventMouseout: hide_note_tooltip,
    lang: I18n.currentLocale(),
    schedulerLicenseKey: 'CC-Attribution-NonCommercial-NoDerivatives',
    resources: getResources,
    eventSources: [
       {
        url: "/venues/" + $calendar.attr('data-venue-id') + '/reservations.json'
      },
      {
        url: "/venues/" + $calendar.data('venue-id') + '/holidays.json',
        rendering: 'background',
        backgroundColor: 'lightgray',
        error: function(jq, status, err) {
        }
      },
      {
        url: "/venues/" + $calendar.data('venue-id') + '/closing_hours.json',
        rendering: 'background',
        backgroundColor: 'lightgray',
        error: function(jq, status, err) {
        }
      },
      {
        url: "/venues/" + $calendar.data('venue-id') + '/active_courts.json',
        rendering: 'background',
        backgroundColor: 'lightgray',
        error: function(jq, status, err) {
        }
      },
      {
        events: fetch_cart_reservations
      }
    ],
    timeFormat: 'H(:mm)', // uppercase H for 24-hour clock
    titleFormat: {
       month: 'MMMM yyyy',
       week: "d MMMM[ yyyy]{ '&#8212;' d MMMM yyyy}",
       day: 'dddd,  D/MM/YYYY'
    },
    defaultView: 'agendaDay',
    header: {
      left: 'week_backward,prev,next,week_forward',
      center: 'title',
      right: 'today'
    },
    minTime: '06:00:00',
    maxTime: '24:00:00',
    views: {
      agenda: {
        allDaySlot: false
      },
      agendaTwoDay: {
        type: 'agenda',
        duration: { days: 2 },

        // views that are more than a day will NOT do this behavior by default
        // so, we need to explicitly enable it
        groupByResource: true

        //// uncomment this line to group by day FIRST with resources underneath
        //groupByDateAndResource: true
      }
    },
    customButtons: {
      week_forward: {
        icon: 'right-double-arrow',
        click: function() {
          $('#calendar').fullCalendar('incrementDate', moment.duration(7, 'days'))
        }
      },
      week_backward: {
        icon: 'left-double-arrow',
        click: function() {
          $('#calendar').fullCalendar('incrementDate', moment.duration(-7, 'days') )
        }
      }
    },
  };

  $calendar.fullCalendar(fullCalendarSetting);

  $('#calendar .fc-week_backward-button').prop('title', I18n.t('venues.view.calendar_prev_week_button')).tooltip()
  $('#calendar .fc-week_forward-button').prop('title', I18n.t('venues.view.calendar_next_week_button')).tooltip()
  $('#calendar .fc-prev-button').prop('title', I18n.t('venues.view.calendar_prev_day_button')).tooltip()
  $('#calendar .fc-next-button').prop('title', I18n.t('venues.view.calendar_next_day_button')).tooltip()


  $sportSelect = $('#sport-select');
  if ($sportSelect.length) {
    $sportSelect.change(function() {
      $calendar.fullCalendar('refetchResources');
    });
  }

  $surfaceSelect = $('#surface-select');
  if ($surfaceSelect.length) {
    $surfaceSelect.change(function() {
      $calendar.fullCalendar('refetchResources');
    });
  }

});

function getResources(callback) {
  $.ajax({
    url: "/venues/" + $('#calendar').attr('data-venue-id') + '/courts.json?sport=' + $('#sport-select').val() + '&surface=' + $('#surface-select').val(),
    success: function(resp) {
      callback(resp);
    }
  });
}

// helpers
// =======

function initResvForm(data, formInitiator) {
  formInitiator();
  initDateTimes();
  initEvents();
  init_rsrv_reselect_event();

  if (data) {
    initSelects(data.id);
  } else {
    initSelects($('#courtTest').data('id'));
    data = getResvData();
  }

  $('#reservationStartTime').val(moment(data.start).format('HH:mm'));
  $('#reservationEndTime').val(moment(data.end).format('HH:mm'));
  $('#reservationDate').val(moment(data.start).format('DD/MM/YYYY'));
}

// returns true if price-auto checkbox is checked
function isPriceAuto(){
  return $("#price-auto").is(':checked');
}

function initRemoteForm(success, fail) {
  return function() {
    var $form = $('.remote-form');
    $form.on('ajax:success', success);
    $form.on('ajax:error', fail);
    $form.on('ajax:complete', enableButton($('button[type=submit]')));
    $form.on('ajax:beforeSend', disableButton($('button[type=submit]')));
    $form.validate();
  };
}

function initUserSelect(venue_id) {
  var $user = $('#selectUser');
  if (!venue_id) venue_id = $("#calendar").data("venue-id");

  $.getJSON('/venues/' + venue_id + '/map_users.json').done(
    function( data ) {

      data = $.map(data, function(item) {
        return { id: item.id, text: item.name };
      });

      data.unshift({id: "-1", text: "Select User"});

      $user.select2({
        placeholder: { id: "-1", text: 'Select User'},
        allowClear: true,
        minimumInputLength: 0,
        data: data
      });

      if (reservations_cart_store.use_cart() && reservations_cart_store.user_id()) {
        $("#selectUser").val(reservations_cart_store.user_id()).trigger('change');
      }
    }
  );
}

function initSelects(courtId) {
  initUserSelect();

  $.getJSON('/venues/' + $("#calendar").data("venue-id") + '/courts.json').done(
    function( data ) {

      data = $.map(data, function(item) {
        return { id: item.id, text: item.title_with_sport };
      });

      $('#courtTest').select2({
        placeholder: 'Select Court',
        minimumInputLength: 0,
        data: data
      });

      $('#courtTest').val(courtId).trigger('change');
    }
  );

  if ($('#pay-with-game-pass-select').length > 0) {
    axios.get('/api/game_passes/available.json', {
      params: {
        venue_id: $("#calendar").data("venue-id"),
        user_id: $('#pay-with-game-pass-select').data('userid'),
        court_id: courtId,
        start_time: getResvStartTime().format('YYYY-MM-DD HH:mm'),
        end_time: getResvEndTime().format('YYYY-MM-DD HH:mm'),
      }
    }).then(function(response) {
      data = $.map(response.data, function(item) {
        return { id: item.value, text: item.label };
      });
      $('#pay-with-game-pass-select').select2({
        placeholder: I18n.t('reservations.edit.select_game_pass'),
        allowClear: true,
        minimumInputLength: 0,
        data: data
      });
    });
  };
}

function initEvents() {
  $("#courtTest, #selectUser, #reservationStartTime, #reservationEndTime").change(function() {
    if(isPriceAuto()) loadPrice();
    // in this case initial render of info runs after courts select2 initialization
    render_reservation_form_info();
  });

  $("#price-auto").change(function(event){
    var priceAuto = $(event.target).is(':checked');
    if(priceAuto){
      loadPrice();
    } else {
      $("#reservationPrice").val($("#reservationPrice").data('price'));
    }
  });
}

function change_reservation_duration(event, delta, revertFunc) {
  if (event.source.events == fetch_cart_reservations) {
    update_reservation_in_cart(event)
  } else {
    update_reservation_request(event, revertFunc)
  }
}

function move_reservation(event, delta, revertFunc) {
  swal({
    title: I18n.t('venues.view.copy_reservation_confirm_title'),
    text: I18n.t('venues.view.copy_reservation_confirm_text'),
    type: "info",
    showCancelButton: true,
    cancelButtonText: I18n.t('venues.view.move_reservation_button_text'),
    confirmButtonText: I18n.t('venues.view.copy_reservation_button_text')
  },
  function(isConfirmed) {
    if (isConfirmed) {
      if (event.source.events == fetch_cart_reservations) {
        put_reservation_in_cart(event.start, event.end, null, null, { id: event.resourceId })
      } else {
        update_reservation_request(event, revertFunc, 'copy')
      }
    } else {
      if (event.source.events == fetch_cart_reservations) {
        update_reservation_in_cart(event)
      } else {
        update_reservation_request(event, revertFunc)
      }
    }
  });
}

function show_note_tooltip(event, jsEvent, view){
  $(this).tooltip({
    title: event.note,
    container: 'body'
  });
  $(this).tooltip('show');
}

function hide_note_tooltip(event, jsEvent, view){
  $(this).tooltip('hide');
}

function update_reservation_request(event, revertFunc, type) {
  var url = '/venues/' + $("#calendar").data("venue-id") + '/reservations/' + event.id;
  if (type == 'copy') url += '/make_copy'

  data = {
    id:         event.id,
    date:       event.start.format('DD/MM/YYYY'),
    start_time: event.start.format('HH:mm'),
    end_time:   event.end.format('HH:mm'),
    court_id:   event.resourceId
  }

  $.ajax({
    type: "PUT",
    url: url,
    data: {
      _method: 'put',
      reservation: data
    },
    success: function() {
      if (type == 'copy') {
        toastr.success(I18n.t('reservations.update.copy_success'));
      } else {
        toastr.success(I18n.t('reservations.update.update_success'));
      }
      $('#calendar').fullCalendar('refetchEvents');
    },
    error: function(resp) {
      revertFunc();
      resvFormFail('', resp);
    }
  })
}

//
// reservations cart functions for calendar and external forms
//

function fetch_cart_reservations(start, end, timezone, callback) {
  if (reservations_cart_store == undefined) {
    return callback([])
  }

  var data = reservations_cart_store.reservations()
  var events = []
  data.forEach( function(r) {
    if (r.end > start && r.start < end) {
      events.push({
        start: r.start,
        end: r.end,
        resourceId: r.court_id,
        title: 'In cart ' + r.key + (r.error ? ' ERROR: ' + r.error : ''),
        color: r.error ? '#34495e' : '#8e44ad',
        key: r.key
      })
    }
  });

  callback(events);
}

function calendar_select_action(start, end, jsEvent, view, res) {
  if (jsEvent.target.className.indexOf('fc-bgevent') > -1) {
    $('#calendar').fullCalendar('unselect');
    return false;
  }

  if (run_rsrv_reselect_event(start, end, jsEvent, view, res)) {
    return false;
  }

  if (reservations_cart_store.use_cart()) {
    return put_reservation_in_cart(start, end, jsEvent, view, res);
  } else {
    return loadNewResv(start, end, jsEvent, view, res);
  }
}

function put_reservation_in_cart(start, end, jsEvent, view, res) {
  var data = {
    start: start,
    end: end,
    court_id: res.id,
    price: ''
  };
  data = reservations_cart_store.add_reservation(data);

  $('#calendar').fullCalendar('unselect');
  $('#calendar').fullCalendar('refetchEvents');

  return false;
}

function update_reservation_in_cart(event) {
  reservations_cart_store.update_reservation(event.key, {
    start:    event.start,
    end:      event.end,
    court_id: event.resourceId
  })
}

function delete_from_cart(key) {
  reservations_cart_store.delete_reservation(key)
  $('#resv-view').modal('toggle');
}

function load_cart_booking_form(currency) {
  var url = '/venues/' + $("#calendar").data("venue-id") + "/reservations/new_cart";
  $.get(url, load_cart_booking_form_success(currency));
  $('#resv-content').empty();
  $('#resv-view').modal('show');
  return false;
}

function render_cart_booking_form_list(currency) {
  if ($('#cart-reservations-list').length > 0) {
    ReactDOM.render(
      React.createElement(ReservationsCartForm, { currency: currency }, null ),
      document.getElementById('cart-reservations-list')
    )
  }
}

function remove_cart_booking_form_list() {
  if ($('#cart-reservations-list').length > 0) {
    ReactDOM.unmountComponentAtNode(document.getElementById('cart-reservations-list'))
  }
}

function load_cart_booking_form_success(currency) {
  return function(resp) {
    $("#resv-content").append($(resp));
    switchUserPane($("div[data-target='#existing-user']"));
    render_cart_booking_form_list(currency)
    initSelects('all_courts')
    initDateTimes();
    init_cart_form_events();

    initRemoteForm(cart_booking_success("Reservations added successfully."), cart_booking_fail)();
  }
}

function init_cart_form_events() {
  $("#selectUser").change(function() {
    reservations_cart_store.refetch_prices($(this).val())
  })
}

function cart_booking_success(message) {
  return function(resp, data) {
    object_foreach(data.saved, function(k,v) {
      reservations_cart_store.delete_reservation(k)
    })

    swal({
      title: message,
      text: "Thanks!",
      type: "success"
    });
    $('#calendar').fullCalendar('refetchEvents');
    $('#resv-view').modal('toggle');
  };
}

function cart_booking_fail(resp, data) {
  object_foreach(data.responseJSON.saved, function(k,v) {
    reservations_cart_store.delete_reservation(k)
  })

  object_foreach(data.responseJSON.errors, function(k,v) {
    reservations_cart_store.update_reservation(k, { error: v })
  })

  toastr.success('Valid reservations was saved, Invalid ones was left in cart');
  $('#calendar').fullCalendar('refetchEvents');
  render_cart_booking_form_list()

  object_foreach(data.responseJSON.errors, function(k,v) {
    toastr.error(v);
  })
}

//
// normal reservations
//

function loadNewResv(start, end, jsEvent, view, res) {
  if (jsEvent.target.className.indexOf('fc-bgevent') > -1) {
    $('#calendar').fullCalendar('unselect');
    return false;
  }

  var data = {
    start: start,
    end: end,
    id: res.id
  };

  var url = '/venues/' + $("#calendar").data("venue-id") + "/reservations/new";
  $.get(url, loadCreateResvSucc(data));
  $('#resv-content').empty();
  $('#resv-view').modal('show');
  return false;
}


function loadEditResv(element) {
  var url = $(element).data("edit-url");
  $.get(url, loadEditResvSucc);
  $('#resv-content').empty();
  return false;
}

function loadResv(event, jsEvent, view) {
  $('#reselect_notification_status').remove()
  if (!event.url) {
    $('#resv-content').empty();
    $("#resv-view").modal("show");
    $("#resv-content").append(
      '<div>' + event.title + '</div><br/><br/>' +
      '<button type="button" class="btn btn-danger" onclick="delete_from_cart(' + event.key + ')">Remove</button>'
    );
    return false;
  }
  $.get(event.url, loadResvSucc);
  $('#resv-content').empty();
  $("#resv-view").modal("show");
  return false;
}

function loadResvSucc(resp) {
  var $container = $("#resv-content");
  $container.append($(resp));
}

function loadEditResvSucc(resp) {
  var $container = $("#resv-content");
  $container.append($(resp));
  initResvForm(null,
               initRemoteForm(resvFormSucc("Reservation updated successfully."),
                              resvFormFail));
}

function loadCreateResvSucc(data) {
  return function(resp) {
    var $container = $("#resv-content");
    $container.append($(resp));
    switchUserPane($("div[data-target='#existing-user']"));
    initResvForm(data,
                 initRemoteForm(resvFormSucc("Reservation added successfully."),
                                resvFormFail));
  };
}

function resvFormSucc(message) {
  return function() {
    swal({
      title: message,
      text: "Thanks!",
      type: "success"
    });
    $('#calendar').fullCalendar('refetchEvents');
    $('#resv-view').modal('toggle');
  };
}

function resvFormFail(resp, data) {
  object_foreach(data.responseJSON.errors, function(k,v) {
    toastr.error(v);
  })
}

function getPriceData() {
  var date = getResvStartTime().format('YYYY-MM-DD');
  if ($('#selectUser').val() > 0) {
    var userid = $('#selectUser').val();
  } else {
    var userid = undefined;
  }
  var data = {
    date: date,
    start_time: getResvStartTime().format('YYYY-MM-DD HH:mm'),
    end_time: getResvEndTime().format('YYYY-MM-DD HH:mm'),
    court_id: $('#courtTest').val(),
    venue_id: $("#calendar").data('venue-id'),
    user_id: userid
  };
  return data;
}

function getResvData() {
  return({
    date: $('#reservationDate').val(),
    start: getResvStartTime(),
    end: getResvEndTime(),
    court_id: $('#courtTest').val()
  })
}

function getResvStartTime() {
  return moment($('#reservationStartTime').val() + ' ' +
           $('#reservationDate').val(), 'HH:mm DD/MM/YYYY')
}

function getResvEndTime() {
  return moment($('#reservationEndTime').val() + ' ' +
           $('#reservationDate').val(), 'HH:mm DD/MM/YYYY')
}

function loadPrice(){
  var data = getPriceData();
  $.getJSON({
    url: "/venues/" + data.venue_id + "/court_price_at.json",
    data: {
      start_time: data.start_time,
      end_time: data.end_time,
      court_id: data.court_id,
      user_id: data.user_id
    },
    success: function(object){
      if (object.price) {
        $("#reservationPrice").val(object.price);
      }
      $("#reservationPrice").show();
      $("#priceIcon").show();
    }
  });
}

function deleteResv(element) {
  swal({
    title: "Are you sure?",
    text: "You are about to remove this reservation permanently.",
    type: "warning",
    showCancelButton: true,
    confirmButtonText: "Yes, remove it!"
  },
  function(isConfirmed) {
    if (isConfirmed)
      $.ajax({
        url: $(element).data('delete-url'),
        type: "delete",
        success: resvFormSucc("Reservation deleted successfully."),
        fail: resvFormFail
      });
  });
  return false;
}

function switchListed() {
  var $switch = $('#listed');
  $switch.off('change');
  $.ajax({
    url: $switch.attr('data-url'),
    data: { status: $switch.val() },
    method: 'post',
    success: function (data) {
      $switch.on('change', switchListed);
      toastr.success(I18n.t('venues.edit.change_status_success'));
    },
    error: function (data, resp) {
      $switch.val(data.responseJSON.status)
      $switch.trigger('change')
      $switch.on('change', switchListed);
      var errors = data.responseJSON.errors;
      for ( var propt in errors) {
        for (var i = 0; i < errors[propt].length; i++){
          toastr.error(propt + ' ' + errors[propt][i]);
        }
      }
    }
  });
}

function paymentCheckbox(elem) {
  if (elem.checked) {
    $('#amount-paid').attr('disabled', 'disabled');
    $('#pay-with-game-pass').removeClass('hidden');
  } else {
    $('#amount-paid').removeAttr('disabled');
    $('#pay-with-game-pass').addClass('hidden');
  }
}

function updateCalendar(elem) {
  var date = moment(elem.value, 'DD/MM/YYYY');
  if (date.isValid())
    $('#calendar').fullCalendar('gotoDate', date);
}

function switchUserPane(elem) {
  var $userarea = $('#user-area');
  $userarea.children().hide();
  $userarea.find('.form-control').attr('disabled', 'disabled');
  $current = $($(elem).data('target'));
  $current.show();
  $current.find('.form-control').removeAttr('disabled');
}

function loadResvLog(url) {
  $.get(url, loadResvLogSucc);
  $('#resv-content').empty();
  $("#resv-view").modal("show");
  return false;
}

function loadResvLogSucc(resp) {
  var $container = $("#resv-content");
  $container.append($(resp));
  $('.rsrv-footable-log').footable();
}

function loadNewCourtModal(element){
  $.ajax({
    url: '/venues/' + $(element).data('venue-id') + '/courts/new',
    method: 'get',
    success: function (resp) {
      $('#new-court-form').html(resp)
      courts_indexes_select_add_form_listeners();
    },
    error: function (jqxhr, textStatus, error) {
      console.log(error);
    }
  });
}

function render_reservation_form_info() {
  var court_name = $('#courtTest').find('option:selected').text();
  var time_range = $('#reservationStartTime').val() + ' - ' + $('#reservationEndTime').val()

  $('#form-reservation-info .info-left').html(court_name + ', ' + $('#reservationDate').val())
  $('#form-reservation-info .info-right').html(time_range)
}

function init_rsrv_reselect_event() {
  $('#form-reservation-info .reselect-betton').click(function() {
    $('#form-reservation-info .reselect-betton').attr('data-active', 1)
    $("#resv-view").modal("hide");

    var message = I18n.t('venues.view.calendar_reservation_reselect');

    $('body').append('<div id="reselect_notification_status">' + message + '</div>')
  })
}

function run_rsrv_reselect_event(start, end, jsEvent, view, res) {
  if ($('#form-reservation-info .reselect-betton').attr('data-active') == '1') {
    confirm_reselect_duration_change(start, end, function() {
      $('#form-reservation-info .reselect-betton').attr('data-active', 0)
      $('#reselect_notification_status').remove()

      $('#reservationStartTime').val(moment(start).format('HH:mm'));
      $('#reservationEndTime').val(moment(end).format('HH:mm'));
      $('#reservationDate').val(moment(start).format('DD/MM/YYYY'));
      $('#courtTest').val(res.id).trigger('change');

      $("#price-auto").prop('checked', true).trigger('change');

      $("#resv-view").modal("show");
    });
    return true
  }
  return false
}

function confirm_reselect_duration_change(new_start, new_end, callback) {
  var start_time = getResvStartTime();
  var end_time = getResvEndTime();
  var duration = moment.duration(end_time - start_time);
  var new_duration = moment.duration(new_end - new_start);

  if (duration.asMinutes() == new_duration.asMinutes()) {
    callback();
    return false;
  };

  swal({
    title: I18n.t('venues.view.change_duration_confirm_title'),
    text: I18n.t('venues.view.change_duration_confirm_text', {
      start_time: new_start.format('HH:mm'),
      end_time: new_end.format('HH:mm'),
      duration: duration.asMinutes(),
      new_duration: new_duration.asMinutes()
    }),
    type: "info",
    showCancelButton: true,
    cancelButtonText: I18n.t('venues.view.change_duration_cancel_button_text'),
    confirmButtonText: I18n.t('venues.view.change_duration_button_text')
  },
  function(isConfirmed) {
    if (isConfirmed) {
      return callback()
    } else {
      return false
    }
  });
}

function ajax_turboclick_link(url) {
  window.history.pushState({}, '', url);
  $.ajax({
    url: url,
    method: 'get',
    dataType: 'script'
  });
}

// load and initiate Resell to user form
function loadSellResv(url) {
  $.get(url, loadSellResvSucc);
  $('#resv-content').empty();
  $("#resv-view").modal("show");
  return false;
}

function loadSellResvSucc(resp) {
  var $container = $("#resv-content");
  $container.append($(resp));

  switchUserPane($("div[data-target='#existing-user']"));
  initUserSelect($('.memberships-list-JS').data("venueid"));

  var id = $('.reservation-id-JS').data('id');

  initRemoteForm(
    function() {
      resvFormSucc(I18n.t('reservations.resell_to_user_form.success'))();
      $('tr[data-membership-reservation="' + id + '"]').remove();
    },
    resvFormFail
  )();
}
