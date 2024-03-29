*** Settings ***
Documentation   This test file contains the test cases of the delete gnb endpoint for NEF Emulator API.
Resource        /opt/robot-tests/resources/login.robot
Resource        /opt/robot-tests/resources/gnb.robot
Library         /opt/robot-tests/libraries/gnb_commons.py

*** Variables ***
${NEF_INVALID_TOKEN}    invalidtoken

*** Keywords ***


*** Test Cases ***
Delete valid gnb valid token
    [Tags]    delete_valid_gnb_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}
    ${gnb}=    Run Keyword    Get Gnb
    Create gNB    %{NEF_URL}  ${token.json()['access_token']}  ${gnb}    

    ${gnb_id}=     Set Variable    ${gnb['gNB_id']}

    ${resp}=    Delete gNB    %{NEF_URL}  ${token.json()['access_token']}    ${gnb['gNB_id']}
    Status Should Be    200  ${resp}

Delete invalid gnb valid token
    [Tags]    delete_invalid_gnb_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}
    ${resp}=    Delete gNB    %{NEF_URL}  ${token.json()['access_token']}    -1    404   

    Status Should Be    404  ${resp}
    
Delete gnb invalid token
    [Tags]    delete_gnb_invalid_token
    ${resp}=    Delete gNB    %{NEF_URL}  ${NEF_INVALID_TOKEN}    {}    401   

    Status Should Be    401  ${resp}