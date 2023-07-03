*** Settings ***
Documentation   This test file contains the test cases of the get last notifications endpoint for NEF Emulator API.
Resource        /opt/robot-tests/resources/ui.robot
Resource        /opt/robot-tests/resources/login.robot

*** Variables ***
${NEF_INVALID_TOKEN}              invalidtoken


*** Test Cases ***

Get notifications invalid token
    [Tags]    get_last_notifications_invalid_token

    ${resp}=    Get Last Notifications  %{NEF_URL}   ${NEF_INVALID_TOKEN}    -1    401

    Status Should Be    401  ${resp}