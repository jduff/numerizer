class GenericProvider

  def numerize(str, ignore: [], bias: :none)
    preprocess(str, ignore)
    numerize_numerals(str, ignore, bias)
    numerize_fractions(str, ignore, bias)
    numerize_ordinals(str, ignore, bias)
    numerize_big_prefixes(str, ignore, bias)
    postprocess(str, ignore)
  end

  private

  def preprocess(str, ignore)
    raise 'must be implemented in subclass'
  end
  def numerize_numerals(str, ignore, bias)
    raise 'must be implemented in subclass'
  end
  def numerize_fractions(str, ignore, bias)
    raise 'must be implemented in subclass'
  end
  def numerize_ordinals(str, ignore, bias)
    raise 'must be implemented in subclass'
  end
  def numerize_big_prefixes(str, ignore, bias)
    raise 'must be implemented in subclass'
  end
  def postprocess(str, ignore)
    raise 'must be implemented in subclass'
  end

  # Turns list of words into a unionized list, ignoring words specified in 
  # arguments or that meet the conditions of the yield block
  def regexify(words, ignore:[])
    if block_given?
      return Regexp.union(words.reject { |x| ignore.include?(x) || yield(x) })
    else
      return Regexp.union(words.reject { |x| ignore.include?(x) })
    end
  end

end
