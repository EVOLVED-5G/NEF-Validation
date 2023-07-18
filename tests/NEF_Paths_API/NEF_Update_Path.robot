*** Settings ***
Documentation   This test file contains the test cases of the update path endpoint for NEF Emulator API.
Resource        /opt/robot-tests/resources/login.robot
Resource        /opt/robot-tests/resources/path.robot
Library         /opt/robot-tests/libraries/path_commons.py


*** Variables ***

*** Keywords ***


*** Test Cases ***
Update valid path valid token
    [Tags]    update_valid_path_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}
    ${path}=    Run Keyword    Get Path

    ${resp}=    Create Path    %{NEF_URL}  ${token.json()['access_token']}  ${path}
    ${to_update}=    Set Variable    ${resp.json()}
    Remove From Dictionary    ${to_update}   description
    ${updated}=    Create Dictionary     &{to_update}    description=updated
    

    ${resp}=    Update Path    %{NEF_URL}  ${token.json()['access_token']}  ${updated}
    Status Should Be    200  ${resp}

    ${path_id}=     Set Variable    ${updated['id']}
    Delete Path    %{NEF_URL}  ${token.json()['access_token']}    ${path_id}
    
Update invalid path valid token
    [Tags]    update_invalid_path_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}
    ${path}=    Run Keyword    Get Path
    ${invalid}=    Create Dictionary    &{path}    id=-1
    ${resp}=    Update Path    %{NEF_URL}  ${token.json()['access_token']}  ${invalid}    404
    Status Should Be    404  ${resp}
