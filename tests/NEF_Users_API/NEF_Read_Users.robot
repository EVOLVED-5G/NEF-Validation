*** Settings ***
Documentation   This test file contains the test cases of the read_users endpoint for NEF Emulator API.
Resource        /opt/robot-tests/resources/login.robot
Resource        /opt/robot-tests/resources/users.robot
*** Variables ***
${NEF_INVALID_TOKEN}    invalid.token

*** Keywords ***


*** Test Cases ***
Read users valid token
    [Tags]    read_users_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}
    ${resp}=    Read Users    %{NEF_URL}  ${token.json()['access_token']}

    Status Should Be    200  ${resp}

Read users invalid token
    [Tags]    read_users_invalid_token

    ${resp}=    Read Users    %{NEF_URL}  ${NEF_INVALID_TOKEN}  401

    Status Should Be    401  ${resp}