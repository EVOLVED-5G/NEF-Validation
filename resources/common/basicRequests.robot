*** Settings ***
Documentation    This resource file contains the basic requests used by Nef.
Library          OperatingSystem
Library          RequestsLibrary
Library          Collections
Library          /opt/robot-tests/libraries/scenario.py


*** Variables ***
${NGINX_HOSTNAME}           %{NGINX_HOSTNAME}
${NETAPP_NOT_REGISTERED}    not-valid
${NEF_BEARER}   


*** keywords ***
Create NEF Session

    [Arguments]    ${server}=${NONE}    ${auth}=${NONE}

    Run Keyword If    "${server}" != "${NONE}"    Create Session    apisession    ${server}            verify=False
    ...               ELSE                        Create Session    apisession    ${NGINX_HOSTNAME}    verify=False

    ${headers}=    Run Keyword If    "${auth}" != "${NONE}" and "${auth}" != "${NETAPP_NOT_REGISTERED}"       Create Dictionary    Authorization=Bearer ${auth}  
    ...            ELSE IF           "${auth}" == "${NETAPP_NOT_REGISTERED}"                                  Create Dictionary    Authorization=Basic ${auth}  
    ...            ELSE IF           "${NEF_BEARER}" != ""                                                    Create Dictionary    Authorization=Bearer ${NEF_BEARER}                                                                             

    [Return]    ${headers}


Post Request Nef

    [Arguments]    ${endpoint}    ${json}=${NONE}    ${server}=${NONE}    ${auth}=${NONE}
    [Timeout]      60s

    ${headers}=    Create NEF Session    ${server}    ${auth}

    ${resp}=       POST On Session    apisession    ${endpoint}    headers=${headers}    json=${json}    expected_status=any

    [Return]       ${resp}


Get Request Nef

    [Arguments]    ${endpoint}    ${server}=${NONE}    ${auth}=${NONE}
    [Timeout]      60s

    ${headers}=    Create Nef Session    ${server}    ${auth}

    ${resp}=       GET On Session    apisession    ${endpoint}    headers=${headers}    expected_status=any

    [Return]       ${resp}


Put Request Nef

    [Arguments]    ${endpoint}    ${json}=${EMPTY}    ${server}=${NONE}    ${auth}=${NONE}
    [Timeout]      60s

    ${headers}=    Create NEF Session    ${server}    ${auth}

    ${resp}=    PUT On Session    apisession    ${endpoint}    headers=${headers}    json=${json}    expected_status=any

    [Return]    ${resp}


Delete Request Nef

    [Arguments]    ${endpoint}    ${server}=${NONE}    ${auth}=${NONE}
    [Timeout]      60s

    ${headers}=    Create NEF Session    ${server}    ${auth}

    ${resp}=    DELETE On Session    apisession    ${endpoint}    headers=${headers}    expected_status=any

    [Return]    ${resp}


Import Scenario

    [Arguments]     ${json}    ${access_token}
    
    ${resp}=    Post Request Nef    endpoint=/api/v1/utils/import/scenario    json=${json}     auth=${access_token}

    Should Be Equal As Strings    ${resp.status_code}    200
