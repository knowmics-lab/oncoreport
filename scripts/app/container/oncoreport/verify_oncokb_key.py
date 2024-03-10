#!/usr/bin/env python3
import argparse
import datetime
import requests
import os
from pathlib import Path
from dotenv import load_dotenv

parser = argparse.ArgumentParser(
    prog="verify_oncokb_key.py",
    description="Verify the OncoKB API key."
)
parser.add_argument("-e", "--env_file", help=".env file", default=None)
args = parser.parse_args()
env_file = args.env_file

if env_file is None or not os.path.exists(env_file):
    load_dotenv()
else:
    dotenv_path = Path(env_file)
    load_dotenv(dotenv_path=dotenv_path)

ONCOKB_API_BEARER_TOKEN = os.getenv('ONCOKB_BEARER_TOKEN')

if ONCOKB_API_BEARER_TOKEN is None or not ONCOKB_API_BEARER_TOKEN:
    print("No OncoKB token provided.")
    exit(1)

response = requests.get("https://www.oncokb.org/api/tokens/" + ONCOKB_API_BEARER_TOKEN, timeout=240)
if response.status_code == 200:
    token = response.json()
    expiration_date = datetime.datetime.strptime(token['expiration'], "%Y-%m-%dT%H:%M:%SZ")
    days_from_expiration = expiration_date - datetime.datetime.now()
    if days_from_expiration.days <= 0:
        print("OncoKB token expired.")
        exit(2)
    elif (days_from_expiration.days < 7):
        print("OncoKB token is valid but will expire soon.")
        exit(4)
    else:
        print(
            "OncoKB token is valid. You have " + 
            str(days_from_expiration.days) + 
            " days left before it expires.")
        exit(0)
else:
    print("Invalid OncoKB token.")
    exit(3)
