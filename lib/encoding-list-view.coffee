{SelectListView} = require 'atom'

# View to display a list of encodings to use in the current editor.
module.exports =
class EncodingListView extends SelectListView
  initialize: (@editor) ->
    super

    @addClass('encoding-selector from-top overlay')
    @list.addClass('mark-active')

    @currentEncoding = @editor.getEncoding()

    @subscribe this, 'encoding-selector:show', =>
      @cancel()
      false

    @setItems(@getEncodings())

  getFilterKey: ->
    'name'

  viewForItem: (encoding) ->
    element = document.createElement('li')
    element.classList.add('active') if encoding.id is @currentEncoding
    element.textContent = encoding.name
    element.dataset.encoding = encoding.id
    element

  confirmed: (encoding) ->
    @cancel()
    @editor.setEncoding(encoding.id)

  attach: ->
    @storeFocusedElement()
    atom.workspaceView.append(this)
    @focusFilterEditor()

  getEncodings: ->
    [
      {
        id: 'utf8'
        name: 'UTF-8'
      }
      {
        id: 'win1251'
        name: 'Cyrillic (Windows 1251)'
      }
    ]
