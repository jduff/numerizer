require 'provider'

class EnglishProvider < GenericProvider

  DIRECT_NUMS = {
    'eleven' => '11',
    'twelve' => '12',
    'thirteen' => '13',
    'fourteen' => '14',
    'fifteen' => '15',
    'sixteen' => '16',
    'seventeen' => '17',
    'eighteen' => '18',
    'nineteen' => '19',
    'ninteen' => '19',
    'zero' => '0',
    'ten' => '10',
  }

  SINGLE_NUMS = {
    'one' => 1,
    'two' => 2,
    'three' => 3,
    'four' => 4,
    'five' => 5,
    'six' => 6,
    'seven' => 7,
    'eight' => 8,
    'nine' => 9
  }

  TEN_PREFIXES = {
    'twenty' => 20,
    'thirty' => 30,
    'forty' => 40,
    'fourty' => 40,
    'fifty' => 50,
    'sixty' => 60,
    'seventy' => 70,
    'eighty' => 80,
    'ninety' => 90
  }

  BIG_PREFIXES = {
    'hundred' => 100,
    'thousand' => 1000,
    'million' => 1_000_000,
    'billion' => 1_000_000_000,
    'trillion' => 1_000_000_000_000,
  }

  FRACTIONS = {
    'half' => 2,
    'halves' => 2,
    'quarter' => 4,
    'quarters' => 4
  }

  ORDINALS = {
    'first' => 1,
    'second' => 2,
  }

  SINGLE_ORDINAL_FRACTIONALS = {
    'third' => 3,
    'fourth' => 4,
    'fifth' => 5,
    'sixth' => 6,
    'seventh' => 7,
    'eighth' => 8,
    'ninth' => 9,
  }

  DIRECT_ORDINAL_FRACTIONALS = {
    'tenth' => '10',
    'eleventh' => '11',
    'twelfth' => '12',
    'thirteenth' => '13',
    'fourteenth' => '14',
    'fifteenth' => '15',
    'sixteenth' => '16',
    'seventeenth' => '17',
    'eighteenth' => '18',
    'nineteenth' => '19',
    'twentieth' => '20',
    'thirtieth' => '30',
    'fourtieth' => '40',
    'fiftieth' => '50',
    'sixtieth' => '60',
    'seventieth' => '70',
    'eightieth' => '80',
    'ninetieth' => '90'
  }

  ALL_ORDINALS = ORDINALS.merge(SINGLE_ORDINAL_FRACTIONALS).merge(DIRECT_ORDINAL_FRACTIONALS)
  ONLY_PLURAL_FRACTIONS = FRACTIONS.merge((SINGLE_ORDINAL_FRACTIONALS.merge(DIRECT_ORDINAL_FRACTIONALS)).inject({ }) {|h, (k,v)| h[k + 's'] = v ; h})
  ALL_FRACTIONS = ONLY_PLURAL_FRACTIONS.merge(SINGLE_ORDINAL_FRACTIONALS).merge(DIRECT_ORDINAL_FRACTIONALS)

  DIRECT_SINGLE_NUMS = DIRECT_NUMS.merge(SINGLE_NUMS)
  ORDINAL_SINGLE = ORDINALS.merge(SINGLE_ORDINAL_FRACTIONALS)

  ALL_ORDINALS_REGEX = Regexp.union(ALL_ORDINALS.keys)

  PRONOUNS = /i|you|he|she|we|it|you|they|to|the/i

  def preprocess(string, ignore)
    string.gsub!(/ +|([^\d])-([^\d])/, '\1 \2') # will mutilate hyphenated-words
    string.gsub!(/\ba$/, '') && string.rstrip! # doesn't make sense for an 'a' at the end to be a 1
  end

  def numerize_numerals(string, ignore)
    # easy/direct replacements
    dir_single_nums = regexify(DIRECT_SINGLE_NUMS.keys, ignore: ignore)
    string.gsub!(/(^|\W)(#{dir_single_nums})(?=$|\W)/i) { $1 + '<num>' + DIRECT_SINGLE_NUMS[$2].to_s} 
    string.gsub!(/(^|\W)\ba\b(?=$|\W)/i, '\1<num>' + 1.to_s)

    # ten, twenty, etc.
    ten_prefs = regexify(TEN_PREFIXES.keys, ignore: ignore)
    single_nums = regexify(SINGLE_NUMS.keys, ignore: ignore)
    single_ords = regexify(ORDINAL_SINGLE.keys, ignore: ignore)
    string.gsub!(/(^|\W)(#{ten_prefs})(#{single_nums})(?=$|\W)/i) { $1 + '<num>' + (TEN_PREFIXES[$2] + SINGLE_NUMS[$3]).to_s}
    string.gsub!(/(^|\W)(#{ten_prefs})(\s)?(#{single_ords})(?=$|\W)/i) { $1 + '<num>' + (TEN_PREFIXES[$2] + ORDINAL_SINGLE[$4]).to_s + $4[-2, 2]}
    string.gsub!(/(^|\W)(#{ten_prefs})(?=$|\W)/i) { $1 + '<num>' + TEN_PREFIXES[$2].to_s}
  end

  def numerize_fractions(string, ignore, bias)
    # handle fractions
    # only plural fractions if ordinal mode
    if bias == :ordinal
      fractionals = regexify(ONLY_PLURAL_FRACTIONS.keys, ignore: ignore)
    else
      fractionals = regexify(ALL_FRACTIONS.keys, ignore: ignore)
    end

    string.gsub!(/a (#{fractionals})(?=$|\W)/i) {'<num>1/' + ALL_FRACTIONS[$1].to_s}
    # TODO : Find Noun Distinction for Quarter
    if bias == :fractional
      string.gsub!(/(^|\W)(#{fractionals})(?=$|\W)/i) {'/' + ALL_FRACTIONS[$2].to_s}
    else
      string.gsub!(/(\w*)(?<!the)(^|\W)(#{fractionals})(?=$|\W)/i) do |match|
        prematch = $1 
        space = $2
        fraction = $3
        # HANDLES QUARTER EDGE CASES
        if (!$3.start_with?('quarter') && space == ' ') || ($3.start_with?('quarter') && (prematch =~ /^(#{PRONOUNS})\b/) == nil) 
            match = prematch + '/' + ALL_FRACTIONS[fraction].to_s 
        end
        match
      end
    end
    cleanup_fractions(string)
  end

  def cleanup_fractions(string)
    # evaluate fractions when preceded by another number
    string.gsub!(/(\d+)(?: | and |-)+(<num>|\s)*(\d+)\s*\/\s*(\d+)/i) { ($1.to_f + ($3.to_f/$4.to_f)).to_s }
    # fix unpreceeded fractions
    string.gsub!(/(?:^|\W)\/(\d+)/, '1/\1')
    string.gsub!(/(?<=[a-zA-Z])\/(\d+)/, ' 1/\1')
  end

  def numerize_ordinals(string, ignore, bias)
    if bias != :fractionals
      all_ords = regexify(ALL_ORDINALS.keys, ignore: ignore) {|x| x == 'second' && bias != :ordinal }
      if bias != :ordinal && !ignore.include?('second')
        string.gsub!(/(\w*)(?<!second)(^|\W)second(?=$|\W)/i) do |match| 
          prematch = $1
          space = $2
          if (prematch =~ /^(\d|#{ALL_ORDINALS_REGEX})/i) == nil
            match = prematch + space + '<num>' + ALL_ORDINALS['second'].to_s + 'second'[-2, 2]
          end
          match
        end
      end
      string.gsub!(/(^|\W)(#{all_ords})(?=$|\W)/i) { $1 + '<num>' + ALL_ORDINALS[$2].to_s + $2[-2, 2]}
    end
  end

  def numerize_big_prefixes(string, ignore)
    # hundreds, thousands, millions, etc.
    # big_prefs = regexify(BIG_PREFIXES.keys, ignore: ignore)
    BIG_PREFIXES.each do |k,v|
      next if ignore.include? k.downcase 
      string.gsub!(/(?:<num>)?(\d*) *#{k}/i) { $1.empty? ? v : '<num>' + (v * $1.to_i).to_s }
      andition(string)
    end
  end

  def numerize_halves(string, ignore)
    # always substitute halfs
    unless ignore.include? 'half'
      string.gsub!(/\bhalf\b/i, '1/2')
    end
  end

  def andition(string)
    sc = StringScanner.new(string)
    while(sc.scan_until(/<num>(\d+)( | and )<num>(\d+)(?=[^\w]|$)/i))
      if sc[2] =~ /and/ || sc[1].size > sc[3].size
        string[(sc.pos - sc.matched_size)..(sc.pos-1)] = '<num>' + (sc[1].to_i + sc[3].to_i).to_s
        sc.reset
      end
    end
  end

  def postprocess(string, ignore)
    andition(string)
    numerize_halves(string, ignore)
    #Strip Away Added Num Tags
    string.gsub(/<num>/, '')
  end

end
