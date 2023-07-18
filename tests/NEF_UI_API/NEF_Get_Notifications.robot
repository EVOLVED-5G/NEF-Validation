*** Settings ***
Documentation   This test file contains the test cases of the get notifications endpoint for NEF Emulator API.
Resource        /opt/robot-tests/resources/ui.robot
Resource        /opt/robot-tests/resources/login.robot

*** Variables ***


*** Test Cases ***
Get notifications valid token
    [Tags]    get_notifications_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}

    ${resp}=    Get Notifications  %{NEF_URL}   ${token.json()['access_token']}

    Status Should Be    200  ${resp}
