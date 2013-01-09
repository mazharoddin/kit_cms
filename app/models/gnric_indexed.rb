class GnricIndexed < ActiveRecord::Base

  self.abstract_class = true
  @columns = []

  include Tire::Model::Search
  include Tire::Model::Callbacks

  def self.do_indexing(model, index_definition)
    $gnric_indexes[model.to_sym] = index_definition
    option_fields = [ :boost, :index, :as, :include_in_all, :type ]
    index_definition.each do |ic|
      options = {}
      option_fields.collect { |f| options[f] = ic[f] if ic[f] }
      indexes ic[:name], options
    end
  end

  def self.indexed_columns(model)
    $gnric_indexes[model.to_sym]
  end

  def self.paginate(options = {})
    page(options[:page]).per(options[:per_page])
  end
end

