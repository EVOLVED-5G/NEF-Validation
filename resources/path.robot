*** Settings ***
Documentation    This resource file contains the basic requests used by Nef.
Library          OperatingSystem
Library          RequestsLibrary
Library          Collections

*** Variables ***

*** Keywords ***

Create Path
    [Arguments]    ${nef_url}    ${access_token}    ${body}    ${status}=200
    ${url}=    Set Variable    ${nef_url}/api/v1/paths
    ${headers}=    Create Dictionary     Authorization=Bearer ${access_token}  Content-Type=application/json; charset=utf-8
    ${body_string}    Evaluate    json.dumps(${body})    json
    ${response}=    POST    url=${url}    headers=${headers}    data=${body_string}  expected_status=${status}    verify=${False}

    [Return]     ${response}

Delete Path
    [Arguments]    ${nef_url}    ${access_token}    ${path_id}    ${status}=200
    ${url}=    Set Variable    ${nef_url}/api/v1/paths/${path_id}
    ${headers}=    Create Dictionary     Authorization=Bearer ${access_token}  Content-Type=application/json; charset=utf-8
    ${response}=    DELETE    url=${url}    headers=${headers}    expected_status=${status}    verify=${False}

    [Return]     ${response}

Update Path
    [Arguments]    ${nef_url}    ${access_token}    ${path}    ${status}=200
    ${path_id}=    Set Variable    ${path['id']}
    ${url}=    Set Variable    ${nef_url}/api/v1/paths/${path_id}
    ${headers}=    Create Dictionary     Authorization=Bearer ${access_token}  Content-Type=application/json; charset=utf-8
    ${body_string}    Evaluate    json.dumps(${path})    json
    ${response}=    PUT    url=${url}    headers=${headers}    data=${body_string}    expected_status=${status}    verify=${False}

    [Return]     ${response}

Read Path
    [Arguments]    ${nef_url}    ${access_token}    ${path_id}    ${status}=200
    ${url}=    Set Variable    ${nef_url}/api/v1/paths/${path_id}
    ${headers}=    Create Dictionary     Authorization=Bearer ${access_token}  Content-Type=application/json; charset=utf-8
    ${response}=    GET    url=${url}    headers=${headers}    expected_status=${status}    verify=${False}

    [Return]     ${response}

Read Paths
    [Arguments]    ${nef_url}    ${access_token}    ${status}=200
    ${url}=    Set Variable    ${nef_url}/api/v1/paths?skip=0&limit=10
    ${headers}=    Create Dictionary     Authorization=Bearer ${access_token}  Content-Type=application/json; charset=utf-8
    ${response}=    GET    url=${url}    headers=${headers}    expected_status=${status}    verify=${False}

    [Return]     ${response}    