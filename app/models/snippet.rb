class Snippet < GnricIndexed
  belongs_to :user

  use_kit_caching

    Snippet.do_indexing :Block, [
      {:name=>:id, :index=>:not_analyzed},
      {:name=>:system_id, :index=>:not_analyzed},
      {:name=>:name, :boost=>100},
      {:name=>:body, :user=>true},
      {:name=>:description},
      {:name=>:created_by, :as=>"user.email"},
      {:name=>:updated_at, :type=>'date', :include_in_all=>false},
    ]

  def self.parse_lines(id, sid)
    s = Snippet.cache_get(sid, id)
    return nil unless s

    return s.body.split(/\r\n/)
  end
    

  def mail_name
    self.name[6..self.name.length]
  end 
end
