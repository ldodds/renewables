class Util
  
  COUNTRIES = {
    "England" => RDF::URI.new("http://statistics.data.gov.uk/doc/country/921"),
    "Scotland" => RDF::URI.new("http://statistics.data.gov.uk/doc/country/923"),
    "Wales" => RDF::URI.new("http://statistics.data.gov.uk/doc/country/924"),
    "Northern Ireland" => RDF::URI.new("http://statistics.data.gov.uk/doc/country/922")  
  }
  
  GENERATOR_MODELS = {
    "E48" => "Enercon E48",
    "E 48" => "Enercon E48",
    "E70" => "Enercon E70",
    "ENERCON E-44" => "Enercon E44",
    "Enercon E-48" => "Enercon E48",
    "Enercon E-66" => "Enercon E66",
    "MM82" => "Repower MM82"
  }
  
  def Util.slug(s)
    normalized = Util.normalize(s)
    normalized.gsub! /\./, ""
    normalized.gsub! /,/, ""
    return normalized    
  end 
  
  def Util.normalize(s)
    normalized = s.downcase
    normalized.gsub! /\s+/, ""
    normalized.gsub! /\(|\)/, ""
    
    normalized.gsub! /&/, ""
    normalized.gsub! /\?/, ""
    normalized.gsub! /\=/, ""
    
    return normalized    
  end 

  def Util.clean_ws(s)
    cleaned = s.gsub /^\r\n/, ""
    cleaned.gsub! /\n/, ""    
    cleaned.gsub! /\s{2,}/, " "
    cleaned.gsub! /^\s/, ""
    
    return cleaned
  end
  
  def Util.absolute_uri(s)
    return "http://data.kasabi.com/dataset/renewables/#{s}"    
  end
  
  def Util.postcode(code)
    return RDF::URI.new( "http://data.ordnancesurvey.co.uk/id/postcodeunit/#{code.gsub(" ", "")}" )
  end
    
end