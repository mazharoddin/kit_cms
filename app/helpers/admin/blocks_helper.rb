module Admin::BlocksHelper
  def db_choice(name)
    klass = Object::const_get(name.singularize.camelize)
    field_name = name=='form' ? :title : :name

    options_from_collection_for_select(klass.order(field_name).all, :id, field_name) 
  end

  @@db_choices = [ 'gallery','snippet','menu','form', 'ad_unit', 'ad_zone' ]

  def is_db_choice?(type)
    @@db_choices.include?(type.singularize)  
  end
end
