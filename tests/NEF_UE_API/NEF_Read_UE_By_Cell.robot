*** Settings ***
Documentation   This test file contains the test cases of the read by cell ue endpoint for NEF Emulator API.
Resource        /opt/robot-tests/resources/login.robot
Resource        /opt/robot-tests/resources/ue.robot
Resource        /opt/robot-tests/resources/gnb.robot
Resource        /opt/robot-tests/resources/cells.robot
Library         /opt/robot-tests/libraries/cell_commons.py
Library         /opt/robot-tests/libraries/gnb_commons.py
Library         /opt/robot-tests/libraries/ue_commons.py

*** Variables ***

*** Keywords ***


*** Test Cases ***

Read by cell invalid ue valid token
    [Tags]    read_by_cell_invalid_ue_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}
    ${resp}=    Read UE By Cell    %{NEF_URL}  ${token.json()['access_token']}    TESTTESTS    404
    Status Should Be    404  ${resp}
    