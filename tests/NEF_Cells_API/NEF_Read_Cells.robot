*** Settings ***
Documentation   This test file contains the test cases of the read cells endpoint for NEF Emulator API.
Resource        /opt/robot-tests/resources/login.robot
Resource        /opt/robot-tests/resources/cells.robot

*** Variables ***
${NEF_INVALID_TOKEN}    invalid.token

*** Keywords ***


*** Test Cases ***
Read cells valid token
    [Tags]    read_cells_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}

    ${resp}=    Read Cells    %{NEF_URL}  ${token.json()['access_token']}
    Status Should Be    200  ${resp}

Read cells invalid token
    [Tags]    read_cells_invalid_token
    ${resp}=    Read Cells    %{NEF_URL}  ${NEF_INVALID_TOKEN}    401   

    Status Should Be    401  ${resp}