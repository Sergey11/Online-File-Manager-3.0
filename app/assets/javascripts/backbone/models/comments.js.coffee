class FileManager.Models.Comment extends Backbone.Model
  paramRoot: 'comment'

class FileManager.Collections.CommentsCollection extends Backbone.Collection
  model: FileManager.Models.Comment

  initialize: (opts) ->
    @commentable_type = opts.commentable_type
    @commentable_id = opts.commentable_id
    console.log(@commentable_type)
    console.log(@commentable_id)



  url: ->
    '/api/v3/' + @commentable_type + "/" + @commentable_id + "/comments"
