require 'lingua/stemmer'

class Word < ActiveRecord::Base

  @@insig_words = {}

  Word.where(:is_insignificant=>1).all.each do |w| 
    ww = Lingua.stemmer(w.name).downcase
    @@insig_words[ww] = true
  end

  def Word.frequency(text, options = {})

    t = text.downcase.gsub(/[^a-z\']/, ' ')
   
    stem = options[:stem] || false
    exclude_insig_words = options[:exclude_insig_words] || true
    excludes = options[:excludes] 
    exclude_matches_stems = options[:exclude_matches_stems] || true

    words = {}
    t.split(' ').each do |w|
      next if exclude_insig_words && @@insig_words[w]
      next if excludes && excludes[w]
      ww = stem ? Lingua.stemmer(w) : w
      next if excludes && excludes[ww] && exclude_matches_stems
      next if exclude_insig_words && @@insig_words[ww] && exclude_matches_stems
      words[ww] ||= 0
      words[ww] += 1
    end

    if options[:de_stem]
      t.split(' ').each do |w|
        ww = Lingua.stemmer(w)
        words[w] = words[ww] if words[ww]
        words.delete(ww)
      end

    end
   return words 
  end

  def Word.histogram(text, options) 
    f = Word.frequency(text, options)
     
    threshold = options[:threshold]
    max = options[:max]
    r = []  
    f.sort {|a,b| a[1]<=>b[1]}.reverse.collect do |k,v| 
      break if max && r.size>=max
      if threshold==nil || v >= threshold
        r << [ k, v ]
      end
    end
    
    return r
  end

end
