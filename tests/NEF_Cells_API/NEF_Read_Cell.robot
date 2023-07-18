*** Settings ***
Documentation   This test file contains the test cases of the read cell endpoint for NEF Emulator API.
Resource        /opt/robot-tests/resources/login.robot
Resource        /opt/robot-tests/resources/cells.robot
Resource        /opt/robot-tests/resources/gnb.robot
Library         /opt/robot-tests/libraries/cell_commons.py
Library         /opt/robot-tests/libraries/gnb_commons.py


*** Variables ***

*** Keywords ***


*** Test Cases ***
Read valid cell valid token
    [Tags]    read_valid_cell_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}
    ${gnb}=    Run Keyword    Get Gnb
    ${resp}=    Create gNB    %{NEF_URL}  ${token.json()['access_token']}  ${gnb}

    ${id}=    Set Variable    ${resp.json()['id']}
    ${cell}=    Run Keyword    Get Cell
    Remove From Dictionary    ${cell}    gNB_id
    ${updated}=    Create Dictionary    &{cell}    gNB_id=${id}
        
    Create Cell    %{NEF_URL}  ${token.json()['access_token']}  ${updated}
    
    ${resp}=     Read Cell    %{NEF_URL}  ${token.json()['access_token']}    ${cell['cell_id']}
    Status Should Be    200  ${resp}

    Delete gNB    %{NEF_URL}  ${token.json()['access_token']}    ${gnb['gNB_id']}
    
    Delete Cell    %{NEF_URL}  ${token.json()['access_token']}    ${cell['cell_id']}

Read invalid cell valid token
    [Tags]    read_invalid_cell_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS} 
    ${resp}=    Read Cell    %{NEF_URL}  ${token.json()['access_token']}    -1    404   

    Status Should Be    404  ${resp}
    