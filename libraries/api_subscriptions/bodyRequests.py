def create_nef_subscription_body():
    return {
        "ipv4Addr": "10.0.0.1",
        "notificationDestination": "http://localhost:80/api/v1/utils/session-with-qos/callback",
        "snssai": {
            "sst": 1,
            "sd": "000001"
        },
        "dnn": "province1.mnc01.mcc202.gprs",
        "qosReference": 9,
        "altQoSReferences": [
            0
        ],
        "usageThreshold": {
            "duration": 0,
            "totalVolume": 0,
            "downlinkVolume": 0,
            "uplinkVolume": 0
        },
        "qosMonInfo": {
            "reqQosMonParams": [
                "DOWNLINK"
            ],
            "repFreqs": [
                "EVENT_TRIGGERED"
            ],
            "latThreshDl": 0,
            "latThreshUl": 0,
            "latThreshRp": 0,
            "waitTime": 0,
            "repPeriod": 0
        }
    }
