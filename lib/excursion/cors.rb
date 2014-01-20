module Excursion
  module CORS
    def self.included(base)
      base.send :before_filter, :cors_headers if Excursion.configuration.enable_cors
    end

    def cors_match?(origin, host)
      host.is_a?(Regexp) ? origin.match(host) : origin.downcase == host.downcase
    end

    def cors_whitelisted?(origin)
      if Excursion.configuration.cors_whitelist == :pool
        Excursion::Pool.all_applications.values.map { |app| app.default_url_options[:host] }.any? { |cw| cors_match? origin, cw }
      else
        Excursion.configuration.cors_whitelist.nil? || Excursion.configuration.cors_whitelist.any? { |cw| cors_match? origin, cw }
      end
    end

    def cors_blacklisted?(origin)
      !Excursion.configuration.cors_blacklist.nil? && !Excursion.configuration.cors_blacklist.any? { |cb| cors_match? origin, cb }
    end

    def cors_headers
      origin = request.headers['Origin'] || request.headers['HTTP_ORIGIN']
      if !origin.nil? && cors_whitelisted?(origin) && !cors_blacklisted?(origin)
        headers['Access-Control-Allow-Origin'] = request.headers['Origin']
        headers['Access-Control-Allow-Methods'] = Excursion.configuration.cors_allow_methods.join(',')
        headers['Access-Control-Allow-Headers'] = Excursion.configuration.cors_allow_headers.join(', ')
        headers['Access-Control-Allow-Credentials'] = Excursion.configuration.cors_allow_credentials.to_s
        headers['Access-Control-Max-Age'] = Excursion.configuration.cors_max_age.to_s
      end
    end
  end
end
