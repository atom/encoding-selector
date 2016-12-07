fs = require 'fs'
{SelectListView} = require 'atom-space-pen-views'

# View to display a list of encodings to use in the current editor.
module.exports =
class EncodingListView extends SelectListView
  initialize: (@encodings) ->
    super

    @panel = atom.workspace.addModalPanel(item: this, visible: false)
    @addClass('encoding-selector')
    @list.addClass('mark-active')

  getFilterKey: ->
    'name'

  viewForItem: (encoding) ->
    element = document.createElement('li')
    element.classList.add('active') if encoding.id is @currentEncoding
    element.textContent = encoding.name
    element.dataset.encoding = encoding.id
    element

  toggle: ->
    if @panel.isVisible()
      @cancel()
    else if @editor = atom.workspace.getActiveTextEditor()
      @attach()

  destroy: ->
    @panel.destroy()

  cancelled: ->
    @panel.hide()

  confirmed: (encoding) ->
    @cancel()

    if encoding.id is 'detect'
      @editor.detectEncoding()
    else
      @editor.setEncoding(encoding.id)

  addEncodings: ->
    @currentEncoding = @editor.getEncoding()
    encodingItems = []

    if fs.existsSync(@editor.getPath())
      encodingItems.push({id: 'detect', name: 'Auto Detect'})

    for id, names of @encodings
      encodingItems.push({id, name: names.list})
    @setItems(encodingItems)

  attach: ->
    @storeFocusedElement()
    @addEncodings()
    @panel.show()
    @focusFilterEditor()
