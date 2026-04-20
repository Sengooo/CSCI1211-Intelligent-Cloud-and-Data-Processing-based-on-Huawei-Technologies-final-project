import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "settings.base")
django.setup()

from django.contrib.auth import get_user_model
User = get_user_model()

email = 'rakhat@example.com'

if not User.objects.filter(email=email).exists():
    User.objects.create_superuser(
        email=email,
        password='123',
        first_name='rakhat',
        last_name=''
    )
    print("Superuser created.")
else:
    u = User.objects.get(email=email)
    u.set_password('123')
    u.is_superuser = True
    u.is_staff = True
    u.save()
    print("Superuser updated.")
