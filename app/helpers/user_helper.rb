module UserHelper

  def field_types
    FormFieldType.sys(_sid).where(:hidden=>0).order(:name).all
  end
end
