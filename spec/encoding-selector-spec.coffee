path = require 'path'
{$, WorkspaceView, View} = require 'atom'

class StatusBarMock extends View
  @content: ->
    @div class: 'status-bar tool-panel panel-bottom', =>
      @div outlet: 'rightPanel', class: 'status-bar-right'

  attach: ->
    atom.workspaceView.appendToTop(this)

  prependRight: (item) ->
    @rightPanel.append(item)

describe "EncodingSelector", ->
  [editor, editorView] =  []

  beforeEach ->
    atom.workspaceView = new WorkspaceView

    waitsForPromise ->
      atom.packages.activatePackage('encoding-selector')

    waitsForPromise ->
      atom.workspace.open('sample.js')

    runs ->
      editorView = atom.workspaceView.getActiveView()
      {editor} = editorView

  describe "when encoding-selector:show is triggered", ->
    it "displays a list of all the available grammars", ->
      editorView.trigger 'encoding-selector:show'
      encodingView = atom.workspaceView.find('.encoding-selector').view()
      expect(encodingView).toExist()
      encodings = require('../lib/encodings')
      expectedItemCount = Object.keys(encodings).length + 1 # Include Auto Detect
      expect(encodingView.list.children('li').length).toBe expectedItemCount

  describe "when an encoding is selected", ->
    it "sets the new encoding on the editor", ->
      editorView.trigger 'encoding-selector:show'
      encodingView = atom.workspaceView.find('.encoding-selector').view()
      encodingView.confirmed(id: 'utf16le')
      expect(editor.getEncoding()).toBe 'utf16le'

  describe "when Auto Detect is selected", ->
    it "detects the character set and applies that encoding", ->
      encodingChangeHandler = jasmine.createSpy('encodingChangeHandler')
      editor.onDidChangeEncoding(encodingChangeHandler)
      editor.setEncoding('utf16le')

      waitsFor ->
        encodingChangeHandler.callCount is 1

      runs ->
        editorView.trigger 'encoding-selector:show'
        encodingView = atom.workspaceView.find('.encoding-selector').view()
        encodingView.confirmed(id: 'detect')
        encodingChangeHandler.reset()

      waitsFor ->
        encodingChangeHandler.callCount is 1

      runs ->
        expect(editor.getEncoding()).toBe 'utf8'

  describe "encoding label", ->
    [encodingStatus] = []

    beforeEach ->
      atom.workspaceView.statusBar = new StatusBarMock()
      atom.workspaceView.statusBar.attach()
      atom.packages.emit('activated')

      [encodingStatus] = atom.workspaceView.statusBar.rightPanel.children()
      expect(encodingStatus).toExist()

    afterEach ->
      atom.workspaceView.statusBar.remove()
      atom.workspaceView.statusBar = null

    it "displays the name of the current encoding", ->
      expect(encodingStatus.encodingLink.textContent).toBe 'UTF-8'

    it "hides the label when the current encoding is null", ->
      atom.workspaceView.attachToDom()
      spyOn(editor, 'getEncoding').andReturn null
      editor.setEncoding('utf16le')

      expect(encodingStatus).toBeHidden()

    describe "when the editor's encoding changes", ->
      it "displays the new encoding of the editor", ->
        expect(encodingStatus.encodingLink.textContent).toBe 'UTF-8'
        editor.setEncoding('utf16le')
        expect(encodingStatus.encodingLink.textContent).toBe 'UTF-16 LE'

    describe "when clicked", ->
      it "toggles the encoding-selector:show event", ->
        eventHandler = jasmine.createSpy('eventHandler')
        atom.workspaceView.on 'encoding-selector:show', eventHandler
        encodingStatus.click()
        expect(eventHandler).toHaveBeenCalled()

    describe "when the package is deactivated", ->
      it "removes the view", ->
        atom.packages.deactivatePackage('encoding-selector')

        expect(encodingStatus.parentElement).toBeNull()
