module Excursion
  class DatastoreError < Error; end
  class NoDatastoreError < DatastoreError; end
  class InvalidDatastoreError < DatastoreError; end

  class DatastoreConfigurationError < DatastoreError; end
end
