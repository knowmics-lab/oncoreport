#!/usr/bin/python3
import datetime
import json
import logging
import requests
from enum import Enum
from typing import Optional, List
from requests.adapters import HTTPAdapter
from urllib3 import Retry

logging.basicConfig(level=logging.INFO)
logging.getLogger("requests").setLevel(logging.ERROR)
logging.getLogger("urllib3").setLevel(logging.ERROR)
logging.getLogger("metapub.config").setLevel(logging.ERROR)

REQUEST_TIMEOUT = 240
API_REQUEST_RETRY_STATUS_FORCELIST = (429, 500, 502, 503, 504)
DEFAULT_ONCOKB_URL = "https://www.oncokb.org"
ONCOKB_API_URL = DEFAULT_ONCOKB_URL + "/api"
ONCOKB_ANNOTATION_API_URL = ONCOKB_API_URL + "/v1"

ONCOKB_API_BEARER_TOKEN = ""

SENSITIVE_LEVELS = [
    'LEVEL_1',
    'LEVEL_2',
    'LEVEL_3A',
    'LEVEL_3B',
    'LEVEL_4',
]
RESISTANCE_LEVELS = [
    'LEVEL_R1',
    'LEVEL_R2'
]
RESISTSANCE = "Resistance"
SENSITIVE = "Sensitivity/Response"


class ReferenceGenome(Enum):
    hg19 = 'GRCh37'
    hg38 = 'GRCh38'


class GenomicChangeQuery:
    """A class to represent a genomic change query to the OncoKB API."""
    genomicLocation: str
    referenceGenome: str

    def __init__(self, chromosome: str, start: str, end: str, ref_allele: str, var_allele: str,
                 reference_genome: Optional[str] = None):
        chromosome = chromosome.strip()
        if chromosome.startswith('chr'):
            chromosome = chromosome[3:]
        self.genomicLocation = ','.join([chromosome, start, end, ref_allele, var_allele])
        if reference_genome is not None:
            self.referenceGenome = ReferenceGenome[reference_genome].value or ReferenceGenome.hg19.value
        else:
            self.referenceGenome = ReferenceGenome.hg19.value

    def get_genomic_location_parts(self) -> [str, str, str, str, str]:
        return self.genomicLocation.split(',')

    def __repr__(self):
        return f"GenomicChangeQuery(genomicLocation={self.genomicLocation}, referenceGenome={self.referenceGenome})"


def set_oncokb_api_token(t: str):
    """Set the OncoKB API token. This token is required to access the OncoKB API."""
    global ONCOKB_API_BEARER_TOKEN
    ONCOKB_API_BEARER_TOKEN = t.strip()


def validate_oncokb_token() -> bool:
    """Validate the OncoKB API token. This token is required to access the OncoKB API."""
    if ONCOKB_API_BEARER_TOKEN is None or not ONCOKB_API_BEARER_TOKEN:
        return False

    response = requests.get(ONCOKB_API_URL + "/tokens/" + ONCOKB_API_BEARER_TOKEN, timeout=REQUEST_TIMEOUT)
    if response.status_code == 200:
        token = response.json()
        expiration_date = datetime.datetime.strptime(token['expiration'], "%Y-%m-%dT%H:%M:%SZ")
        days_from_expiration = expiration_date - datetime.datetime.now()
        if days_from_expiration.days < 0:
            return False
        else:
            return True
    else:
        return False


def requests_retry_session(
        retries=3,
        backoff_factor=0.3,
        status_force_list=API_REQUEST_RETRY_STATUS_FORCELIST,
        allowed_methods=('GET', 'HEAD'),
        session: Optional[requests.Session] = None,
) -> requests.Session:
    """Set up a requests session with retries and backoff."""
    session = session or requests.Session()
    retry = Retry(
        total=retries,
        read=retries,
        connect=retries,
        backoff_factor=backoff_factor,
        status_forcelist=status_force_list,
        allowed_methods=allowed_methods,
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount('http://', adapter)
    session.mount('https://', adapter)
    return session


def make_oncokb_post_request(url, body):
    """Make a POST request to the OncoKB API."""
    headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer %s' % ONCOKB_API_BEARER_TOKEN
    }
    return requests_retry_session(allowed_methods=["POST"]).post(url, headers=headers,
                                                                 data=json.dumps(body, default=lambda o: o.__dict__),
                                                                 timeout=REQUEST_TIMEOUT)


def make_oncokb_get_request(url):
    """Make a GET request to the OncoKB API."""
    headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer %s' % ONCOKB_API_BEARER_TOKEN
    }
    return requests_retry_session(allowed_methods=["HEAD", "GET"]).get(url, headers=headers, timeout=REQUEST_TIMEOUT)


def query_genomic_change(queries: List[GenomicChangeQuery]):
    """Query the OncoKB API for a list of genomic changes."""
    url = ONCOKB_ANNOTATION_API_URL + '/annotate/mutations/byGenomicChange'
    response = make_oncokb_post_request(url, queries)
    if response.status_code == 401:
        raise Exception('unauthorized')
    annotation = []
    if response.status_code == 200:
        annotation = response.json()
    else:
        for query in queries:
            geturl = url + '?'
            geturl += 'genomicLocation=' + query.genomicLocation
            geturl += '&referenceGenome=' + query.referenceGenome
            getresponse = make_oncokb_get_request(geturl)
            if getresponse.status_code == 200:
                annotation.append(getresponse.json())
            else:
                print('Error on annotating the url ' + geturl)
                annotation.append(None)
    return annotation


def get_tumor_name(tumor_type):
    """Get the tumor name from the tumor type."""
    if tumor_type["name"]:
        return tumor_type["name"]
    else:
        return tumor_type["mainType"]["name"]


def process_treatment_annotation(treatment, variant_summary, res_start: List[str], res_end: List[str]):
    disease = get_tumor_name(treatment["levelAssociatedCancerType"])
    if not disease:
        return None
    drug = ','.join([drug["drugName"] for drug in treatment["drugs"]])
    drug_interaction_type = "Combination" if len(treatment["drugs"]) > 1 else "NA"
    description = treatment["description"]
    pmids = treatment["pmids"]
    level = treatment["level"]
    is_resistence = level in RESISTANCE_LEVELS
    is_sensitive = level in SENSITIVE_LEVELS
    clinical_significance = SENSITIVE if is_sensitive else RESISTSANCE if is_resistence else "Unknown"
    record = res_start + [
        disease, drug, drug_interaction_type, "Predictive", level,
        "Supports", clinical_significance, description, variant_summary,
        pmids, []
    ] + res_end
    return record


def process_prognostic_annotation(prognostic, variant_summary, res_start: List[str], res_end: List[str]):
    disease = get_tumor_name(prognostic["tumorType"])
    if not disease:
        return None
    description = prognostic["description"]
    if not description:
        return None
    pmids = prognostic["pmids"]
    level = prognostic["levelOfEvidence"]
    record = res_start + [
        disease, "NA", "NA", "Prognostic", level, "Supports", "NA", description, variant_summary, pmids, []
    ] + res_end
    return record


def process_diagnostic_annotation(diagnostic, variant_summary, res_start: List[str], res_end: List[str]):
    disease = get_tumor_name(diagnostic["tumorType"])
    if not disease:
        return None
    description = diagnostic["description"]
    if not description:
        return None
    pmids = diagnostic["pmids"]
    level = diagnostic["levelOfEvidence"]
    record = res_start + [
        disease, "NA", "NA", "Prognostic", level, "Supports", "NA", description, variant_summary, pmids, []
    ] + res_end
    return record


def process_annotation(annotation, original_query: GenomicChangeQuery, variant_type: str):
    """Process the annotation from the OncoKB API."""
    if annotation is None:
        return None
    if not annotation["geneExist"] or not annotation["variantExist"]:
        return None
    query = annotation["query"]
    treatments = annotation["treatments"]
    records = []
    variant_summary = annotation["variantSummary"]
    res_start = ["OncoKB", query["hugoSymbol"], query["alteration"]]
    res_end = original_query.get_genomic_location_parts() + [variant_type]
    if len(treatments) > 0:
        for treatment in treatments:
            record = process_treatment_annotation(treatment, variant_summary, res_start, res_end)
            if record is not None:
                records.append(record)
    if len(annotation["prognosticImplications"]) > 0:
        for prognostic in annotation["prognosticImplications"]:
            record = process_prognostic_annotation(prognostic, variant_summary, res_start, res_end)
            if record is not None:
                records.append(record)
    if len(annotation["diagnosticImplications"]) > 0:
        for diagnostic in annotation["diagnosticImplications"]:
            record = process_diagnostic_annotation(diagnostic, variant_summary, res_start, res_end)
            if record is not None:
                records.append(record)
    return records
