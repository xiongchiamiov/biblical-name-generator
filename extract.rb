#!/usr/bin/env ruby
# encoding: utf-8

# May you recognize your weaknesses and share your strengths.
# May you share freely, never taking more than you give.
# May you find love and love everyone you find.

require 'set'

names = {}
names.default = 0

File.open('NHEB.txt', 'r').each_line do |line|
   # There are some strange characters floating around in this file; we don't
   # really care about them, so just ignore them altogether.
   # Just going from utf-8 -> utf-8 doesn't work, because ???, but doing a
   # silly utf-8 -> utf-16 -> utf-8 conversion is fine.
   # http://stackoverflow.com/a/8873922/120999
   line.encode! 'UTF-16', 'UTF-8', :invalid => :replace, :replace => ''
   line.encode! 'UTF-8', 'UTF-16'
   
   # Skip the first few copyright lines.
   if line =~ %r{//}
      next
   end
   
   # Strip off the book, chapter and verse.
   #print line
   words = line.split.drop 2
   next if not words
   
   # When there are sentence breaks in the middle of the verse, we need to
   # downcase the next word. Also, it's likely the start of the verse is the
   # start of a sentence.
   startOfSentence = true
   words.each do |word|
      if startOfSentence
         word.downcase!
         startOfSentence = false
      end
      if word.end_with? *%W{. ! ? " ' :}
         startOfSentence = true
      end
      # Quoted sentences don't come after periods.
      if word.start_with? '"' or word.start_with? "'"
         next
      end
      
      # Possessive-stripping.
      word.sub! "'s", ''
      # Punctuation is harmful for our purposes.
      word.tr! ',.;:!?"\'()[]', ''
      
      # We want words that are title-cased, but not those that are just plain
      # ol' capitalized all the way (due to being part of a God-quote).
      # http://stackoverflow.com/a/8529619/120999
      if word[0].match /\p{Upper}/ and not word.match /^\p{Upper}+$/
         names[word] += 1
      end
   end
end

# Some names are used a lot - so much they aren't very interesting.
blacklist = Set.new %W{I Lord God Israel Jerusalem Jesus Moses Egypt King Queen
Good News Man Woman David Christ Holy Spirit Father Pharaoh Most High}
names.delete_if {|name| blacklist.include? name}

begin
   names.sort_by {|name, count| count}.reverse.each do |tuple|
      puts "#{tuple[1]}: #{tuple[0]}"
   end
rescue Errno::EPIPE
   # Swallow and stop writing to stdout.
end

