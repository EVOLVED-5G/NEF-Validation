from evolved5g.sdk import  ServiceDiscoverer

def extract_user(certs_path, capif_host, capif_port):
    service_discoverer = ServiceDiscoverer(folder_path_for_certificates_and_api_key=certs_path,
                                           capif_host=capif_host,
                                           capif_https_port=capif_port
                                           )
    endpoints = service_discoverer.discover_service_apis()
    if len(endpoints)>0:
        ## The access token is always retrieved for a specific api name and a specific endpoint (that is mapped ton an api_id and aef_id)
        ## For the purposes of the example we retrieve the fist available
        api_name = endpoints["serviceAPIDescriptions"][0]["apiName"]
        api_id =  endpoints["serviceAPIDescriptions"][0]["apiId"]
        aef_id =  endpoints["serviceAPIDescriptions"][0]["aefProfiles"][0]["aefId"]
        access_token = service_discoverer.get_access_token(api_name,api_id,aef_id)
        return api_id, access_token
    else:
        return None, None