module Admin::DashboardHelper

  def highlight_app(t)
    op = []
    return "" unless t
    t.split("\n").each do |line|
      opentag = nil
      closetag = nil
      if line =~ /^\//
        unless line =~ /\/vendor\// || line =~ /\/gems\/passenger/
          opentag = "<span style='background-color: #FFFFDD'>"
          closetag = "</span>"
        end
      end

      op << opentag if opentag
      op << line
      op << closetag if closetag
      op << "<br/>"
    end
   
    op.join("\n").html_safe
  end
end
