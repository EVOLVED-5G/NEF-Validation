*** Settings ***
Library     /opt/robot-tests/libraries/helpers.py
Library     /opt/robot-tests/libraries/capif_token_extractor.py
Resource    /opt/robot-tests/resources/common/basicRequests.robot
Resource    /opt/robot-tests/resources/login.robot
Library          /opt/robot-tests/libraries/scenario.py

*** Variables ***

*** Keywords ***
Initialize Test, Register And Import Scenario

    [Arguments]    ${num} 

    # Extract APF_ID and ACCESS_TOKEN FROM CAPIF
    ${user_info}=   Run Keyword     Extract User    %{CERTS_PATH}   %{CAPIF_HOST}   %{CAPIF_HTTPS_PORT}
    Set Global Variable    ${APF_ID}    ${user_info[0]}
    Set Global Variable    ${NEF_BEARER}    ${user_info[1]}

    ${access_token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}

    ${json}=            Import Scenario Body    ${num}  

    Import Scenario     ${json}    ${access_token.json()['access_token']}