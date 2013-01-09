class BlockInstance < ActiveRecord::Base
  belongs_to :page
  belongs_to :user
  belongs_to :block
  
  validates :instance_id, :presence=>true, :length=>{:minimum=>1, :maximum=>200}

  def display_version
    return "Current" if self.version==0
    return "Draft" if self.version==-1
    return "Autosave" if self.version==-2
    return self.version
  end

  def prompt
    body = self.block.body

    if body =~ /\[\[#{self.field_name}\:[^\:]+\:([^\:]+)\]\]/
      return $1
    else
      field_name.titleize
    end
  end

  def render
    return "[No block definition #{self.block_id}]" unless self.block

    self.block.body.gsub(/\[\[([^\:]+)\:([^\:]+)\:[^\]]+\]\]/) do
      bi = self.page.get_block_instances(self.instance_id, self.version, $1, self.block_id)
      return "[No block instances]" unless bi
      block_instance = bi.first
      if block_instance && block_instance.field_value
        if $2 == "friendly"
          block_instance.field_value.friendly_format 
        else
          block_instance.field_value
        end
      else
        "[Missing value '#{$1}']"
      end
    end
  end
end
