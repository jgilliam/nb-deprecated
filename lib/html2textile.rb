
require 'sgml-parser'

# A class to convert HTML to textile. Based on the python parser
# found at http://aftnn.org/content/code/html2textile/
#
# Read more at http://jystewart.net/process/2007/11/converting-html-to-textile-with-ruby
#
# Author::    James Stewart  (mailto:james@jystewart.net)
# Copyright:: Copyright (c) 2007 James Stewart
# License::   Distributes under the same terms as Ruby

# This class is an implementation of an SGMLParser designed to convert
# HTML to textile.
# 
# Example usage:
#   parser = HTMLToTextileParser.new
#   parser.feed(input_html)
#   puts parser.to_textile
class HTMLToTextileParser < SGMLParser

  attr_accessor :result
  attr_accessor :in_block
  attr_accessor :data_stack
  attr_accessor :a_href
  attr_accessor :in_ul
  attr_accessor :in_ol

  @@permitted_tags = []
  @@permitted_attrs = []

  def initialize(verbose=nil)
    @output = String.new
    self.in_block = false
    self.result = []
    self.data_stack = []
    super(verbose)
  end

  # Normalise space in the same manner as HTML. Any substring of multiple
  # whitespace characters will be replaced with a single space char.
  def normalise_space(s)
    s.to_s.gsub(/\s+/x, ' ')
  end

  def build_styles_ids_and_classes(attributes)
    idclass = ''
    idclass += attributes['class'] if attributes.has_key?('class')
    idclass += "\##{attributes['id']}" if attributes.has_key?('id')
    idclass = "(#{idclass})" if idclass != ''

    style = attributes.has_key?('style') ? "{#{attributes['style']}}" : ""
    "#{idclass}#{style}"
  end

  def make_block_start_pair(tag, attributes)
    attributes = attrs_to_hash(attributes)
    class_style = build_styles_ids_and_classes(attributes)
    write("#{tag}#{class_style}. ")
    start_capture(tag)
  end

  def make_block_end_pair
    stop_capture_and_write
    write("\n\n")
  end

  def make_quicktag_start_pair(tag, wrapchar, attributes)
    attributes = attrs_to_hash(attributes)
    class_style = build_styles_ids_and_classes(attributes)
    write([" ", "#{wrapchar}#{class_style}"])
    start_capture(tag)
  end

  def make_quicktag_end_pair(wrapchar)
    stop_capture_and_write
    write([wrapchar, " "])
  end

  def write(d)
    if self.data_stack.size < 2
      self.result += d.to_a
    else
      self.data_stack[-1] += d.to_a
    end
  end

  def start_capture(tag)
    self.in_block = tag
    self.data_stack.push([])
  end

  def stop_capture_and_write
    self.in_block = false
    self.write(self.data_stack.pop)
  end

  def handle_data(data)
    write(normalise_space(data).strip) unless data.nil? or data == ''
  end

  %w[1 2 3 4 5 6].each do |num|
    define_method "start_h#{num}" do |attributes|
      make_block_start_pair("h#{num}", attributes)
    end

    define_method "end_h#{num}" do
      make_block_end_pair
    end
  end

  PAIRS = { 'blockquote' => 'bq', 'p' => 'p' }
  QUICKTAGS = { 'b' => '*', 'strong' => '*', 
    'i' => '_', 'em' => '_', 'cite' => '??', 's' => '-', 
    'sup' => '^', 'sub' => '~', 'code' => '@', 'span' => '%'}

  PAIRS.each do |key, value|
    define_method "start_#{key}" do |attributes|
      make_block_start_pair(value, attributes)
    end

    define_method "end_#{key}" do
      make_block_end_pair
    end
  end

  QUICKTAGS.each do |key, value|
    define_method "start_#{key}" do |attributes|
      make_quicktag_start_pair(key, value, attributes)
    end

    define_method "end_#{key}" do
      make_quicktag_end_pair(value)
    end
  end

  def start_ol(attrs)
    self.in_ol = true
  end

  def end_ol
    self.in_ol = false
    write("\n")
  end

  def start_ul(attrs)
    self.in_ul = true
  end

  def end_ul
    self.in_ul = false
    write("\n")
  end

  def start_li(attrs)
    if self.in_ol
      write("# ")
    else
      write("* ")
    end

    start_capture("li")
  end

  def end_li
    stop_capture_and_write
    write("\n")
  end

  def start_a(attrs)
    attrs = attrs_to_hash(attrs)
    self.a_href = attrs['href']

    if self.a_href:
      write(" \"")
      start_capture("a")
    end
  end

  def end_a
    if self.a_href:
      stop_capture_and_write
      write(["\":", self.a_href, " "])
      self.a_href = false
    end
  end

  def attrs_to_hash(array)
    array.inject({}) { |collection, part| collection[part[0].downcase] = part[1]; collection }
  end

  def start_img(attrs)
    attrs = attrs_to_hash(attrs)
    write([" !", attrs["src"], "! "])
  end

  def end_img
  end

  def start_tr(attrs)
  end

  def end_tr
    write("|\n")
  end

  def start_td(attrs)
    write("|")
    start_capture("td")
  end

  def end_td
    stop_capture_and_write
    write("|")
  end

  def start_br(attrs)
    write("\n")
  end

  def unknown_starttag(tag, attrs)
    if @@permitted_tags.include?(tag)
      write(["<", tag])
      attrs.each do |key, value|
        if @@permitted_attributes.include?(key)
          write([" ", key, "=\"", value, "\""])
        end
      end
    end
  end

  def unknown_endtag(tag)
    if @@permitted_tags.include?(tag)
      write([""])
    end
  end

  # Return the textile after processing
  def to_textile
    result.join
  end

  # UNCONVERTED PYTHON METHODS
  #
  # def handle_charref(self, tag):
  #     self._write(unichr(int(tag)))
  #     
  # def handle_entityref(self, tag):
  #     if self.entitydefs.has_key(tag): 
  #         self._write(self.entitydefs[tag])
  # 
  # def handle_starttag(self, tag, method, attrs):
  #     method(dict(attrs))
  #     

end