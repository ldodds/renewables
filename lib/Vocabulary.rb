class Vocabulary

  FOAF = RDF::Vocabulary.new("http://xmlns.com/foaf/0.1/")
  DCTERMS = RDF::Vocabulary.new("http://purl.org/dc/terms/")
  OWL = RDF::Vocabulary.new("http://www.w3.org/2002/07/owl#")
  RENEW = RDF::Vocabulary.new("http://data.kasabi.com/dataset/renewables/schema/generators/")
  
  SKOS = RDF::Vocabulary.new("http://www.w3.org/2004/02/skos/core#")
  GEO = RDF::Vocabulary.new("http://www.w3.org/2003/01/geo/wgs84_pos#")
  
  ADMIN_GEO = RDF::Vocabulary.new("http://statistics.data.gov.uk/def/administrative-geography/")  

  ORG = RDF::Vocabulary.new("http://www.w3.org/ns/org#")
  
  VCARD= RDF::Vocabulary.new("http://www.w3.org/2006/vcard/ns#")
end