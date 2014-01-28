FileManager.Views.Folders ||= {}

class FileManager.Views.Folders.FoldersView extends Backbone.View
  template: JST["backbone/templates/folders/folders"]

  initialize: ->
    @collection = new FileManager.Collections.FoldersCollection()
    @collection.fetch()
    @collection.on('reset', @render, this)

  render: ->
    @collection.each (folder) ->
      view = new FileManager.Views.Folders.FolderView(model: folder)
      $('#filelist-t').append(view.render().el)