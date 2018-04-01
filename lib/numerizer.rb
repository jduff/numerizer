# LICENSE:
#
# (The MIT License)
#
# Copyright © 2008 Tom Preston-Werner
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'strscan'

require 'numerizer/version'

class Numerizer

  DIRECT_NUMS = [
    ['eleven', '11'],
    ['twelve', '12'],
    ['thirteen', '13'],
    ['fourteen', '14'],
    ['fifteen', '15'],
    ['sixteen', '16'],
    ['seventeen', '17'],
    ['eighteen', '18'],
    ['nineteen', '19'],
    ['ninteen', '19'], # Common mis-spelling
    ['zero', '0'],
    ['ten', '10'],
    ['\ba\b', '1']
  ]

  SINGLE_NUMS = [
    ['one', 1],
    ['two', 2],
    ['three', 3],
    ['four', 4],
    ['five', 5],
    ['six', 6],
    ['seven', 7],
    ['eight', 8],
    ['nine', 9]
  ]

  TEN_PREFIXES = [
    ['twenty', 20],
    ['thirty', 30],
    ['forty', 40],
    ['fourty', 40], # Common misspelling
    ['fifty', 50],
    ['sixty', 60],
    ['seventy', 70],
    ['eighty', 80],
    ['ninety', 90]
  ]

  BIG_PREFIXES = [
    ['hundred', 100],
    ['thousand', 1000],
    ['million', 1_000_000],
    ['billion', 1_000_000_000],
    ['trillion', 1_000_000_000_000],
  ]

  FRACTIONS = [
    ['hal(f|ves)', 2],
    ['quarter(s)?', 4],
  ]

  ORDINALS = [
    ['first', 1],
    ['second', 2],
  ]

  SINGLE_ORDINAL_FRACTIONALS = [
    ['third', 3],
    ['fourth', 4],
    ['fifth', 5],
    ['sixth', 6],
    ['seventh', 7],
    ['eighth', 8],
    ['ninth', 9],
  ]

  DIRECT_ORDINAL_FRACTIONALS = [
    ['tenth', '10'],
    ['eleventh', '11'],
    ['twelfth', '12'],
    ['thirteenth', '13'],
    ['fourteenth', '14'],
    ['fifteenth', '15'],
    ['sixteenth', '16'],
    ['seventeenth', '17'],
    ['eighteenth', '18'],
    ['nineteenth', '19'],
    ['twentieth', '20'],
    ['thirtieth', '30'],
    ['fourtieth', '40'],
    ['fiftieth', '50'],
    ['sixtieth', '60'],
    ['seventieth', '70'],
    ['eightieth', '80'],
    ['ninetieth', '90']
  ]

  ALL_ORDINALS = ORDINALS + SINGLE_ORDINAL_FRACTIONALS + DIRECT_ORDINAL_FRACTIONALS
  ALL_FRACTIONS = FRACTIONS + (SINGLE_ORDINAL_FRACTIONALS + DIRECT_ORDINAL_FRACTIONALS).map {|tp| [tp[0] + '(s)?', tp[1]] }
  ONLY_PLURAL_FRACTIONS = FRACTIONS + (SINGLE_ORDINAL_FRACTIONALS + DIRECT_ORDINAL_FRACTIONALS).map {|tp| [tp[0] + 's', tp[1]] }

  ALL_ORDINALS_REGEX = ALL_ORDINALS.reduce { |a,b| a[0] + '|' + b[0] }


  def self.numerize(string, ignore: [], bias: :none)
    string = string.dup
    ignore = ignore.map(&:downcase).to_set

    # preprocess
    string.gsub!(/ +|([^\d])-([^\d])/, '\1 \2') # will mutilate hyphenated-words
    string.gsub!(/\ba$/, '') && string.rstrip! # doesn't make sense for an 'a' at the end to be a 1

    # easy/direct replacements
    (DIRECT_NUMS + SINGLE_NUMS).each do |dn|
      next if ignore.include? dn[0].downcase 
      string.gsub!(/(^|\W)#{dn[0]}(?=$|\W)/i, '\1<num>' + dn[1].to_s) 
    end

    # ten, twenty, etc.
    TEN_PREFIXES.each do |tp|
      next if ignore.include? tp[0].downcase 
      SINGLE_NUMS.each do |dn|
        next if ignore.include? dn[0].downcase 
        string.gsub!(/(^|\W)#{tp[0]}#{dn[0]}(?=$|\W)/i, '\1<num>' + (tp[1] + dn[1]).to_s)
      end
      (ORDINALS + SINGLE_ORDINAL_FRACTIONALS).each do |dn|
        next if ignore.include? dn[0].downcase 
        string.gsub!(/(^|\W)#{tp[0]}(\s)?#{dn[0]}(?=$|\W)/i, '\1<num>' + (tp[1] + dn[1]).to_s + dn[0][-2, 2])
      end
      string.gsub!(/(^|\W)#{tp[0]}(?=$|\W)/i, '\1<num>' + tp[1].to_s)
    end

    # handle fractions
    # only plural fractions if ordinal mode
    if bias == :ordinal
      fractionals = ONLY_PLURAL_FRACTIONS 
    else
      fractionals = ALL_FRACTIONS
    end

    fractionals.each do |tp|
      next unless ignore.select {|x| /#{tp[0]}/ =~ x } .empty?
      string.gsub!(/a #{tp[0]}(?=$|\W)/i, '<num>1/' + tp[1].to_s)
      # TODO : Find Noun Distinction for Quarter
      # Handle Edge Case with Quarter
      if bias == :fractional
        string.gsub!(/(^|\W)#{tp[0]}(?=$|\W)/i, '/' + tp[1].to_s)
      elsif /quarter/ =~ tp[0] then
        string.gsub!(/(?:\w*)(^|\W)#{tp[0]}(?=$|\W)/i) do |match|
          if (match =~ /^(i|you|he|she|we|it|you|they|to|the)/i) == nil then 
            match.gsub!(/(^|\W)#{tp[0]}/, '/' + tp[1].to_s)
          end
          match
        end
      else
        string.gsub!(/(?<!the)\s#{tp[0]}(?=$|\W)/i, '/' + tp[1].to_s)
      end
    end

    ALL_ORDINALS.each do |on|
      break if bias == :fractional # shouldn't be necessary but saves cycles
      next if ignore.include? on[0].downcase 
      if on[0] == 'second' and bias != :ordinal then
        # We don't want to substitute second preceeded by second or another ordinal
        string.gsub!(/\w*(?<!second)(^|\W)#{on[0]}(?=$|\W)/i) do |match| 
          unless match =~ /^(\d|#{ALL_ORDINALS_REGEX})/ then
            match.gsub!(/(^|\W)#{on[0]}(?=$|\W)/i, '\1<num>' + on[1].to_s + on[0][-2, 2])
          end
          match
        end
      else
        string.gsub!(/(^|\W)#{on[0]}(?=$|\W)/i, '\1<num>' + on[1].to_s + on[0][-2, 2])
      end
    end

    # evaluate fractions when preceded by another number
    string.gsub!(/(\d+)(?: | and |-)+(<num>|\s)*(\d+)\s*\/\s*(\d+)/i) { ($1.to_f + ($3.to_f/$4.to_f)).to_s }

    # fix unpreceeded fractions
    string.gsub!(/(?:^|\W)\/(\d+)/, '1/\1')
    string.gsub!(/(?<=[a-zA-Z])\/(\d+)/, ' 1/\1')

    # hundreds, thousands, millions, etc.
    BIG_PREFIXES.each do |bp|
      next if ignore.include? bp[0].downcase 
      string.gsub!(/(?:<num>)?(\d*) *#{bp[0]}/i) { $1.empty? ? bp[1] : '<num>' + (bp[1] * $1.to_i).to_s }
      andition(string)
    end

    andition(string)

    # always substitute halfs
    unless ignore.include? 'half' then
      string.gsub!(/\bhalf\b/i, '1/2')
    end

    string.gsub(/<num>/, '')
  end

  class << self
    private
    def andition(string)
      sc = StringScanner.new(string)
      while(sc.scan_until(/<num>(\d+)( | and )<num>(\d+)(?=[^\w]|$)/i))
        if sc[2] =~ /and/ || sc[1].size > sc[3].size
          string[(sc.pos - sc.matched_size)..(sc.pos-1)] = '<num>' + (sc[1].to_i + sc[3].to_i).to_s
          sc.reset
        end
      end
    end
  end

end
