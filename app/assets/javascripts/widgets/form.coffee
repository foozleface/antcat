window.AntCat or= {}

class AntCat.Form

  constructor: (@element, @options = {}) ->
    @element.addClass 'antcat_form'
    @save_form_values()
    @spinner_path = '/assets/ui-anim_basic_16x16.gif'
    (new Image()).src = @spinner_path
    self = @
    @element
      .find('.submit')
        .button()
        .click(-> self.submit this)
        .end()
      .find('.cancel')
        .button()
        .click(-> self.cancel this)
        .end()

  submit: (button) =>
    @start_spinning()
    @element.ajaxSubmit
      beforeSerialize: @before_serialize
      success: @update
      error: @handle_error
      dataType: 'json'
    false

  before_serialize: ($form, options) => true

  update: (data, statusText, xhr, $form) =>
    @stop_spinning()
    if not data.success
      @show_error_messages data.content
      return
    @options.on_done data.content

  handle_error: (jq_xhr, text_status, error_thrown) =>
    @stop_spinning()
    alert "Oh, shoot. It looks like a bug prevented this item from being saved.\n\nPlease report this situation to Mark Wilden (mark@mwilden.com) and we'll fix it.\n\n#{error_thrown}" unless AntCat.testing

  cancel: (button) =>
    @clear_error_messages()
    @restore_form_values() unless @is_new_item()
    @options.on_cancel() if @options.on_cancel
    false

  start_spinning: =>
    @element.find(':button')
      .disable()
      .parent().spinner position: 'left', leftOffset: 1, img: @spinner_path

  stop_spinning: =>
    @element.find('.spinner')
      .enable()
      .spinner 'remove'

  show_error_messages: (html) ->
    @clear_error_messages()
    @element.prepend $(html).find 'ul.error_messages'

  clear_error_messages: =>
    @element.find('ul.error_messages').remove()

  is_new_item: =>
    false #@element.attr('id') is 'item_'

  save_form_values: =>

  restore_form_values: =>
