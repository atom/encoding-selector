encodingStatusView = null

module.exports =
  activate: ->
    atom.workspaceView.command('encoding-selector:show', createEncodingListView)
    atom.packages.once('activated', createEncodingStatusView)

  deactivate: ->
    encodingStatusView?.destroy()

createEncodingListView = ->
  editor = atom.workspace.getActiveEditor()
  if editor?
    EncodingListView = require './encoding-list-view'
    view = new EncodingListView(editor)
    view.attach()

createEncodingStatusView = ->
  {statusBar} = atom.workspaceView
  if statusBar?
    EncodingStatusView = require './encoding-status-view'
    encodingStatusView = new EncodingStatusView()
    encodingStatusView.initialize(statusBar)
    encodingStatusView.attach()
