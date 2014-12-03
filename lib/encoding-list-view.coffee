fs = require 'fs'
{SelectListView} = require 'atom-space-pen-views'

# View to display a list of encodings to use in the current editor.
module.exports =
class EncodingListView extends SelectListView
  initialize: (@editor, encodings) ->
    super

    @addClass('encoding-selector from-top overlay')
    @list.addClass('mark-active')

    @currentEncoding = @editor.getEncoding()

    @subscribe this, 'encoding-selector:show', =>
      @cancel()
      false

    encodingItems = []

    if fs.existsSync(@editor.getPath())
      encodingItems.push({id: 'detect', name: 'Auto Detect'})

    for id, names of encodings
      encodingItems.push({id, name: names.list})
    @setItems(encodingItems)

  getFilterKey: ->
    'name'

  viewForItem: (encoding) ->
    element = document.createElement('li')
    element.classList.add('active') if encoding.id is @currentEncoding
    element.textContent = encoding.name
    element.dataset.encoding = encoding.id
    element

  detectEncoding: ->
    filePath = @editor.getPath()
    return unless fs.existsSync(filePath)

    jschardet = require 'jschardet'
    iconv = require 'iconv-lite'
    fs.readFile filePath, (error, buffer) =>
      return if error?

      {encoding} =  jschardet.detect(buffer) ? {}
      encoding = 'utf8' if encoding is 'ascii'
      return unless iconv.encodingExists(encoding)

      encoding = encoding.toLowerCase().replace(/[^0-9a-z]|:\d{4}$/g, '')
      @editor.setEncoding(encoding)

  confirmed: (encoding) ->
    @cancel()

    if encoding.id is 'detect'
      @detectEncoding()
    else
      @editor.setEncoding(encoding.id)

  attach: ->
    @storeFocusedElement()
    atom.workspaceView.append(this)
    @focusFilterEditor()
