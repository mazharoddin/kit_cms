require 'yaml'
require 'net/http'
require 'digest/md5'

class Form < ActiveRecord::Base
  has_many :form_fields, :dependent => :destroy, :order=>:display_order
  has_many :form_field_groups, :order=>:order_by
  has_many :form_submissions, :dependent => :destroy

  has_many :ungrouped_form_fields, :class_name=>"FormField", :conditions=>"form_fields.form_field_group_id is null"  
  validates :title, :uniqueness=>{:scope=>:system_id}, :presence=>true
  validates :url, :uniqueness=>true, :allow_blank=>true


  def geo_codeable_fields
    self.form_fields.joins(:form_field_type).where("form_field_types.field_type in ('line','paragraph','select','multiselect')").all
  end

  def include_stylesheets
    return ["application"] if self.stylesheets.is_blank?
    return self.stylesheets.split(',').uniq
  end

  def field_by_name(name)
    self.form_fields.each do |ff|
      if ff.code_name == name.to_s
        return ff
      end
    end
    return nil
  end

  def record(id)
    self.form_submissions.sys(self.system_id).where(:id=>id).includes({:form=>{:form_field_groups=>:form_fields}}).first
  end

  # field_conditions => [ {:name=>"field_name", :comparator=>"=", :value=>"Test", :connective=>"and"}, { ... } ]
  #
  def records(options = {})

    field_conditions = options[:field_conditions] 
    r = self.form_submissions.includes(:form_submission_fields)
    r = r.where(:visible => 1) if options[:only_visible]

    r = r.where(options[:where]) if options[:where]

    if options[:enforce_permissions] 
      if self.public_visible==0
        if self.user_visible==0
          if self.owner_visible==0
            return []
          else
            r = r.where("form_submissions.user_id = #{options[:user_id]}")
          end
        else
          if options[:user_id]==nil
            return []
          end
        end
      end
    end
    if field_conditions
      conditions = {}

      if field_conditions.is_a?(Array)
        field_conditions.each do |field_condition|
          field_condition[:connective] ||= "and"
          that_field = self.field_by_name(field_condition[:name])
          conditions[that_field.id] = [field_condition[:comparator], field_condition[:value], field_condition[:connective]] if that_field
        end
      elsif field_conditions.is_a?(Hash) 
        field_conditions.each do |field_name, field_value|
          that_field = self.field_by_name(field_name)
          conditions[that_field.id] = ['=', field_value, "and"]
        end
      else
        raise "record conditions can be a hash of equalities, or an array of {:name, :value, :comparator, [:connective]} hashes"
      end
      alias_index = 0
      conditions.each do |field_id, field_comparison|
        alias_index += 1
        r = r.joins("inner join form_submission_fields fsf#{alias_index} on fsf#{alias_index}.form_submission_id = form_submissions.id and fsf#{alias_index}.form_field_id = #{field_id}")
      end
      alias_index = 0
      where_clause = " (1=1) "
      bind_values = {}
      conditions.each do |field_id, field_comparison|
        alias_index += 1
        where_clause += " #{field_comparison[2]} fsf#{alias_index}.value #{field_comparison[0]} :field_#{field_id} "
        bind_values["field_#{field_id}".to_sym] = field_comparison[1]
      end
      r = r.where(where_clause, bind_values)
    end

    if options[:order_by]
      options[:order_by] = [ options[:order_by] ] if options[:order_by].is_a?(String)
      sorting_index = 0
      options[:order_by].each do |order_by|
        that_field = self.field_by_name(order_by)
        sorting_index += 1
        r = r.joins("inner join form_submission_fields fsf_sort#{sorting_index} on fsf_sort#{sorting_index}.form_submission_id = form_submissions.id and fsf_sort#{sorting_index}.form_field_id = #{that_field.id}")
        r = r.order("fsf_sort#{sorting_index}.value") 
      end
    end

    if options[:group_values]
      that_field = self.field_by_name(options[:group_values])
      r = r.joins("inner join form_submission_fields fsf_grouping on fsf_grouping.form_submission_id = form_submissions.id and fsf_grouping.form_field_id = #{that_field.id}")
      r = r.count(:group=>"fsf_grouping.value", :order=>"count_all desc")
    end


    if options[:random]
      r = r.limit(1)
      r = r.order(:id)
      max_id = self.form_submissions.maximum("form_submissions.id")
      min_id = self.form_submissions.minimum("form_submissions.id")
      results = []
      for int in 1..options[:random]
        id = rand(max_id-min_id) + min_id - 1
        s = r.clone
        s = s.where("form_submissions.id >= #{id}")
        results += s.all
      end
      return results
    else
      return r
    end
  end

  def Form.debar_counts(data)
    values = {}
    data.each do |name, count|
      name.split('|').each do |nm|
        values[nm] = (values[nm] || 0) + count
      end
    end

    return values
  end

  @@captcha_questions = [] 
  def self.load_captcha_questions
    question, answers = Form.get_textcaptcha_qa
    a = [question, answers]
    @@captcha_questions << a 
    return a
  end

  def self.captcha_question(cached_quantity = 100)
    if  @@captcha_questions.size < cached_quantity
      logger.debug "Currently have #{@@captcha_questions.size} captcha questions, loading another one"
      return Form.load_captcha_questions
    end
    return @@captcha_questions[rand(l).to_i]
  end

  def self.get_textcaptcha_qa
    xml   = Net::HTTP.get(URI::Parser.new.parse("http://textcaptcha.com/api/7zsxcgrbaacc4cs4swsswk4sk863uwld"))
    if xml.empty?
      raise Textcaptcha::BadResponse
    else
      parsed_xml = ActiveSupport::XmlMini.parse(xml)['captcha']
      spam_question = parsed_xml['question']['__content__']
      if parsed_xml['answer'].is_a?(Array)
        spam_answers = encrypt_answers(parsed_xml['answer'].collect { |a| a['__content__'] })
      else
        spam_answers = encrypt_answers([parsed_xml['answer']['__content__']])
      end

      return spam_question, spam_answers
    end
  end

  def self.encrypt_answers(answers)
    answers.map { |answer| encrypt_answer(answer) }.join('-')
  end

  def self.encrypt_answer(answer)
    BCrypt::Engine.hash_secret(answer, "$2a$10$YCymaxgU1LZq5Tij07wvOu", 3)
  end

  def self.md5_answer(answer)
    Digest::MD5.hexdigest(answer.to_s.strip.mb_chars.downcase)
  end

  def self.validate_captcha_answer(answer, answers)
    (answer && answers) ? answers.split('-').include?(encrypt_answer(md5_answer(answer))) : false
  end

  def use_text_captcha?(request, user, even_if_logged_in = false)
    country = IpCountry.country_from_ip(request.remote_ip)
    risk = country ? country.risk : 10
    use_captcha = (user==nil || even_if_logged_in) && Preference.get_cached(self.system_id, "use_captcha")=='true' && (risk > self.use_captcha_above_risk)
    logger.debug "** Use Text Captcha? #{user==nil ? 'Not logged in user' : 'User'}, Country #{country ? country.name : 'unknown'} Risk #{country ? country.risk : 'unknown'}, Form Risk #{self.use_captcha_above_risk}, Even if logged in #{even_if_logged_in}, Use Captcha #{Preference.get(self.system_id, 'use_captcha')} Using Captcha: #{use_captcha}"
    return use_captcha
  end

  def text_captcha_entry
      question, answers = Form.captcha_question(500)
      "<div class='q_a'>
         <input type='hidden' name='q_q' value='#{answers}'/>
          <label>#{question}</label> 
          <input type='text' name='q_a' value='' class='captcha'>
       </div>".html_safe

  end
end
