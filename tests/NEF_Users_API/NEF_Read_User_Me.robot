*** Settings ***
Documentation   This test file contains the test cases of the read_users_me endpoint for NEF Emulator API.
Resource        /opt/robot-tests/resources/login.robot
Resource        /opt/robot-tests/resources/users.robot
*** Variables ***

*** Keywords ***


*** Test Cases ***
Read user me valid token
    [Tags]    read_user_me_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}
    ${resp}=    Read User Me    %{NEF_URL}  ${token.json()['access_token']}
    
    Should Contain    ${resp.text}    %{ADMIN_USER}
    Status Should Be    200  ${resp}

