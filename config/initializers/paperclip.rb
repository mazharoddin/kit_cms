attachment_virtual_path = "/system/:system_id/:class/:attachment/:id_partition/:id/:code/:style/:basename.:extension"
attachment_real_path = ":rails_root/public" + attachment_virtual_path


Paperclip::Attachment.default_options.merge!(
  :path=>attachment_real_path, 
  :url => attachment_virtual_path
)

Paperclip.interpolates :code do |attachment, style|
  secret = 'Generic'
  hash = Digest::MD5.hexdigest("--#{attachment.class.name}--#{attachment.instance.id}--#{secret}--")
  hash[0..8]
end

Paperclip.interpolates :system_id do |attachment, style|
  "#{attachment.instance.system_id}"
end
