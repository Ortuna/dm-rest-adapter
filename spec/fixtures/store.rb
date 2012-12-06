class Store
  include DataMapper::Resource

  storage_names[:test] = 'Store__c'

  def self.default_repository_name
    :test
  end
  
  property :id, Serial, field: "id__c", key: true, required: false, lazy: false

  property :name, Text, field: "name__c", key: false, required: false, lazy: false
  
  property :phone, Text, field: "phone__c", key: false, required: false, lazy: false
    
  property :street, Text, field: "street__c", key: false, required: false, lazy: false
  property :city, Text, field: "city__c", key: false, required: false, lazy: false
  property :state, Text, field: "state__c", key: false, required: false, lazy: false
  property :zip, Text, field: "zip__c", key: false, required: false, lazy: false
  
  property :latitude, Float, field: "latitude__c", key: false, required: false, lazy: false
  property :longitude, Float, field: "longitude__c", key: false, required: false, lazy: false
end