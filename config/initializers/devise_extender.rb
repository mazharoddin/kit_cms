module DeviseExtender

  attr_accessor :kit_template

  def render(options = {})
   
    unless options.is_a?(Symbol) 
      if options[:partial]
        name = options[:partial]
      else 
        name = options[:name]
      end
    else
      name = options.to_s
      options = {}
    end

    custom_template = PageTemplate.get_custom_template(_sid, kit_template ? kit_template : name, request)
    if custom_template
      options[:type] = custom_template.template_type || 'erb'
      options[:inline] = custom_template.body
      options[:layout] = custom_template.layout.path

      super options
    else
      super name, options
    end
  end


  def stylesheets
    custom_template = PageTemplate.get_custom_template(_sid, kit_template ? kit_template : name, request)
    if custom_template
      return custom_template.layout.stylesheets.split(',').uniq
    else
      return ["application"]
    end
  end
end
