{$} = require 'atom-space-pen-views'

describe "EncodingSelector", ->
  [editor, editorView] =  []

  beforeEach ->
    jasmine.attachToDOM(atom.views.getView(atom.workspace))

    waitsForPromise ->
      atom.packages.activatePackage('status-bar')

    waitsForPromise ->
      atom.packages.activatePackage('encoding-selector')

    waitsForPromise ->
      atom.workspace.open('sample.js')

    runs ->
      editor = atom.workspace.getActiveTextEditor()
      editorView = atom.views.getView(editor)

  describe "when encoding-selector:show is triggered", ->
    it "displays a list of all the available encodings", ->
      atom.commands.dispatch(editorView, 'encoding-selector:show')
      encodingView = $(atom.views.getView(atom.workspace)).find('.encoding-selector').view()
      expect(encodingView).toExist()
      expect(encodingView.list.children('li').length).toBeGreaterThan 1

  describe "when an encoding is selected", ->
    it "sets the new encoding on the editor", ->
      atom.commands.dispatch(editorView, 'encoding-selector:show')
      encodingView = $(atom.views.getView(atom.workspace)).find('.encoding-selector').view()
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
        atom.commands.dispatch(editorView, 'encoding-selector:show')
        encodingView = $(atom.views.getView(atom.workspace)).find('.encoding-selector').view()
        encodingView.confirmed(id: 'detect')
        encodingChangeHandler.reset()

      waitsFor ->
        encodingChangeHandler.callCount is 1

      runs ->
        expect(editor.getEncoding()).toBe 'utf8'

  describe "encoding label", ->
    [encodingStatus] = []

    beforeEach ->
      runs ->
        encodingStatus = document.querySelector('encoding-selector-status')
        expect(encodingStatus).toExist()

    it "displays the name of the current encoding", ->
      expect(encodingStatus.encodingLink.textContent).toBe 'UTF-8'

    it "hides the label when the current encoding is null", ->
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
        atom.commands.add('atom-text-editor', 'encoding-selector:show', eventHandler)
        encodingStatus.click()
        expect(eventHandler).toHaveBeenCalled()

    describe "when the package is deactivated", ->
      it "removes the view", ->
        atom.packages.deactivatePackage('encoding-selector')

        expect(encodingStatus.parentElement).toBeNull()
