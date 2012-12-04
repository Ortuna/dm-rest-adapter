class DifficultBook
  include DataMapper::Resource

  storage_names[:default] = 'books'

  property :id,           Serial
  property :created_at,   DateTime
  property :title,        String
  property :author,       String
  property :publisher_id, Integer, :field => 'pid'
  
  belongs_to :publisher
  has n, :chapters
  has 1, :cover, 'BookCover'
  has n, :vendors, :nested => true
end
