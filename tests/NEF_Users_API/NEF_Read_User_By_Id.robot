*** Settings ***
Documentation   This test file contains the test cases of the read user by id endpoint for NEF Emulator API.
Resource        /opt/robot-tests/resources/login.robot
Resource        /opt/robot-tests/resources/users.robot
*** Variables ***

*** Keywords ***


*** Test Cases ***
Read By Id valid user valid token
    [Tags]    read_by_id_valid_user_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}
    ${user}=    Create Dictionary    email=read-user-%{BUILD_NUMBER}@mail.com  is_active=true  is_superuser=false  full_name=read-user  password=pass
    ${resp}=    Create User    %{NEF_URL}  ${token.json()['access_token']}  ${user}
    ${user}=    Set Variable    ${resp.json()}
    ${resp}=    Read User By Id    %{NEF_URL}  ${token.json()['access_token']}  ${user}

    Should Contain    ${resp.text}    read-user-%{BUILD_NUMBER}@mail.com
    Status Should Be    200  ${resp}

Read By Id invalid user valid token
    [Tags]    read_by_id_invalid_user_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}
    ${user}=    Create Dictionary    id=-1
    ${resp}=    Read User By Id    %{NEF_URL}  ${token.json()['access_token']}  ${user}

    Should Contain    ${resp.text}    null
    Status Should Be    200  ${resp}

