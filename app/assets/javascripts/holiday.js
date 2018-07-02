$(function () {
  if ($("#court").length) {
    initDateTimes();
    initHolidayCourtSelect();
    $("#is-venue-checkbox").change(function() {
      if (this.checked) {
        $('#court').prop('disabled', 'disabled');
      } else {
        $('#court').prop('disabled', false);
      }
    });
    $(".delete-holiday").on("ajax:success", function (e, data) {
      $('#holiday-' + data.id).remove();
    });
    $("#holiday-form").on("ajax:success", function (e, response) {
      if (response.conflicting.length)
        createConflict(response.holiday);
      else
        createSuccess();
    });
    $("#holiday-form").on("ajax:error", function (e, data) {
      createFail();
    });
  }
});

function createSuccess(message) {
  var reload = !message;
  message = message || I18n.t('venues.holidays_new.create_success');
  toastr.success(message);
  if (reload) {
    window.location.reload();
  }
}

function createFail() {
  swal({
    title: I18n.t('venues.holidays_new.create_error'),
    type: "error"
  });
}

function createConflict(holiday) {
  swal({
    title: I18n.t('venues.holidays_new.create_conflict'),
    type: 'warning',
    showCancelButton: true,
    confirmButtonText: I18n.t('venues.holidays_new.cancel_conflicting'),
    cancelButtonText: I18n.t('venues.holidays_new.keep_conflicting'),
  }, function(isConfirm) {
    axios({
      method: 'post',
      url: '/holidays/' + holiday.id +'/handle_conflicting.json',
      data: { cancel_conflicting: isConfirm,
              authenticity_token: $('meta[name=csrf-token]').attr('content')},
    }).then(function(response) {
      createSuccess(response.data);
    });
  });
}

function initHolidayCourtSelect() {
  $.getJSON('/venues/' + $('#court').data('venue-id') + '/courts.json').done(
    function( data ) {

      data = $.map(data, function(item) {
        return { id: item.id, text: item.title_with_sport };
      });

      $('#court').select2({
        placeholder: 'Select Court',
        allowClear: true,
        minimumInputLength: 0,
        data: data
      });

      const ids = $.map(data, function(item) { return item.id });

      $('#js-holiday-select-all').change(function(e) {
        if (e.target.checked)
          $('#court').val(ids).trigger('change');
        else
          $('#court').val([]).trigger('change');
      });
    }
  ).error(function() {
    console.log('error: couldnt get courts!');
  });
}
