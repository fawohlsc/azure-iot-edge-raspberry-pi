# Copyright (c) Microsoft. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for
# full license information.

import asyncio
import json
import os
import sys
import signal
import threading
from azure.iot.device.aio import IoTHubModuleClient
from sense_hat import SenseHat


# Event indicating client stop
stop_event = threading.Event()


async def read_sensehat(client):
    # Periodically send readings from Raspberry Pi Sense HAT to Azure IoT Hub
    sense = SenseHat()
    sense.clear()

    while True:
        message = json.dumps({
            "deviceId": os.environ["IOTEDGE_DEVICEID"],
            "humidity": round(sense.get_humidity(), 2),
            "pressure": round(sense.get_pressure(), 2),
            "temperature": round(sense.get_temperature(), 2)
        })
        print("{}".format(message))
        await client.send_message_to_output(message, "output1")

        await asyncio.sleep(15)


def main():
    if not sys.version >= "3.5.3":
        raise Exception(
            "The sample requires python 3.5.3+. Current version of Python: %s" % sys.version)
    print("IoT Hub Client for Raspberry Pi Sense HAT")

    client = IoTHubModuleClient.create_from_edge_environment()

    # Define a handler to cleanup when module is is terminated by Edge
    def module_termination_handler(signal, frame):
        print("IoT Hub Client stopped by Edge")
        stop_event.set()

    # Set the Edge termination handler
    signal.signal(signal.SIGTERM, module_termination_handler)

    # Periodically send readings from Raspberry Pi Sense HAT to Azure IoT Hub.
    loop = asyncio.get_event_loop()
    try:
        loop.run_until_complete(read_sensehat(client))
    except Exception as e:
        print("Unexpected error %s " % e)
        raise
    finally:
        print("Shutting down IoT Hub Client...")
        loop.run_until_complete(client.shutdown())
        loop.close()


if __name__ == "__main__":
    main()
