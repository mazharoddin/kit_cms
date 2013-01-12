class Admin::ContentController < AdminController

  layout 'cms-boxed'

  def match
    @page = Page.where(:id=>params[:id]).sys(_sid).first
    if params[:words]
      words = params[:words]
    else
      content = ''
      @page.current_content.each { |cc| content += ' ' + cc.value }
    
      content.gsub!(/<[^<>]*>/, "") 
      @histogram = Word.histogram(content, {:stem=>true, :de_stem=>true, :threshold=>1})
      words = []
      @histogram.each do |k,v|
        words << k
        break if words.size>10
      end

      if words.size==0
        render :text=>"You must create and save some content before you can see related content." and return
      end
    end

    indexes = [ "pages", "topic_posts", "topic_threads" ] 
    search = Tire.search indexes.map { |name| "kit_#{app_name}_#{name}"}.join(',') do
      query do
        string words.join(' ')
      end
      size 10
    end

    @pages = search.results
    render :layout=>false
  end

  def analyse
    @page = Page.where(:id=>params[:id]).sys(_sid).first
    
    content = ''
    @page.current_content.each { |cc| content += ' ' + cc.value }
    
    content.gsub!(/<[^<>]*>/, "") 
    @wordcount = content.split(' ').size
    @sentencecount = content.split('.').size

    @histogram = Word.histogram(content, {:stem=>true, :de_stem=>true, :threshold=>1})
  end
end
