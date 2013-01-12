class Help < KitIndexed

   Help.do_indexing :Help, [
      {:name=>"id", :index=>:not_analyzed, :include_in_all=>false},
      {:name=>"name", :boost=>100, :exclude_user=>true},
      {:name=>"path", :boost=>50, :exclude_user=>true},
      {:name=>"body"}
   ]
  
end
