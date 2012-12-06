class Book
  include DataMapper::Resource
  storage_names[:default] = 'livre'
  property :id,         Serial
  property :created_at, DateTime
  property :title,      String
  property :author,     String
  property :comment,    String, field: "comment_crazy_mapping"
end
