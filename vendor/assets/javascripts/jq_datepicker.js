function applyJQDatePickerSetup(ele) {

  var el = $(ele);

  if (el.is(".jq_datepicker_already_applied")) {
    return;
  }

  var dobIdentifiers = ['#jq_datepicker_ignore_person_dob', '#family_member_dob_', '#jq_datepicker_ignore_organization_dob', '#jq_datepicker_ignore_census_employee_dob', '[name="jq_datepicker_ignore_dependent[dob]"]'];
  var isElementDOBType = false;

  /* Checking If type of element is Date of Birth type. */
  $.each(dobIdentifiers, function(index, value){
    if(el.is(value)) {
      isElementDOBType = true;
      return;
    }
  });

  var yearMax = dchbx_enroll_date_of_record().getFullYear() + 10;
  var yearMin = dchbx_enroll_date_of_record().getFullYear() - 110;
  var otherFieldSelector = el.attr("data-submission-field");
  var otherField = $(otherFieldSelector);
  otherField.hide();
  el.show();
  var otherFieldId = otherField.attr("id");
  var labelFields = $("label[for='" + otherFieldId + "']");
  if (labelFields.length > 0) {
    labelFields.hide();
  }
  otherField.attr("class", "");

  var ofParentControl = otherField.parent();
  var ofGrandparentControl = ofParentControl.parent();

  var inErrorState = false;

  var dateMax = null;
  var dateMin = null;

  if (ofParentControl.is(".floatlabel-wrapper")) {
    if (ofGrandparentControl.is(".field_with_errors")) {
      inErrorState = true;
    }
  } else if (ofParentControl.is(".field_with_errors")) {
    inErrorState = true;
  }

  if (inErrorState) {
    var parentControl = el.parent();
    if (parentControl.is(".floatlabel-wrapper")) {
      parentControl.wrap("<div class=\"field_with_errors\"></div>");
    } else {
      el.wrap("<div class=\"field_with_errors\"></div>");
    }
  }

  if (el.is("[data-year-max]")) {
    yearMax = el.attr("data-year-max");
  }

  if (el.is("[data-year-min]")) {
    yearMin = el.attr("data-year-min");
  }

  if (el.is("[data-date-max]")) {
    dateMax = el.attr("data-date-max");
  }

  if (el.is("[data-date-min]")) {
    dateMin = el.attr("data-date-min");
  }

  el.datepicker({
    changeMonth: true,
    changeYear: true,
    dateFormat: 'mm/dd/yy',
    altFormat: 'yy-mm-dd',
    altField: otherFieldSelector,
    yearRange: yearMin + ":" + yearMax,
    onSelect: function(dateText, dpInstance) {
      $(this).datepicker("hide");
      $(this).trigger('change');

    }
  });
  if(!isElementDOBType) {
    el.datepicker('option', 'minDate', dateMin);
    el.datepicker('option', 'maxDate', dateMax);
  }
  el.datepicker("refresh");
  el.addClass("jq_datepicker_already_applied");
}

function applyJQDatePickers() {
  $(".jq-datepicker").each(function(idx, ele) {
    applyJQDatePickerSetup(ele);
    if ($(this).attr("readonly") != undefined){
      $(ele).datepicker('disable');
    }
  });
}
