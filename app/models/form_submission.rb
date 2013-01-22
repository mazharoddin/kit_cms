class FormSubmission  < KitIndexed

  FormSubmission.do_indexing :FormSubmission, [
    {:name=>"id", :index=>:not_analyzed, :include_in_all=>false},
    {:name=>"location", :type => 'geo_point', :as=>'"#{self.lat ? self.lat : 0}, #{self.lon ? self.lon : 0}"' },
    {:name=>"created_at", :index=>:not_analyzed, :include_in_all=>false},
    {:name=>"marked", :as=>"self.marked ? self.marked : 0", :index=>:not_analyzed, :include_in_all=>false},
    {:name=>"system_id", :index=>:not_analyzed, :include_in_all=>false},
    {:name=>"email", :boost=>50 , :as=>"self.user ? self.user.email : ''"},
    {:name=>"form_id", :boost=>100, :as=>"self.form_id", :include_in_all=>false},
    {:name=>"form", :boost=>100, :as=>"self.form.title", :include_in_all=>false},
    {:name=>"data", :analyzer => 'snowball', :type=>"object", :as=>"self.form_submission_fields.map {|fsf| {fsf.form_field.code_name => fsf.index_value}}"},
    {:name=>"visible", :index=>:not_analyzed}
  ]

  belongs_to :user
  has_many :form_submission_fields, :include=>:form_field, :dependent=>:destroy
  belongs_to :form
  attr_accessor :kit_session_id

  after_create :create_engagement

  def geo_code
    first = true
    self.form.form_fields.where("geo_code_from_fields is not null and geo_code_from_fields <> ''").order(:display_order).each do |geo_field|
      entered_location = []
      geo_field.geo_code_from_fields.split('|').each do |field_id|
        entered_location << field_value_by_id(field_id)
      end
      location = Geocoder.search(entered_location.join(', '))
      if location.size>0
        location_field = FormSubmissionField.new(:form_field_id=>geo_field.id, :form_submission_id=>self.id, :system_id=>self.system_id)
        location_field.value = location[0].address
        location_field.lat = location[0].latitude
        location_field.lon = location[0].longitude
        location_field.save

        if first
          self.lat = location[0].latitude
          self.lon = location[0].longitude
          self.save
        end
      end
    end

  end

  def create_engagement
    KitEngagement.create(:kit_session_id=>self.kit_session_id, :system_id=>self.system_id, :engage_type=>"Form Submission", :value=>"/admin/forms/#{self.id}/list") if self.kit_session_id
  end

  def can_see?(user)
    return can?('visible', user)
  end

  def can_edit?(user)
    return can?('editable', user)
  end

  def can_delete?(user)
    can_edit?(user)
  end

  def fields
    self.form_submission_fields
  end 

  def field_value_by_id(id)
    self.fields.where(:form_field_id=>id).first.value
  end

  def field_by_name(name)
    self.fields.joins(:form_field).where("form_fields.code_name = '#{name}'").first
  end

  def method_missing(meth, *args, &block)
    if meth =~ /^(.+)\=$/
      field_name = $1
      setter = true
    else
      field_name = meth # might not be, but no harm
      setter = false
    end
    field_name = field_name.to_s if field_name.instance_of?(Symbol)
    field_name.gsub!('_','-') if field_name
    field_name = field_name.to_sym if field_name.instance_of?(String)
    self.fields.each do |field|
      next unless field.form_field
      if setter && field.form_field.code_name.to_sym == field_name.to_sym
        field.value = args[0]
        field.save
        return field.value
      end
      if !setter && field.form_field.code_name.to_sym == field_name
        return field.value
      end
    end
    super
  end

  private 

  def can?(which, user)
    return true if self.form.respond_to?("public_#{which}") && self.form.send("public_#{which}")==1
    return true if user && user.admin?
    return true if user && self.form.send("user_#{which}")==1
    return true if user && self.form.send("owner_#{which}")==1 && self.user_id = user.id
    return false
  end
end
