# Options: edit_selector, display_selector
# Panel options: click_on_display, click_on_icon, highlight, parent_form

class AntCat.ReferenceFieldPanel extends AntCat.Panel

  initialize: (@element) =>
    AntCat.log 'ReferenceFieldPanel initialize: no @element' unless @element && @element.size() == 1
    @setup_sections()
    @setup_edit()

  setup_sections: =>
    edit_selector = @options.edit_selector || '> .edit'
    @edit = @element.find edit_selector
    AntCat.log 'ReferenceFieldPanel setup_sections: no @edit' unless @edit.size() == 1

    display_selector = @options.display_selector || '> .display'
    @display = @element.find display_selector
    AntCat.log 'ReferenceFieldPanel setup_sections: no @display' unless @display.size() == 1

  setup_edit: =>
    @display.click @start_editing
    $edit_icon = @element.find '.edit_icon'
    @element
      .mouseenter(=> $edit_icon.show() unless @is_editing())
      .mouseleave(=> $edit_icon.hide())

  start_editing: =>
    @save_panel()
    @show_form()
    false

  show_form: =>
    @display.hide()
    @edit.show()
    @form().open()

  hide_form: =>
    @edit.hide()
    @display.show()
    @form().close()

  is_editing: =>
    @edit.is ':visible'
