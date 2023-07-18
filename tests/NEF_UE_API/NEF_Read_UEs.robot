*** Settings ***
Documentation   This test file contains the test cases of the read ues endpoint for NEF Emulator API.
Resource        /opt/robot-tests/resources/login.robot
Resource        /opt/robot-tests/resources/ue.robot

*** Variables ***

*** Keywords ***


*** Test Cases ***
Read ues valid token
    [Tags]    read_ues_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}

    ${resp}=    Read UEs    %{NEF_URL}  ${token.json()['access_token']}
    Status Should Be    200  ${resp}

    
