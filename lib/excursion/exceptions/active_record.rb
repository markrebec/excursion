module Excursion
  class ActiveRecordError < Error; end
  class TableDoesNotExist < ActiveRecordError; end
end
