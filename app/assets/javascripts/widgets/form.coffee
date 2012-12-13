window.AntCat or= {}

class AntCat.Form
  @css_class = 'antcat_form'

  constructor: ($element, @options = {}) ->
    @options.button_container or= '> .buttons'
    @initialize $element

  initialize: ($element) =>
    @element = $element
    @element
      .addClass(AntCat.Form.css_class)
      .find(@options.button_container)
        .find(':button').unbutton().button().end()
        .find(':button.submit').click(@submit).end()
        .find(':button.cancel').click(@cancel).end()
        .end()
      # commented out until can figure out why pressing Enter
      # in an autocomplete field triggers this
      #.keypress (event) =>
        #return true unless event.which is $.ui.keyCode.ENTER
        #@submit()
        #false

  open: =>
    @element.show() if @options.modal
    @element.find('input[type=text]:visible:first').focus()
    @options.on_open() if @options.on_open

  close: =>
    @element.hide() if @options.modal
    @options.on_close() if @options.on_close

  submit: =>
    @start_spinning()
    @form().ajaxSubmit
      beforeSerialize: @before_serialize
      success: @update
      error: @handle_error
      dataType: 'json'
    false

  form: => @element

  before_serialize: ($form, options) =>
    return @options.before_serialize($form, options) if @options.before_serialize
    true

  cancel: =>
    @options.on_cancel() if @options.on_cancel
    @close()
    false

  update: (data, statusText, xhr, $form) =>
    @stop_spinning()
    @options.on_update data if @options.on_update
    if data.success
      @options.on_done data if @options.on_done
      @close()

  handle_error: (jq_xhr, text_status, error_thrown) =>
    @stop_spinning()
    alert "Oh, shoot. It looks like a bug prevented this item from being saved.\n\nPlease report this situation to Mark Wilden (mark@mwilden.com) and we'll fix it.\n\n#{error_thrown}" unless AntCat.testing

  start_spinning: =>
    @element.find(':button')
      .disable()
      #.parent().spinner position: 'left', leftOffset: 1, img: AntCat.spinner_path

  stop_spinning: =>
    #@element.find('.spinner').spinner 'remove'
    @element.find('.buttons :button').undisable()

