*** Settings ***
Documentation   This test file contains the test cases of the create_user endpoint for NEF Emulator API.
Resource        /opt/robot-tests/resources/login.robot
Resource        /opt/robot-tests/resources/users.robot
*** Variables ***

*** Keywords ***


*** Test Cases ***
Create valid user valid token
    [Tags]    create_valid_user_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}
    ${user}=    Create Dictionary    email=create-user-%{BUILD_NUMBER}@mail.com  is_active=true  is_superuser=false  full_name=create-user  password=pass
    ${resp}=    Create User    %{NEF_URL}  ${token.json()['access_token']}  ${user}

    Status Should Be    200  ${resp}

Create invalid user valid token
    [Tags]    create_invalid_user_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}

    ${resp}=    Create User    %{NEF_URL}  ${token.json()['access_token']}  {}  422
    Status Should Be    422  ${resp}
