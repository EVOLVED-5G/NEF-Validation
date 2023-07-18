*** Settings ***
Documentation   This test file contains the test cases of the qos information endpoints for NEF Emulator API.
Resource        /opt/robot-tests/resources/qos_information.robot
Resource        /opt/robot-tests/resources/login.robot

*** Variables ***


*** Test Cases ***
Get qos characteristics valid token
    [Tags]    get_qos_characteristics_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}

    ${resp}=    Get QoS Characteristics  %{NEF_URL}   ${token.json()['access_token']}

    Status Should Be    200  ${resp}


Get active profiles invalid gnb valid token
    [Tags]    get_active_profiles_invalid_gnb_valid_token
    ${token}=    Get Access Token    %{NEF_URL}    %{ADMIN_USER}    %{ADMIN_PASS}

    ${resp}=    Get QoS Active Profiles  %{NEF_URL}   ${token.json()['access_token']}    CHANGE    404

    Status Should Be    404  ${resp}
