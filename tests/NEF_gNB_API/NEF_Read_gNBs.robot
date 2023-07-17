*** Settings ***
Documentation   This test file contains the test cases of the read gnbs endpoint for NEF Emulator API.
Resource        /opt/robot-tests/resources/login.robot
Resource        /opt/robot-tests/resources/gnb.robot

*** Variables ***
${NEF_INVALID_TOKEN}    invalid.token

*** Keywords ***


*** Test Cases ***
Read gnbs valid token
    [Tags]    read_gnbs_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}

    ${resp}=    Read gNBs    %{NEF_URL}  ${token.json()['access_token']}
    Status Should Be    200  ${resp}

Read gnbs invalid token
    [Tags]    read_gnbs_invalid_token
    ${resp}=    Read gNBs    %{NEF_URL}  ${NEF_INVALID_TOKEN}    401   

    Status Should Be    401  ${resp}