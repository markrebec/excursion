module Excursion
  class MemcacheError < Error; end
  class MemcacheServerError < MemcacheError; end
  class MemcacheConfigurationError < MemcacheError; end
end
