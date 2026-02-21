# treat the package as a thin wrapper around the base settings module
# so that DJANGO_SETTINGS_MODULE can continue to point at
# "booking_clone.settings" without breaking anything.

from .base import *  # noqa: F401,F403
