module Admin::FormHelper

  def form_permissions(form)
    cans = []

    [["creatable", "create"], ["visible", "see"],["editable", "edit"]].each do |perm|
      [["public", "Everyone"],["user", "Registered users"],["owner", "The creator"]].each do |group|
        if form.send("#{group[0]}_#{perm[0]}")==1
          cans << "#{group[1]} can #{perm[1]} #{group[0]=='owner' ? 'their own' : ''} submissions"
          break
        end if form.respond_to?("#{group[0]}_#{perm[0]}")
      end
    end

    return cans.join("<br/>").html_safe
  end
end
