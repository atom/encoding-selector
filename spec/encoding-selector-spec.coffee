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

      waitsFor ->
        document.body.querySelector('.encoding-selector')

      runs ->
        expect(document.body.querySelectorAll('.encoding-selector li').length).toBeGreaterThan(1)

  describe "when an encoding is selected", ->
    it "sets the new encoding on the editor", ->
      atom.commands.dispatch(editorView, 'encoding-selector:show')

      waitsFor ->
        document.body.querySelector('.encoding-selector')

      runs ->
        encodingListView = atom.workspace.getModalPanels()[0].getItem()
        encodingListView.props.didConfirmSelection({id: 'utf16le'})
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

      waitsFor ->
        document.body.querySelector('.encoding-selector')

      runs ->
        encodingListView = atom.workspace.getModalPanels()[0].getItem()
        encodingListView.props.didConfirmSelection({id: 'detect'})
        encodingChangeHandler.reset()

      waitsFor ->
        encodingChangeHandler.callCount is 1

      runs ->
        expect(editor.getEncoding()).toBe 'utf8'

  describe "encoding label", ->
    [encodingStatus] = []

    beforeEach ->
      waitsFor ->
        encodingStatus = document.querySelector('.encoding-status')
        encodingStatus.offsetHeight > 0

    it "displays the name of the current encoding", ->
      expect(encodingStatus.querySelector('a').textContent).toBe 'UTF-8'

    it "hides the label when the current encoding is null", ->
      spyOn(editor, 'getEncoding').andReturn null
      editor.setEncoding('utf16le')
      waitsFor ->
        encodingStatus.offsetHeight is 0

    describe "when the editor's encoding changes", ->
      it "displays the new encoding of the editor", ->
        expect(encodingStatus.querySelector('a').textContent).toBe 'UTF-8'
        editor.setEncoding('utf16le')
        waitsFor ->
          encodingStatus.querySelector('a').textContent is 'UTF-16 LE'

    describe "when clicked", ->
      it "toggles the encoding-selector:show event", ->
        eventHandler = jasmine.createSpy('eventHandler')
        atom.commands.add('atom-text-editor', 'encoding-selector:show', eventHandler)
        encodingStatus.click()
        expect(eventHandler).toHaveBeenCalled()

    describe "when the package is deactivated", ->
      it "removes the view", ->
        waitsForPromise ->
          Promise.resolve(atom.packages.deactivatePackage('encoding-selector'))
        runs ->
          expect(encodingStatus.parentElement).toBeNull()
