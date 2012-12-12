class BookCover
  include DataMapper::Resource
  def self.default_repository_name
    :test
  end
  property :id,                Serial
  property :difficult_book_id, Integer, :field => 'book_id'
  
  belongs_to :difficult_book
end
