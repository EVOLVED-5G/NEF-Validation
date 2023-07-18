*** Settings ***
Documentation   This test file contains the test cases of the import scenario endpoint for NEF Emulator API.
Library         /opt/robot-tests/libraries/scenario.py
Resource        /opt/robot-tests/resources/ui.robot
Resource        /opt/robot-tests/resources/login.robot

*** Variables ***


*** Test Cases ***
Import valid scenario valid token
    [Tags]    import_valid_scenario_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}
    ${scenario}=    Run Keyword    scenario.Import Scenario
    ${resp}=    Import Scenario    %{NEF_URL}   ${token.json()['access_token']}    ${scenario}

    Status Should Be    200  ${resp}

Import invalid scenario valid token
    [Tags]    import_invalid_scenario_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}
    ${resp}=    Import Scenario    %{NEF_URL}   ${token.json()['access_token']}    {}    422

    Status Should Be    422  ${resp}
