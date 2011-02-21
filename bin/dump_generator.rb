$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'rubygems'
require 'Generator'
require 'rdf'

file = File.new( ARGV[0] )
generator = Generator.new( file )

writer = RDF::NTriples::Writer.new( $stdout )
generator.statements.each do |stmt|
  writer << stmt
end
