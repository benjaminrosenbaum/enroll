  $(document).on('click', 'a.qle-menu-item', function() {
    qle_text = $(this).text();
    $('#event-title').html($(this).html());
  	$('#qle-details').removeClass('hidden');
  	if(qle_text.toLowerCase() == "change in aptc/csr" || qle_text.toLowerCase() == "being native american" || qle_text.toLowerCase() == "my immigration status has changed" || qle_text.toLowerCase() == "hbx (exchange)/hhs error"){
  		$('#qle-panel-body').addClass('hidden');
  		$('#qle-default-footer').addClass('hidden');
  		$('#qle-special-footer').removeClass('hidden');
  	}
  	else {	
      $('.qle-details-title').html($(this).html());
      $('#change_plan').val($(this).html());
      init_datepicker_for_qle_date();
      $('#qle-panel-body').removeClass('hidden');
      $('#qle-special-footer').addClass('hidden');
  		$('#qle-default-footer').removeClass('hidden');
    }
  });
  
	$(document).on('click', '#qle-details .close-popup, #qle-details .cancel, #existing_coverage, #new_plan', function() {
		$('#qle-details').addClass('hidden');
		$('#qle-details .success-info, #qle-details .error-info').addClass('hidden');
    $('#qle-details .qle-form').removeClass('hidden');
    $("#qle_date").val("");

		$('#qle_flow_info #qle-menu').show();
	});

	// Disable form submit on pressing Enter, instead click Submit link
  $('#qle_form').on('keyup keypress', function(e) {
    var code = e.keyCode || e.which;
    if (code == 13) { 
      e.preventDefault();
      $("#qle_submit").click();
      return false;
    }
  });

	/* QLE Date Validator */
	$(document).on('click', '#qle_submit', function() {
		if(check_qle_date()) {
			$('#qle_date').removeClass('input-error');
			get_qle_date();
		} else {
			$('#qle_date').addClass('input-error');
			$('.success-info').addClass('hidden');
			$('.error-info').addClass('hidden');
		}
	});

	function check_qle_date() {
		var date_value = $('#qle_date').val();
		if(date_value == "" || isNaN(Date.parse(date_value))) { return false; }
		return true;
	}

  function get_qle_date() {
    qle_type = $(".qle-details-title").text();

    $.ajax({
      type: "GET",
      data:{date_val: $("#qle_date").val(), qle_type: qle_type},
      url: "/consumer_profiles/check_qle_date.js"
    });
  }

  function init_datepicker_for_qle_date() {
    var target = $('.qle-date-picker');
    var dateMin = $(target).attr("data-date-min");
    var dateMax = $(target).attr("data-date-max");
    var cur_qle_title = $('.qle-details-title').html();
    if (cur_qle_title === "I've had a baby" || cur_qle_title === "A family member has died" || cur_qle_title === "I've married") {
      dateMin = "-60d";
      dateMax = "+0d";
    };
    if (cur_qle_title === "Myself or a family member has lost other coverage" || cur_qle_title === "Mid-month loss of mec" || cur_qle_title === "My employer failed to pay premiums on time" || cur_qle_title === "I've moved into the district of columbia") {
      dateMin = "-60d";
      dateMax = "+60d";
    };

    $(target).val('');
    $(target).datepicker('destroy');
    $(target).datepicker({
      changeMonth: true,
      changeYear: true,
      dateFormat: 'mm/dd/yy',
      minDate: dateMin,
      maxDate: dateMax});
  }

	$(document).on('click', '#qle_continue_button', function() {
		$('#qle_flow_info .initial-info').hide();
		$('#qle_flow_info .qle-info').removeClass('hidden');
	})
});
