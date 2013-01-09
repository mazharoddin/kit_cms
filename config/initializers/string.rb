include ActionView::Helpers::SanitizeHelper

class String

  def sanitise
    sanitize(self,
             :tags=>%w(table tr td th p br b strong u em i span div pre code quote),
             :attributes=> %w(id) )
  end

  def friendly_format(options={})
    text = self
    text = text.gsub(/http:\/\/(?:www\.)?youtube.com\/watch\?[\S]*v=([0-9a-zA-Z\_\-]{5,15})[^0-9a-zA-Z\_\-]/i, '!YOUTUBE!\1!')  unless options[:strict_markdown] || options[:no_youtube]

    text = text.gsub(/http:\/\/youtu.be\/(\S{5,15})/, '!YOUTUBE!\1!')  unless options[:strict_markdown] || options[:no_youtube]
   
    text = text.gsub(/http:\/\/vimeo.com\/([0-9]{6,9})/, '!VIMEO!\1!') unless options[:strict_markdown] || options[:no_youtube]

    options[:filter_html] ||= false
    options[:filter_styles] ||= true
    options[:autolink] ||= true

    r = RDiscount.new(text)

    options.each do |k,v|
      if r.respond_to?(k.to_sym)
         r.send("#{k.to_s}=", v)
      end
    end
    
    d = r.to_html.gsub(/!YOUTUBE!([0-9a-zA-Z\_\-]{5,15})!/i,  '<br/><iframe width="560" height="315" src="http://www.youtube.com/embed/\1" frameborder="0" allowfullscreen></iframe><br/>')  unless options[:strict_markdown] || options[:no_youtube]
    d = d.gsub(/!VIMEO!([0-9]{6,9})!/i,  '<br/><iframe src="http://player.vimeo.com/video/\1" width="500" height="281" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe><br/>') unless options[:strict_markdown] || options[:no_youtube]
 
    if options[:smilies]
      d.gsub!(/:smile:/, '<img src="/assets/smilies/smile.gif" height="20" width="20" />')
      d.gsub!(/:wink:/, '<img src="/assets/smilies/wink.gif" height="20" width="20" />')
      d.gsub!(/:wall:/, '<img src="/assets/smilies/wall.gif" height="20" width="20" />')
    end 
    return d
  end

  def is_number?
    (self =~ /^\-?[\d\.]+$/) != nil
  end

  def md5
  Digest::MD5.hexdigest(self)
  end  
  def transliterate
    # Based on permalink_fu by Rick Olsen

    # s = Iconv.iconv('ascii//ignore//translit', 'utf-8', str).to_s

    # Downcase string
    self.downcase!

    # Remove apostrophes so isn't changes to isnt
    self.gsub!(/'/, '')

    # Replace any non-letter or non-number character with a space
    self.gsub!(/[^A-Za-z0-9]+/, ' ')

    # Remove spaces from beginning and end of string
    self.strip!

    # Replace groups of spaces with single hyphen
    self.gsub!(/\ +/, '-')

  end

 def urlise
  self.downcase.gsub(/'/, '').gsub(/[^A-Za-z0-9]+/, ' ').strip.gsub(/\ +/,'-')
 end
 

 def is_blank?
   return true if self.strip.length==0
   return false
 end
 
 def not_blank?
   return !is_blank?
 end

 def right_truncate(n, missing='...')
   return self if self.length<=n
   return missing + self[-n..-1]
  end


 # A regular expression to match small words that should not be
 # titleized.
 SMALL_WORDS_RE = /^(a|an|and|as|at|but|by|en|for|if|in|of|on|or|the|to|v\.?|via|vs\.?)$/
 
 def titleize_if_appropriate

   # If a word does not contain a full-stop within itself and it doesn't
   # contain any capital letters apart from its first letter, titleize it.
   if !self[/\w\.\w/] && !self[/^.+[A-Z]/]
     
     # Capitalise the first *word* character (therefore avoiding problems
     # where the first character is some punctuation).
     self[/^\W*\w/] = self[/^\W*\w/].upcase
   end
   self
 end

 def title_case

   # Keep track when a colon has been used at the end of a word.
   colon_preceding = false
   
   # Split the string by any whitespace and then inspect each word
   # at a time.
   words = split(/\s+/).map do |word|
     title_cased_word = if colon_preceding
       
       # If there was a colon preceding this word then titleize
       # it even if it is a small word.
       colon_preceding = false
       word.titleize_if_appropriate
     elsif word.downcase[SMALL_WORDS_RE]
       
       # If this is a small word, make it lowercase.
       word.downcase
     else
       
       # In all other cases, titleize the word.
       word.titleize_if_appropriate
     end

     # If this word ends in a colon, set the flag so that the
     # following word can be titleized.
     colon_preceding = true if word[/:$/]

     title_cased_word
   end

   # Always capitalise the first and last words.
   words[0] = words[0].titleize_if_appropriate
   words[-1] = words[-1].titleize_if_appropriate
   
   words.join(" ")
 end 

end

class Fixnum

  def is_number?
    return true
  end

  def is_blank?
    return false
  end

  def downcase!
    return self
  end

  def strip!
    return self
  end
end

class NilClass
 
  def is_number?
   return false
  end

  def is_blank?
    return true
  end
  
  def not_blank?
    return false
  end
end
