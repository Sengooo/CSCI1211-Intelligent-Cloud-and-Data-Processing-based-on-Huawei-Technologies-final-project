"""Environment-specific settings that override or extend the shared base configuration.

You can place secrets, debug flags, host lists, or any other values that
should vary between deployments in this file.  The base module imports
everything defined here so values here will shadow the base defaults.
"""

from dotenv import load_dotenv
import os
from decouple import config
from datetime import timedelta

load_dotenv()

ENV_POSSIBLE_OPTIONS = (
    "local",
    "prod",
)
ENV_ID = config("DJANGORLAR_ENV_ID", cast=str)

SECRET_KEY = os.getenv("SECRET_KEY")

