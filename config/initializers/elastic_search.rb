app_name = Rails.configuration.es_index_name rescue 'kit'

Tire::Model::Search.index_prefix "kit_#{app_name}".downcase

Tire.configure { logger 'log/search.log', :level => 'info' }


