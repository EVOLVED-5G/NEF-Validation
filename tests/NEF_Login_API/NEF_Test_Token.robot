*** Settings ***
Documentation   This test file contains the test cases of the test_token endpoint for NEF Emulator API.
Resource        /opt/robot-tests/resources/login.robot

*** Variables ***
${NEF_INVALID_TOKEN}              invalidtoken

*** Keywords ***


*** Test Cases ***
Test valid access token
    [Tags]    test_valid_access_token

    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}
    ${resp}=    Test Token  %{NEF_URL}  ${token.json()['access_token']}

    Status Should Be    200  ${resp}

Test invalid access token
    [Tags]    test_invalid_access_token
    
    ${resp}=    Test Token    %{NEF_URL}    ${NEF_INVALID_TOKEN}    401

    Status Should Be    401  ${resp}