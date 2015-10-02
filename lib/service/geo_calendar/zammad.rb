# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

require 'cache'

class Service::GeoCalendar::Zammad
  def self.location(address)

    # check cache
    cache_key = "zammadgeocalendar::#{address}"
    cache = Cache.get( cache_key )
    return cache if cache

    # do lookup
    host = 'https://geo.zammad.com'
    if address
      url  = "/calendar?ip=#{CGI.escape address}"
    else
      url  = '/calendar'
    end
    data = {}
    begin
      response = UserAgent.get(
        "#{host}#{url}",
        {},
        {
          json: true,
          open_timeout: 2,
          read_timeout: 4,
        },
      )
      if !response.success? && response.code.to_s !~ /^40.$/
        fail "ERROR: #{response.code}/#{response.body}"
      end

      data = response.data

      Cache.write( cache_key, data, { expires_in: 30.minutes } )
    rescue => e
      Rails.logger.error "#{host}#{url}: #{e.inspect}"
      Cache.write( cache_key, data, { expires_in: 1.minutes } )
    end
    data
  end
end
