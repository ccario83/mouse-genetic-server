import requests
import re
def biomart_annotate(rsNums):
    rsNums = ','.join(rsNums)
    biomart_url = "http://www.biomart.org/biomart/martservice?"
    query = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE Query>
<Query  virtualSchemaName = "default" formatter = "TSV" header = "0" uniqueRows = "0" count = "" datasetConfigVersion = "0.6" >
	<Dataset name = "mmusculus_snp" interface = "default" >
		<Filter name = "snp_filter" value = "%s"/>
		<Attribute name = "refsnp_id" />
		<Attribute name = "chr_name" />
		<Attribute name = "chrom_start" />
		<Attribute name = "chrom_strand" />
		<Attribute name = "synonym_name" />
		<Attribute name = "synonym_source" />
		<Attribute name = "ensembl_gene_stable_id" />
		<Attribute name = "consequence_type_tv" />
		<Attribute name = "consequence_allele_string" />
		<Attribute name = "ensembl_peptide_allele" />
		<Attribute name = "sift_prediction" />
		<Attribute name = "sift_score" />
	</Dataset>
</Query>""" % rsNums

    #print query
    query = re.sub('[\t\n\r]+','',query)
    query = re.sub(' +',' ',query)
    query = query + '\n'

    #headers = {'content-type': 'application/xml'}
    r = requests.post(biomart_url, data="query=%s"%query)
    text = r.raw.read()
    return text


html = biomart_annotate(['rs6167295','rs31701671','rs31895570','rs31895572','rs31896744','rs31896753','rs31897612','rs31890636'])
print html