$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'rubygems'
require 'Generator'
require 'rdf'

nt_dir = ARGV[1]
if !File.exists?(nt_dir)
  d = Dir.mkdir(nt_dir)  
end

File.open("#{nt_dir}/renewables.nt", "w") do |f|

  Dir.glob("#{ ARGV[0]}/R*").each do |filename|
    if !filename.include?("-map")
     
      #puts filename
      generator = Generator.new( File.new(filename) )
                  
      #writer = RDF::NTriples::Writer.new( $stdout )
      writer = RDF::NTriples::Writer.new( f )
      generator.statements.each do |stmt|
        begin
          writer << stmt
        rescue => e
          puts filename
          puts e
          puts e.backtrace
        end
      end
      
    end
  end
    
  
end
