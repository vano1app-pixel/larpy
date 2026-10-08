#!/usr/bin/env python3
"""Register only Larpy's missing extension IDs; never claims managed approval."""
from asc_request import request

EXTENSIONS = {
    "com.vano.larpy.focus-monitor": "Larpy Focus Monitor",
    "com.vano.larpy.focus-shield": "Larpy Focus Shield",
    "com.vano.larpy.focus-action": "Larpy Focus Action",
}

def main():
    for identifier, name in EXTENSIONS.items():
        matches = request("/v1/bundleIds?filter[identifier]=" + identifier)["data"]
        if matches:
            record = matches[0]
            print(identifier + ": already registered")
        else:
            record = request("/v1/bundleIds", "POST", {"data": {
                "type": "bundleIds",
                "attributes": {"identifier": identifier, "name": name, "platform": "IOS"},
            }})["data"]
            print(identifier + ": registered")
        path = "/v1/bundleIds/" + record["id"] + "/bundleIdCapabilities"
        enabled = {item["attributes"]["capabilityType"] for item in request(path)["data"]}
        if "APP_GROUPS" not in enabled:
            request("/v1/bundleIdCapabilities", "POST", {"data": {
                "type": "bundleIdCapabilities",
                "attributes": {"capabilityType": "APP_GROUPS"},
                "relationships": {"bundleId": {"data": {"type": "bundleIds", "id": record["id"]}}},
            }})
        verified = {item["attributes"]["capabilityType"] for item in request(path)["data"]}
        if "APP_GROUPS" not in verified:
            raise RuntimeError(identifier + ": App Groups read-back failed")
        print(identifier + ": App Groups enabled (group association still requires verification)")
    print("Family Controls distribution approval is separate and must be checked in the Developer portal.")

if __name__ == "__main__":
    main()
