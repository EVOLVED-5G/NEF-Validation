*** Settings ***
Documentation   This test file contains the test cases of the update user endpoint for NEF Emulator API.
Resource        /opt/robot-tests/resources/login.robot
Resource        /opt/robot-tests/resources/users.robot
*** Variables ***

*** Keywords ***


*** Test Cases ***
Update valid user valid token
    [Tags]    update_valid_user_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}
    ${user}=    Create Dictionary    email=update-user-%{BUILD_NUMBER}@mail.com  is_active=true  is_superuser=false  full_name=update-user  password=pass
    ${resp}=    Create User    %{NEF_URL}  ${token.json()['access_token']}  ${user}
    ${new_user}=    Set Variable    ${resp.json()}
    Remove From Dictionary    ${new_user}    full_name
    ${user}=    Create Dictionary    &{new_user}    full_name=updated  password=pass
    ${resp}=    Update User    %{NEF_URL}  ${token.json()['access_token']}  ${user}

    Status Should Be    200  ${resp}

Update invalid user valid token
    [Tags]    update_invalid_user_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}
    ${user}=    Create Dictionary    id=-1
    ${resp}=    Update User    %{NEF_URL}  ${token.json()['access_token']}  ${user}  404

    Status Should Be    404  ${resp}

