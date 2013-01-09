module FormHelper


  def text_captcha_entry
      question, answers = Form.captcha_question(500)
      "<div class='q_a'>
         <input type='hidden' name='q_q' value='#{answers}'/>
          <label>#{question}</label> 
          <input type='text' name='q_a' value='' class='captcha'>
       </div>".html_safe
  end


  def text_captcha_qa
    return Form.captcha_question(500)
  end

  def show_tree(data)
    a = data.split("|")
    options = []
   
    op = "<table class='loosen'>"

    a.each do |aa|
      first = true
      bb = aa.split('~')

      op += "<tr><td valign='top'>#{bb[0]} &rarr;</td><td>"

      for i in 1..bb.length-1
        op += bb[i]
        op += "<br/>"
      end

      op += "</td></tr>"
    end    
    op += "</table>"
    op.html_safe
  end

  def select_tree(field_id, data, field_options, value = nil)
  # sample: Test1\BlahA\BlahB\BlahC|Test2\BloopA\BloopB
  # value: if present, of the form x:y 
    return "no values" unless data
    a = data.split("|")
    options = []

    parent_value = nil
    child_value = nil
    parent_value, child_value = value.split(':') if value
   
    op = '<script type="text/javascript">'
    op += "var data_#{field_id} = {"
    a.each do |parent|
      first = true
      parent.split('~').each do |v|
        v.strip!
        if first
          op += " '#{v}' : ["
          options << v
          first = false
        else
          op += '"' + v + '",'
        end
      end
      op += '],'
    end

    op += "};"
    op += "$(document).ready(function() {"
    op += "$('##{field_id}_parent').bind('change', function() {"
    op += "select_change_parent('#{field_id}_parent', '#{field_id}', data_#{field_id}, \"#{child_value}\");"
    op += "});"
    op += "select_change_parent('#{field_id}_parent', '#{field_id}', data_#{field_id}, \"#{child_value}\");"
    op += "});"
    op += "</script>";

    op += select_tag("#{field_id}_parent", options_for_select(options, parent_value), field_options)
    op += select_tag(field_id, "", {:style=>"margin-left: 20px;"})
    return op.html_safe
  end

  def html_options(type)
    hash = {}
    type.html_options.split('|').each do |ss|
      name,value = ss.split('=')
      hash[name] = value
    end
    return hash
  end
end
