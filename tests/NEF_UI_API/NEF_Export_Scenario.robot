*** Settings ***
Documentation   This test file contains the test cases of the export scenario endpoint for NEF Emulator API.
Resource        /opt/robot-tests/resources/ui.robot
Resource        /opt/robot-tests/resources/login.robot

*** Variables ***
${NEF_INVALID_TOKEN}              invalidtoken


*** Test Cases ***
Export scenario valid token
    [Tags]    export_scenario_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}

    ${resp}=    Export Scenario  %{NEF_URL}   ${token.json()['access_token']}

    Status Should Be    200  ${resp}

Export scenario invalid token
    [Tags]    export_scenario_invalid_token

    ${resp}=    Export Scenario  %{NEF_URL}   ${NEF_INVALID_TOKEN}    401

    Status Should Be    401  ${resp}