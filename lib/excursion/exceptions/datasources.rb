module Excursion
  class DatasourceError < Error; end
  class NoDatasourceError < DatasourceError; end
  class InvalidDatasourceError < DatasourceError; end

  class DatasourceConfigurationError < DatasourceError; end
end
