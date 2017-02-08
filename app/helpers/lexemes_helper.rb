# encoding: utf-8

module LexemesHelper
  # Do wikibold around a string, except around the | character, unless it's the |
  # that does pipe-linking.  This approach thanks to Ben Marini's suggestion at
  # http://refactormycode.com/codes/977-ugly-split-join
  def bold_around_pipes (str)
    stack, functional = 0, false
    "'''#{str}'''".each_char.inject('') do |memo, char|
      case char
      when '[' then stack, functional = stack + 1, true
      when ']' then stack, functional = stack - 1, !stack.zero?
      when '|' then stack.zero? || !functional ? char = "'''|'''" : functional = false
      end
      memo + char
    end
  end
  
  def wiki_title_for(lexeme, headword)
    dict = lexeme.dictionaries.first
    homographs = dict.try(:homographs_of, headword.form)
    count = homographs.try(:size) || 1
    index = homographs.try(:index, lexeme) || 0
    sortkey = headword.form.capitalize.delete " " # This will eventually want language- or dictionary-sensitive rules
    
    dict_sort = "{{%s|%s}}" % [dict.try(:title), sortkey]
    count == 1 ? dict_sort : t('helpers.lexemes.wikititle_with_ordinal', dictionary: dict_sort, ordinal: "#{roman_numeral(index.next)}", default: "%{dictionary} %{ordinal}.")
  end
  
  def roman_numeral(int)
    "%s%s%s%s" % [
      ['', 'M', 'MM', 'MMM', 'Mↁ', 'ↁ', 'ↁM', 'ↁMM', 'ↁMMM', 'Mↂ'][int / 1000 % 10],
      ['', 'C', 'CC', 'CCC', 'CD', 'D', 'DC', 'DCC', 'DCCC', 'CM'][int / 100 % 10],
      ['', 'X', 'XX', 'XXX', 'XL', 'L', 'LX', 'LXX', 'LXXX', 'XC'][int / 10 % 10],
      ['', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX'][int % 10]
    ]
  end

  # Given a lexeme, give the most acceptable headwords as a sentence (sans period)
  # e.g. "Chançuon, чаншӯн, or cançuon"
  # Used in page titles and dictionary show
  def titleize_headwords_for lexeme    
    headwords = lexeme.best_headword_forms.compact.inject([]) do |memo, form|
      swapform = form.dup
      swapform[0,1] = swapform[0,1].swapcase
      
      memo.include?(swapform) ? memo : memo << form
    end
    
    html_escape sentence_case(headwords.to_options_sentence(@dictionary.try(:definition_language)))
  end
  
  # List dictionaries.  Includes a separate group with the logged-in 
  # user's most recent dictionaries, if applicable.
  # 
  # Returns an object suitable for grouped_collection_select.
  def dictionary_select
    dictionary_hash = {}
    
    if session[:logged_in] 
      recent = User.find(session[:logged_in]).recent.compact
      dictionary_hash[t('helpers.dictionaries.recent')] = [] if recent.any?
      
      recent.each do |dict|
        dictionary_hash[t('helpers.dictionaries.recent')] << [dict.title, dict.id]
      end
    end
    
    dictionary_hash[t('helpers.dictionaries.all')] = []
    Dictionary.all.each do |dict|
      dictionary_hash[t('helpers.dictionaries.all')] << [dict.title, dict.id]
    end

    dictionary_hash.to_a
  end
end