class Todo < KitIndexed

   Todo.do_indexing :Todo,  [
    {:name=>"id", :index=>:not_analyzed},
    {:name=>"user", :as=>"user.email"},
    {:name=>"name"},
    {:name=>"description"}
  ]


  belongs_to :user

  after_create :add_activity

  def add_activity
    Activity.add(_sid, "Created to do '#{self.name}'", self.user_id, "To do")
  end
end
