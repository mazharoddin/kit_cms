class Status < ActiveRecord::Base
  has_many :pages
  attr_accessible :system_id, :name, :value, :user_id, :order_by, :is_default, :is_published, :is_stub

  @@statuses = {}

  def Status.method_missing(m, *args, &block)
    if m=~/(.*)_status$/
      status = $1
      sys_id = args[0]
      key = "#{sys_id}.#{status}"
      s = @@statuses[key]
      return s if s
      @@statuses[key] = Status.sys(sys_id).where("is_#{status} = 1").first
    else
      super(m, args, block)
    end
  end
end
