#######################################################################
# RADIUS                                                              #
# Really, Another Developer Indentation Utility Software?             #
# (c) 2017 Dagen Brock                                                #
#                                                                     #
# Hats off to people who make real dev tools like:                    #
#  https://www.brutaldeluxe.fr/products/crossdevtools/cadius/         #
#######################################################################

# params/defaults
mnemonic_col_x = 18
operand_col_x = 24
comment_col_x = 48
min_space = 1
bump_space = 2
indent_semi = true
indent_ast = false
std_out = false

def print_help()
  puts "\nradius.rb [-h] [-c0 nn] [-c1 nn] [-c2 nn] filename.\n "
  puts "  -h  : help"
  puts "  -c0 : column 0 indent (start of opcode column)"
  puts "  -c1 : column 1 indent (start of operand column)"
  puts "  -c2 : column 2 indent (start of comment column)"
  puts "  -s  : redirect to standard out only (default overwrites source file)"
  puts "\n\n"
end

# must at least have filename
if ARGV.length == 0
  print_help()
  exit
end


# load file
infile = false
skip_parm = false
for i in 0..ARGV.length-1
  if skip_parm
    skip_parm = false
    next
  end

  arg = ARGV[i]
  if arg[0] == "-"
    case arg
    when "-h"
      print_help()
      exit
    when "-s"
      std_out = true
    when "-c0"
      mnemonic_col_x = ARGV[i+1].to_i
      skip_parm = true
    when "-c1"
      operand_col_x = ARGV[i+1].to_i
      skip_parm = true
    when "-c2"
      comment_col_x = ARGV[i+1].to_i
      skip_parm = true
    end

  else
    if infile == false
      infile = arg
    end
  end

end

#puts "opening #{infile}"
file = File.open(infile, "rb")
source_contents = file.read
file.close unless file.nil?

# begin line-by-line processing
output_buf = ""
# most editors will start numbering with line 1
linenum = 1 
source_contents.each_line do |line|
  # we catch any issue that causes radius to fail and just print out the line
  # that it failed on.  not the best, but *shrug*
  # Note, to debug a condition below simply:
  #   puts " "*i +"."
  #   puts line
  #
  begin
    
    # state machine - resets each line
    in_quote = false
    in_comment = false
    label_done = false
    in_label = false
    opcode_done = false
    in_opcode = false
    operand_done = false
    in_operand = false
    chars_started = false
    quote_char = false
    x=0

    buf = "" # line buffer, starts empty each line and is appended to output_buf

    # begin char-by-char processing
    line.each_char.with_index(0) do |c, i|

      # starts with whitespace? do an indent
      if i == 0 && c.strip.empty?
        buf << " "*mnemonic_col_x  # optimize?
        x+=mnemonic_col_x
        label_done = true
        next                # SHORT CIRCUIT
      end

      # are we in a comment? just print the char
      if in_comment
        # don't print embedded newline :P
        if !c.include?("\n")
          buf << c
          x+=1
        end
        next                # SHORT CIRCUIT
      end

      # are we in a quote? print, but also look for matching end quote
      if in_quote
        buf << c
        x+=1
        if c == quote_char # second quotes
          in_quote = false
        end
        next                # SHORT CIRCUIT
      end

      # not already in comment or quote
      if c.strip.empty?
        #ignore
        if in_label
          in_label = false
          label_done = true
          # do we need to bump out space
          if x > mnemonic_col_x-min_space
            buf << " "*min_space # optimize?
            x+=min_space
          else
            buf << " "*(mnemonic_col_x-x) # optimize ?
            x+=mnemonic_col_x-x
          end
        elsif in_opcode
          in_opcode = false
          opcode_done = true
          # do we need to bump out space
          if x > operand_col_x-min_space
            buf << " "*min_space
            x+=min_space
          else
            buf << " "*(operand_col_x-x)
            x+=operand_col_x-x
          end
        elsif in_operand
          in_operand = false
          operand_done = true
          # do we need to bump out space
          if x > comment_col_x-min_space
            buf << " "*min_space
            x+=min_space
          else
            buf << " "*(comment_col_x-x)
            x+=comment_col_x-x
          end
        end


        next
      else
        chars_started = true
        # see if we are starting a quote
        if c == '"' || c == "'"
          quote_char = c
          in_quote = true
          in_operand = true
          buf << c
          # see if we are starting a line with a comment
        elsif (c == ';' || c == '*') && i == 0
          in_comment = true
          buf << c
          x+=1
        # found a semi-colon not in an operand (macro!danger)
        #   (and not in quote or comment)
        elsif c == ';' && !in_operand
          in_comment = true
          # protect against "negative" spacing
          spaces = 1 > (comment_col_x-x) ? 1 : (comment_col_x-x)
          buf << " "*spaces

          x+=comment_col_x-x
          buf << c
          x+=1
        # found asterisk preceded only by whitespace
        elsif c == '*' && line[0..i-1].strip.empty?
          in_comment = true
          buf << c
          x+=1
        # real label!
        elsif i == 0
          buf << ""
          in_label = true
          buf << c
          x+=1
        # already in label?
        elsif in_label
          buf << c
          x+=1
        # real opcode!
        elsif label_done && !opcode_done
          in_opcode = true
          buf << c
          x+=1
        # already in opcode
        elsif in_opcode
          buf << c
          x+=1
        # real operand!
        elsif opcode_done && !operand_done
          in_operand = true
          buf << c
          x+=1
        # already in operand
        elsif in_operand
          buf << c
          x+=1
	# if they have unhandled weirdness, just pass them through minus whitespace
	else 
      	  if !c.strip.empty?
            buf << c
            x+=1
          end
        end
      end
    end
  rescue Exception => ex
    puts "An error of type #{ex.class} happened, message is #{ex.message}"
    abort("We failed to parse on line #{linenum}")
      
  end
  linenum+=1
  # move line to buffer, stripping trailing spaces
  output_buf << buf.rstrip << "\n"
end

# see if output matches input as far as characters
is_error = output_buf.gsub(/\s+/, "") != source_contents.gsub(/\s+/, "")
if is_error
  #puts output_buf.gsub(/\s+/, "")
  #puts source_contents.gsub(/\s+/, "")
  puts "FAILED TO SAFELY INDENT.  Aborting... "
  puts "** We're really sorry about this.  But we didn't want to take a chance corrupting your file."
  exit
end

if std_out
  puts output_buf
else
  File.open(infile, 'w') { |file| file.write(output_buf) }
end
