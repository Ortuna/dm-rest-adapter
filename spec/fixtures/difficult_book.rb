class DifficultBook
  include DataMapper::Resource

  storage_names[:default] = 'booksies'

  property :id,           Serial
  property :created_at,   DateTime
  property :title,        String
  property :author,       String
  property :publisher_id, Integer, :field => 'pid'
  property :comment,    String, field: "comment_crazy_mapping"  
  belongs_to :publisher
  has n, :chapters
  has 1, :cover, 'BookCover'
  has n, :vendors, :nested => true
end
