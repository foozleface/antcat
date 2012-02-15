$(function() {
  setupSearch();
  setupDisplays();
  if (user_can_edit) {
    setupEdits();
  }
})

function setupSearch() {
  $('#search form').submit(function(){
    var inp = $('#q', $(this))
    inp.blur()
    var string = inp.attr('value')
    if (!string.match(/ $/))
      string += ' '
    string.replace(/'/, '"')
    inp.attr('value', string)
  });
  $("#search form").keypress(function (e) {
    if ((e.which && e.which == 13) || (e.keyCode && e.keyCode == 13)) {
        $('button[type=submit].default').click();
        return false;
    } else {
        return true;
    }
  });

  setupSearchBox($('#search_selector option:selected').text())
  $('#search_selector').change(function() {
    new_type = $('#search_selector option:selected').text()
    if (new_type == 'Search for')
      removeAdvancedSearchAuthorAutocomplete();
    setupSearchBox(new_type);
  })
}

function setupSearchBox(selector_text) {
  if (selector_text == 'Search for') {
    setHelpIconText("Enter search words (including author names), a year, a year range or an ID. Words are searched for in the title, author names, journal name, publisher name, citation, cite code, and notes.)");
  } else {
    setupAdvancedSearchAuthorAutocomplete();
    setHelpIconText("Start typing an author's name, then choose it from the list and press Enter. Repeat for additional author names. Then press Enter to find references by all those authors, including references by aliases of those authors. For example, searching for Radchenko, A.G. will also find references by Radchenko, A., Radtchenko, A. G., and Radtschenko, A. G.");
  }
}

function setHelpIconText(text) {
  $('.help_icon').qtip({
    content: text,
    style: {width: 600},
    show: 'mouseover',
    hide: 'mouseout',
    position: {
      adjust: {y: -7},
      corner: {target: 'topLeft', tooltip: 'bottomRight'}
    }
  })
}

/////////////////////////////////////////////////////////////////////////

function setupDisplays() {
  setupIcons();
}

function setupIcons() {
  setupIconVisibility()
  if (user_can_edit) {
    setupIconHighlighting()
    setupIconClickHandlers()
  }
}

function setupIconVisibility() {
  if (!testing || !user_can_edit)
    $('.icon').hide();

  if (!user_can_edit)
    return

  $('.reference').live('mouseenter',
    function() {
      if (!isEditing())
        $('.icon', $(this)).show();
    }).live('mouseleave',
    function() {
      $('.icon').hide();
    });
}

function setupIconHighlighting() {
  $('.icon img').live('mouseenter',
    function() {
      this.src = this.src.replace('off', 'on');
    }).live('mouseleave',
    function() {
      this.src = this.src.replace('on', 'off');
    });
}

function setupIconClickHandlers() {
  $('.icon.edit').live('click', editReference);
  $('.icon.add').live('click', insertReference);
  $('.icon.copy').live('click', copyReference);
  $('.icon.delete').live('click', deleteReference);
}

function setupEdits() {
  $('.reference_edit').hide();
  $('.reference_edit .submit').live('click', submitReferenceEdit);
  $('.reference_edit .cancel').live('click', cancelReferenceEdit);
  $('.reference_edit .delete').live('click', deleteReference);
}

///////////////////////////////////////////////////////////////////////////////////

function editReference() {
  if (isEditing())
    return false;

  $reference = $(this).closest('.reference');
  saveReference($reference);
  showReferenceEdit($reference, {showDeleteButton: true});
  return false;
}

function deleteReference() {
  $reference = $(this).closest('.reference');
  $reference.addClass('about_to_be_deleted');
  if (confirm('Do you want to delete this reference?')) {
    $.post($reference.find('form').attr('action'), {'_method': 'delete'},
      function(data){
        if (data.success) {
          $reference.closest('tr').remove();
          removeSavedReference()
        } else
          alert(data.message);
      });
  } else
    $reference.removeClass('about_to_be_deleted');

  return false;
}

function addReference() {
  addOrInsertReferenceEdit(null);
  return false;
}

function insertReference() {
  addOrInsertReferenceEdit($(this).closest('.reference'));
  return false
}

function copyReference() {
  $rowToCopyFrom = $(this).closest('tr.reference_row');
  $newRow = $rowToCopyFrom.clone(true);
  $rowToCopyFrom.after($newRow);
  $newReference = $('.reference', $newRow);
  $newReference.attr("id", "reference_");
  $('form', $newReference).attr("action", "/references");
  $('[name=_method]', $newReference).attr("value", "post");
  clearFieldsThatShouldntBeCopied($newReference)
  showReferenceEdit($newReference);
  return false;
}

function clearFieldsThatShouldntBeCopied($reference) {
  $('#reference_document_attributes_id', $reference).remove()
  $('#reference_document_attributes_url', $reference).attr("value", "")
  $('#reference_document_attributes_public', $reference).attr("checked", "")
  $('#reference_date', $reference).attr("value", "")
  $('#reference_cite_code', $reference).attr("value", "")
}

function addOrInsertReferenceEdit($reference) {
  $referenceTemplateRow = $('.reference_template_row');
  $newReferenceRow = $referenceTemplateRow.clone(true);
  $newReferenceRow.removeClass('reference_template_row').addClass('reference_row');
  $('.reference_template', $newReferenceRow).removeClass('reference_template').addClass('reference');

  if ($reference == null)
    $('.references').prepend($newReferenceRow);
  else
    $reference.closest('tr').after($newReferenceRow);

  $newReference = $('.reference', $newReferenceRow);
  showReferenceEdit($newReference);
}

///////////////////////////////////////////////////////////////////////////////////

function saveReference($reference) {
  $('#saved_reference').remove()
  $reference.clone(true)
    .attr('id', 'saved_reference')
    .appendTo('body')
    .hide()
}

function restoreReference($reference) {
  var id = $reference.attr('id');
  $reference.replaceWith($('#saved_reference'))
  $('#saved_reference').attr('id', id).show()
}

function removeSavedReference() {
  $('#saved_reference').remove()
}

function showReferenceEdit($reference, options) {
  if (!options)
    options = {}

  $('.reference_display', $reference).hide();
  if (!testing)
    $('.icon').hide()

  var $edit = $('.reference_edit', $reference);

  if (!options.showDeleteButton)
    $('.delete', $edit).hide();

  setupTabs($reference);

  setupReferenceEditAuthorAutocomplete($reference);
  setupReferenceEditJournalAutocomplete($reference);
  setupReferenceEditPublisherAutocomplete($reference);

  $edit.show();
  $('#reference_author_names_string', $edit)[0].focus();
}

function setupTabs($reference) {
  var id = $reference.attr('id');
  var selected_tab = $('.selected_tab', $reference).val();

  $('.tabs .article-tab', $reference).attr('href', '#reference_article' + id);
  $('.tabs .article-tab-section', $reference).attr('id', 'reference_article' + id);

  $('.tabs .book-tab', $reference).attr('href', '#reference_book' + id);
  $('.tabs .book-tab-section', $reference).attr('id', 'reference_book' + id);

  $('.tabs .nested-tab', $reference).attr('href', '#reference_nested' + id);
  $('.tabs .nested-tab-section', $reference).attr('id', 'reference_nested' + id);

  $('.tabs .unknown-tab', $reference).attr('href', '#reference_unknown' + id);
  $('.tabs .unknown-tab-section', $reference).attr('id', 'reference_unknown' + id);

  $('.tabs', $reference).tabs({selected: selected_tab});
}

////////////////////////////////////////////////////////////////////////////////

function submitReferenceEdit() {
  $(this).closest('form').ajaxSubmit({
    beforeSerialize: beforeSerialize,
    beforeSubmit: setupSubmit,
    success: updateReference,
    dataType: 'json'
  });
  return false;
}

function beforeSerialize($form, options) {
  var selectedTab = $.trim($('.ui-tabs-selected', $form).text())
  $('#selected_tab', $form).val(selectedTab)
  return true;
}

function setupSubmit(formData, $form, options) {
  var $spinnerElement = $('button', $form).parent();
  $spinnerElement.spinner({position: 'left', img: '/stylesheets/ext/jquery-ui/images/ui-anim_basic_16x16.gif'});
  $('input', $spinnerElement).attr('disabled', 'disabled');
  $('button', $spinnerElement).attr('disabled', 'disabled');
  return true;
}

function updateReference(data, statusText, xhr, $form) {
  var $reference = $('#reference_' + (data.isNew ? '' : data.id));

  var $edit = $('.reference_edit', $reference);

  var $spinnerElement = $('button', $edit).parent();
  $('input', $spinnerElement).attr('disabled', '');
  $('button', $spinnerElement).attr('disabled', '');
  $spinnerElement.spinner('remove');

  $reference.parent().html(data.content);

  if (!data.success) {
    $reference = $('#reference_' + (data.isNew ? '' : data.id));
    showReferenceEdit($reference);
    return;
  }

  $reference = $('#reference_' + data.id);
  $('.reference_edit', $reference).hide();

  $('.reference_display', $reference)
    .show()
    .effect("highlight", {}, 3000)
}

function cancelReferenceEdit() {
  $reference = $(this).closest('.reference');
  if ($reference.attr('id') == 'reference_')
    $reference.closest('tr').remove();
  else {
    id = $reference.attr('id')
    restoreReference($reference);
    $reference = $('#' + id)
    $('.reference_display', $reference)
      .show()
      .effect("highlight", {}, 3000)
  }

  return false;
}

////////////////////////////////////////////////////////////////////////////////

function isEditing() {
  return $('.reference_edit').is(':visible');
}

