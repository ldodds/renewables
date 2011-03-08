require 'rubygems'
require 'rdf'
require 'hpricot'
require 'open-uri'
require 'Util'
require 'Vocabulary'

class Generator
  
  attr_reader :id
  attr_reader :fields
  attr_reader :statements
  
  def initialize(file)
    @id = File.basename(file.path)
    @uri = RDF::URI.new( Util.absolute_uri( "generator/#{@id}") )
    
    @file = file
    @doc = Hpricot(file.read)
    
    @name = @doc.at("h4").inner_text.sub("\226", "-").split(" : ")[1]
    
    @fields = Hash.new
    
    address = false
    @doc.search("table[1] tr").each do |row|
      field = row.at("td").inner_text.gsub(":", "")
      #value = Util.clean_ws( row.search("td")[1].inner_text.gsub(/ $/, "") )
      #if field == "" && address && value != ""
      #  @fields["Address"] << value
      #end
      
      #if field == "Address"
      #  address = true
      #  @fields["Address"] = [ value ]
      #else
      #  @fields[ field ] = value  
      #end
      
      if field == "Address"
        address = Util.clean_ws( row.search("td")[1].inner_text.gsub(/ $/, "") )
        if address != nil && address != ""
          value = Util.clean_ws( row.search("td")[1].inner_html.gsub("<br />", ",") )
          value = value.gsub(/, $/, "")
        else
          value = nil
        end
      else
        value = Util.clean_ws( row.search("td")[1].inner_text.gsub(/ $/, "") )
      end
          
      @fields[ field ] = value
               
    end
  
#    puts @fields.inspect
    
    @statements = Array.new

    read_coords()
    populate()
  end
    
  def read_coords()
    @doc.search("table[1] tr td a").each do |a|
      if a["href"].include?("tab=map")
        mapdoc = File.new("#{@file.path}-map").read
        match = mapdoc.match(/google.maps.LatLng\(([0-9\-\.]+), ([0-9\-\.]+)\)/)
        @lat, @long = match[1], match[2]
      end
    end
  end
  
  def add_statement(subject, predicate, object)
    @statements << RDF::Statement.new( subject, predicate, object )
  end
  
  def add_property(predicate, object)
    @statements << RDF::Statement.new( @uri, predicate, object )
  end
  
  def populate
    
    add_property( RDF.type, Vocabulary::RENEW.Generator )
    add_property( RDF.type, Vocabulary::ORG.Site )

    add_property( RDF::RDFS.label, RDF::Literal.new( @name ) )
    add_property( Vocabulary::DCTERMS.identifier, RDF::Literal.new( @id ) )

    #Only add address if we have an address or a location
    if ( @lat != nil || @fields["Postcode"] )
      
      @vcard = RDF::URI.new( Util.absolute_uri( "generator/#{@id}/vcard") )
      add_property( Vocabulary::ORG.siteAddress, @vcard)
      
      add_statement( @vcard, RDF.type, Vocabulary::VCARD.VCard )
      
      if @fields["Address"] != nil && @fields["Address"] != "" 
        add_statement( @vcard, Vocabulary::VCARD.fn, RDF::Literal.new( @fields["Address"] ) )
      else 
        add_statement( @vcard, Vocabulary::VCARD.fn, @name )
      end
      
      if @lat != nil && @long != nil 
        #add lat/long directly to the site
        add_property( Vocabulary::GEO.lat, RDF::Literal.new( @lat ) )
        add_property( Vocabulary::GEO.long, RDF::Literal.new( @long ) )
        
        #add lat/long as a Location associated with the vcard too
        location = RDF::URI.new( Util.absolute_uri( "generator/#{@id}/vcard/geo") )
        add_statement( @vcard, Vocabulary::VCARD.geo, location )
        add_statement( location, Vocabulary::VCARD.latitude, RDF::Literal.new( @lat ) )
        add_statement( location, Vocabulary::VCARD.longitude, RDF::Literal.new( @long ) )
      end
      
      if @fields["Postcode"] != ""
        @address = RDF::URI.new( Util.absolute_uri( "generator/#{@id}/vcard/adr") )
        
        add_statement( @vcard, Vocabulary::VCARD.adr, @address )
        #add post code as literal to address
        add_statement( @address, Vocabulary::VCARD["postal-code"], RDF::Literal.new( @fields["Postcode"] ) )
        #add as link to OS
        add_statement( @address, RDF::URI.new( "http://data.ordnancesurvey.co.uk/ontology/postcode/postcode" ), Util.postcode( @fields["Postcode"]) )
        
      end
      
      if @fields["Address"]       
        add_statement( @vcard, Vocabulary::VCARD.label, RDF::Literal.new( @fields["Address"] ) )
      end
        
      if ( @fields["Country"] && @address )
        add_statement( @address, Vocabulary::VCARD["country-name"], RDF::Literal.new( @fields["Country"] ) )
      end
                    
      country = Util::COUNTRIES[ @fields["Country"] ]
      if country != nil
        #add country to Site too
        add_property( Vocabulary::ADMIN_GEO.country, country )
      else
        puts "#{@id} Unknown country: #{@fields["Country"]}"
      end
            
    end
    
    if @fields["Installed Capacity (kW)"]
      capacity = @fields["Installed Capacity (kW)"].gsub(",", "").to_i
      add_property( Vocabulary::RENEW.installedCapacity, RDF::Literal.new( capacity ) )
    end

    if @fields["Accreditation Date"] != ""
      date = @fields["Accreditation Date"]
      add_property( Vocabulary::RENEW.accreditationDate, RDF::Literal.new( date, {:datatype => RDF::XSD.date } ) )
    end
            
    #Categories
    slug = Util.slug( @fields["Technology Group"] )
    category = RDF::URI.new( Util.absolute_uri( "category/#{slug}") )
    scheme = RDF::URI.new( Util.absolute_uri("category") )
    add_property( Vocabulary::RENEW.category,  category )
    add_statement( category, RDF.type, Vocabulary::SKOS.Concept )
    add_statement( category, Vocabulary::SKOS.inScheme, scheme )
    add_statement( category, RDF::RDFS.label, @fields["Technology Group"] )  
    add_statement( category, Vocabulary::SKOS.prefLabel, @fields["Technology Group"] )  
    
    #mark group as top-level concept      
    add_statement( scheme, Vocabulary::SKOS.hasTopConcept, category )
      
    slug = Util.slug( @fields["Technology Sub-group"] )
    code = RDF::URI.new( Util.absolute_uri( "category/#{slug}") )
    add_property( Vocabulary::RENEW.category, code )
    add_statement( code, RDF.type, Vocabulary::SKOS.Concept )
    add_statement( code, Vocabulary::SKOS.inScheme, scheme )
    add_statement( code, RDF::RDFS.label, @fields["Technology Sub-group"] )  
    add_statement( code, Vocabulary::SKOS.prefLabel, @fields["Technology Sub-group"] )  
    
    if @fields["Technology Sub-group"] != @fields["Technology Group"]
      add_statement( code, Vocabulary::SKOS.broader, category)     
      add_statement( category, Vocabulary::SKOS.narrower, code)
    end    
        
    #FIXME: DONG Energy / Centrica Renewable Energy
    if @fields["Developer"] != ""
      puts @fields["Developer"] if @fields["Developer"].include?("/") 
      slug = Util.slug(@fields["Developer"])
      developer_uri = RDF::URI.new( Util.absolute_uri("organisation/#{slug}"))
      add_property( Vocabulary::RENEW.developer, developer_uri)
      add_statement( developer_uri, RDF.type, Vocabulary::FOAF.Organization )
      add_statement( developer_uri, RDF.type, Vocabulary::ORG.Organization )
      add_statement( developer_uri, Vocabulary::FOAF.name, RDF::Literal.new( @fields["Developer"] ) ) 
      add_statement( developer_uri, Vocabulary::RENEW.developed, @uri )    
    end

    #FIXME: Natural Power/Fred Olsen
    #are these two separate companies?
    if @fields["Operator"] != ""      
      slug = Util.slug(@fields["Operator"])
      puts @fields["Operator"] if @fields["Operator"].include?("/")
      developer_uri = RDF::URI.new( Util.absolute_uri("organisation/#{slug}"))
      add_property( Vocabulary::RENEW.operator, developer_uri)
      add_statement( developer_uri, RDF.type, Vocabulary::FOAF.Organization )
      add_statement( developer_uri, RDF.type, Vocabulary::ORG.Organization )
      add_statement( developer_uri, Vocabulary::FOAF.name, RDF::Literal.new( @fields["Operator"] ) ) 
      add_statement( developer_uri, Vocabulary::RENEW.operates, @uri )    
    end

    #FIXME: centrica/dongenergy
    if @fields["Site Owner"] != ""
      slug = Util.slug(@fields["Site Owner"])
      puts @fields["Site Owner"] if @fields["Site Owner"].include?("/") 
      developer_uri = RDF::URI.new( Util.absolute_uri("organisation/#{slug}"))
      add_property( Vocabulary::ORG.siteOf, developer_uri)
      add_statement( developer_uri, RDF.type, Vocabulary::FOAF.Organization )
      add_statement( developer_uri, RDF.type, Vocabulary::ORG.Organization )
      add_statement( developer_uri, Vocabulary::FOAF.name, RDF::Literal.new( @fields["Site Owner"] ) ) 
      add_statement( developer_uri, Vocabulary::ORG.hasSite, @uri )
    end

    #Fields for Wind stations
    if @fields["Number of Wind Turbines"] != ""
      turbines = RDF::URI.new( Util.absolute_uri( "generator/#{@id}/turbines") )
      add_property( Vocabulary::RENEW.installation, turbines )
      add_statement( turbines, RDF.type, Vocabulary::RENEW.WindTurbineInstallation)
      add_statement( turbines, Vocabulary::RENEW.site, @uri )
      add_statement( turbines, RDF::RDFS.label, RDF::Literal.new( "Wind Turbine installation at #{@name}" )  )                    
      add_statement( turbines, Vocabulary::RENEW.numberOfTurbines, RDF::Literal.new( @fields["Number of Wind Turbines"].to_i  ) )      

      if @fields["Hub Height"]
        add_statement( turbines, Vocabulary::RENEW.hubHeight, RDF::Literal.new( @fields["Hub Height"].gsub(" m", "").to_f  ) )
      end

      if @fields["Blade Diameter"]
        add_statement( turbines, Vocabulary::RENEW.bladeDiameter, RDF::Literal.new( @fields["Blade Diameter"].gsub(" m", "").to_f  ) )
      end
      
      if @fields["Turbine Capacity (kW)"]
        capacity = @fields["Turbine Capacity (kW)"].gsub(",", "").to_i
        add_statement( turbines, Vocabulary::RENEW.turbineCapacity, capacity )
      end
      
      if @fields["Wind Turbine Model"]
        add_statement( turbines, Vocabulary::RENEW.turbineModel, RDF::Literal.new( @fields["Wind Turbine Model"]) )
      end
                    
    end
    
    #Now in separate tabs?
#    if @fields["Rolling Load Factor"] != ""
#      add_property( Vocabulary::RENEW.rollingLoadFactor, RDF::Literal.new( @fields["Rolling Load Factor"]  ) )
#    end
#    if @fields["Latest Annual Load F"] != ""
#      add_property( Vocabulary::RENEW.latestAnnualLoadFactor, RDF::Literal.new( @fields["Latest Annual Load F"]  ) )
#    end
    
                                            
    return statements
  end
  
end
