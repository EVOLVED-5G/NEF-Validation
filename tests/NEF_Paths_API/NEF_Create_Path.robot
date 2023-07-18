*** Settings ***
Documentation   This test file contains the test cases of the create path endpoint for NEF Emulator API.
Resource        /opt/robot-tests/resources/login.robot
Resource        /opt/robot-tests/resources/path.robot
Library         /opt/robot-tests/libraries/path_commons.py


*** Variables ***

*** Keywords ***


*** Test Cases ***
Create valid path valid token
    [Tags]    create_valid_path_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}
    ${path}=    Run Keyword    Get Path

    ${resp}=    Create Path    %{NEF_URL}  ${token.json()['access_token']}  ${path}
    Status Should Be    200  ${resp}

    ${path_id}=     Set Variable    ${resp.json()['id']}
    Delete Path    %{NEF_URL}  ${token.json()['access_token']}    ${path_id}
    