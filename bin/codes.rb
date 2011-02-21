$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'rubygems'
require 'Generator'
require 'rdf'

Dir.glob("#{ ARGV[0]}/R*").each do |filename|
  generator = Generator.new( File.new(filename) )

  group = generator.fields["Technology Group"]
  code = generator.fields["Technology Code"]
  
  puts "#{group}, #{code}"    
end
