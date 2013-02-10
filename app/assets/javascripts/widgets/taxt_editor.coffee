window.AntCat or= {}

# A TaxtEditor is a textarea with associated tag type selector, reference_picker and name picker
#
# #taxt
#   = text_area_tag :taxt_editor, '', Taxt.to_editable(taxt), rows: 1, class: 'taxt_edit_box'
#   = render 'tag_type_selectors/show'
#   = render 'reference_pickers/show'
#   = render 'name_pickers/show'
# In the page's CoffeeScript:
#   new AntCat.TaxtEditor $('#taxt'), parent_buttons: '.buttons_section'

$.fn.taxt_editor = (options = {}) ->
  return this.each -> new AntCat.TaxtEditor $(this), options

class AntCat.TaxtEditor
  constructor: (@element, @options = {}) ->
    @element.addClass 'taxt_editor'
    @control = @element.find '> textarea'
    console.log 'TaxtEditor ctor: no @control' unless @control.size() == 1
    @control.addClass 'taxt_edit_box'
    @tag_type_selector = new AntCat.TagTypeSelector(@element.find('.antcat_tag_type_selector'), on_ok: @handle_tag_type_selector_result, on_cancel: @after_form_closes)
    @reference_picker = @element.find '.antcat_reference_picker'
    console.log 'TaxtEditor ctor: no @reference_picker' unless @reference_picker.size() == 1
    @parent_buttons = $(@options.parent_buttons)
    if @options.parent_buttons
      @parent_buttons = @element.closest('form').find $(@options.parent_buttons)
    else
      @parent_buttons = @element.siblings().find(':button')
    console.log 'TaxtEditor ctor: no @parent_buttons' unless @parent_buttons.size() == 1
    @name_picker = new AntCat.NamePicker(@element.find('.antcat_name_picker').parent(), on_success: @handle_name_picker_result, on_close: @after_form_closes, field: false, hide_initially: true)
    @dashboard = new TaxtEditor.DebugDashboard @ if @options.show_debug_dashboard
    @dashboard?.show_status 'before'
    @value @control.val()
    @last_value @control.val()
    @control.bind 'keyup keydown mouseup dblclick', @handle_event
    @

  handle_event: (event) =>
    if not @is_tag_selected() and @is_new_tag_event(event)
      @tag_start = @start()
      @tag_end = @end()
      @open_tag_type_selector()
      return false

    if @is_tag_selected() and @is_tag_opening_event event
      @tag_start = @start()
      @tag_end = @end()
      @open_picker_for_existing_tag()
      return false

    if event.type is 'keyup' or event.type is 'mouseup'
      @dashboard?.show_event event
      @dashboard?.show_status 'before'
      @handle_change()
      @select_tag_if_caret_inside()
      @dashboard?.show_status 'after'

    true

  handle_change: =>
    old_value = @last_value()
    current_value = @value()
    return if old_value is current_value

    current_position = @start()
    new_value = TaxtEditor.remove_unbalanced_tags current_value
    @last_value new_value
    @value new_value if new_value isnt current_value
    @set_position current_position

  # opening and closing subdialogs

  before_form_opens: =>
    @replace_text_area_with_simulation()
    @parent_buttons.disable()

  open_tag_type_selector: =>
    @before_form_opens()
    @tag_type_selector.open()

  handle_tag_type_selector_result: (type) =>
    @open_picker_for_new_tag(type)

  after_form_closes: =>
    @parent_buttons.undisable()
    @replace_simulation_with_text_area()

  open_picker_for_new_tag: (type) =>
    if type == 'reference_button'
      new AntCat.ReferencePicker @reference_picker.parent(), id: null, on_success: @handle_picker_result, on_close: @after_form_closes
    else
      @name_picker.open()

  open_picker_for_existing_tag: =>
    @before_form_opens()
    id = TaxtEditor.extract_id_from_editable_taxt @selection()
    type = TaxtEditor.extract_type_from_editable_taxt @selection()
    if type == 1
      new AntCat.ReferencePicker @reference_picker.parent(), id: id, on_success: @handle_picker_result, on_close: @after_form_closes
    else
      @name_picker.open()

  replace_text_area_with_simulation: =>
    # We need to indicate the selected tag in the taxt edit box
    # when the focus has moved to the reference picker, so the user can see
    # what they're editing. So replace the text area (and its selection) with
    # a paragraph that has a highlighted span
    @control.siblings('.antcat_taxt_simulation').remove()
    text = @control.val()
    before_selection = text[...@start()]
    selection = if @is_tag_selected() then text[@start()...@end()] else ' {Inserting...} '
    selection = '<span class=antcat_taxt_simulated_selection>' +  selection + '</span>'
    after_selection = text[@end()...]
    text = before_selection + selection + after_selection
    simulation = $("<p class='antcat_taxt_simulation ui-corner-all ui-widget-content ui-widget'>#{text}</p>")
    simulation.height @control.height()
    simulation.insertAfter @control
    @control.hide()

  replace_simulation_with_text_area: =>
    @element.find('.antcat_taxt_simulation').remove()
    @control.show()
 
  handle_name_picker_result: (data) =>
    @handle_picker_result data.taxt

  handle_picker_result: (taxt) =>
    if taxt
      new_value = @value()[...@tag_start] + taxt + @value()[@tag_end...]
      @value new_value

    @after_form_closes()

    if taxt
      @set_selection @tag_start, @tag_start + taxt.length - 1
    else
      @set_selection @tag_start, @tag_end

  # this value is duplicated in lib/taxt.rb
  @EDITABLE_ID_DIGITS = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

  @extract_id_from_editable_taxt: (taxt) ->
    TaxtEditor.id_from_editable taxt.match("{((.*?)? )?([#{@EDITABLE_ID_DIGITS}]+)}")[3]

  @extract_type_from_editable_taxt: (taxt) ->
    TaxtEditor.type_from_editable taxt.match("{((.*?)? )?([#{@EDITABLE_ID_DIGITS}]+)}")[3]

  # this code is duplicated in lib/taxt.rb
  @id_from_editable: (id) ->
    result = 0
    base = @EDITABLE_ID_DIGITS.length
    multiplier = 1
    index = 0
    while true
      digit = id.charAt index
      digit_value = @EDITABLE_ID_DIGITS.indexOf digit
      result += digit_value * multiplier
      multiplier *= base
      index += 1
      return result / 10 if index >= id.length
  @type_from_editable: (id) ->
    result = 0
    base = @EDITABLE_ID_DIGITS.length
    multiplier = 1
    index = 0
    while true
      digit = id.charAt index
      digit_value = @EDITABLE_ID_DIGITS.indexOf digit
      result += digit_value * multiplier
      multiplier *= base
      index += 1
      return result % 10 if index >= id.length

  select_tag_if_caret_inside: =>
    tag_indexes = TaxtEditor.enclosing_tag_indexes @value(), @start()
    return unless tag_indexes
    @set_selection tag_indexes.left, tag_indexes.right
    true

  selection: =>
    @value()[@start()...@end()]

  is_tag_selected: =>
    @value().charAt(@start())   is '{' and
    @value().charAt(@end() - 1) is '}'

  is_tag_opening_event: (event) =>
    @is_new_tag_event(event) or
    event.type is 'keydown' and event.which is $.ui.keyCode.ENTER or
    event.type is 'dblclick'

  is_new_tag_event: (event) =>
    event.type is 'keydown' and
    event.which is @LEFT_BRACKET and
    event.shiftKey

  value:      => @control.val arguments...
  last_value: => @control.data 'last_value', arguments...
  start:      => @control.getSelection().start
  end:        => @control.getSelection().end
  focus:      => @control.focus()

  set_position:  (position)    => @control.setCaretPos position + 1
  set_selection: (left, right) => @control.setSelection left, right + 1

  LEFT_BRACKET: 219

  this.enclosing_tag_indexes = (text, position) ->
    opening_bracket_index = position - 1
    while opening_bracket_index >= 0
      break if text.charAt(opening_bracket_index) is '{'
      break if text.charAt(opening_bracket_index) is '}'
      --opening_bracket_index
    opening_bracket_index = undefined if opening_bracket_index < 0 or text.charAt(opening_bracket_index) is '}'

    closing_bracket_index = position
    while closing_bracket_index < text.length
      break if text.charAt(closing_bracket_index) is '}'
      break if text.charAt(closing_bracket_index) is '{'
      ++closing_bracket_index
    closing_bracket_index = undefined if closing_bracket_index >= text.length or text.charAt(closing_bracket_index) is '{'

    return {left: opening_bracket_index, right: closing_bracket_index} if opening_bracket_index or closing_bracket_index

  this.remove_unbalanced_tags = (text) ->
    start = 0
    i = 0
    in_tag = false
    while i < text.length
      if not in_tag
        if text.charAt(i) is '{'
          in_tag = true
          start = i++
        else
          if text.charAt(i) is '}'
            text = text[...start] + text[i + 1..]
            i = start = 0
            in_tag = false
          else
            ++i
      else
        if text.charAt(i) is '}'
          in_tag = false
          start = ++i
        else
          if text.charAt(i) is '{'
            text = text[...start] + text[i..]
            i = start = 0
            in_tag = false
          else
            ++i
    text = text[0...start] if in_tag
    text

class AntCat.TaxtEditor.DebugDashboard
  @dashboard_id: 'antcat_taxteditbox_dashboard'
  constructor: (@taxt_editor) ->
    DebugDashboard.add_html()

  @add_html: ->
    return if $("##{@dashboard_id}").size() > 0
    $("
    <style>
      ##{@dashboard_id} {
        margin-bottom: 8px;
        font-family: monospace;
      }
      ##{@dashboard_id} span.small {
        display: inline-block;
        width: 30px;
      }
      ##{@dashboard_id} span.tiny {
        display: inline-block;
        width: 10px;
      }
      ##{@dashboard_id} span.wide {
      }
    </style>
      ").appendTo('head')

    html = "
    <div id='#{@dashboard_id}'>
      <div class='event'>
        <div class='keyup_mouseup'>
          <span class='value small'></span>
          <span class='type small'></span>
        </div>
      </div>
      <div class='status'>"
    for status_when in ['before', 'after']
      html += "
        <div class='#{status_when}'>
          <span class='start_enclosing_tag small'></span>
          <span class='start_selection small'></span>
          <span class='end_selection small'></span>
          <span class='end_enclosing_tag small'></span>
          val:
          [<span class='value'></span>]
          sel:
          [<span class='selection'></span>]
          <span class='is_tag_selected tiny'></span>
        </div>"
    html += "
      </div>
    </div>"
    $(html).prependTo('body')

  show_status: (before_or_after) =>
    $status_panel = $ "##{DebugDashboard.dashboard_id} .status .#{before_or_after}"

    value = @taxt_editor.value()
    start_selection = @taxt_editor.start()
    end_selection = @taxt_editor.end()
    enclosing_tag = AntCat.TaxtEditor.enclosing_tag_indexes value, start_selection

    $('.value', $status_panel).text value

    text = "{#{enclosing_tag.left}" if enclosing_tag?.left
    $('.start_enclosing_tag', $status_panel).text text ? ''

    text = "#{enclosing_tag.right}}" if enclosing_tag?.right
    $('.end_enclosing_tag', $status_panel).text text ? ''

    $('.start_selection', $status_panel).text start_selection
    $('.end_selection', $status_panel).text end_selection
    $('.selection', $status_panel).text @taxt_editor.value()[start_selection...end_selection]
    $('.is_tag_selected', $status_panel).text if @taxt_editor.is_tag_selected() then 'T' else 'F'

  show_event: (event) =>
    $event_panel = $ "##{DebugDashboard.dashboard_id} .event .keyup_mouseup"
    $('.type', $event_panel).text event.type
    $('.value', $event_panel).text event.which
