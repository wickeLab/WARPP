module Ascii
  @@replacements = {
      '×' => "",
  }

  @@encoding_options = {
      :invalid   => :replace,     # Replace invalid byte sequences
      :replace => "",             # Use a blank for those replacements
      :universal_newline => true, # Always break lines with \n
      # For any character that isn't defined in ASCII, run this
      # code to find out how to replace it
      :fallback => lambda { |char|
        # If no replacement is specified, use an empty string
        @@replacements.fetch(char, "")
      },
  }

  def encode(non_ascii_string)
    ascii = non_ascii_string.encode(Encoding.find('ASCII'), @@encoding_options)
    return ascii.gsub(/\s{2}/, " ")
  end
end
