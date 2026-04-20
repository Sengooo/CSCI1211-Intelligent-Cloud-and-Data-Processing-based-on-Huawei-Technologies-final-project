import os
import django
import json
import re

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'settings.base')
django.setup()

from apps.properties.models import Apartment, City, Country
from django.contrib.auth import get_user_model

User = get_user_model()

def run():
    print("Starting seeding process...")

    # Load JSON
    json_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'seed.json')
    if not os.path.exists(json_path):
        print(f"File not found: {json_path}")
        return

    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Create default user
    owner, _ = User.objects.get_or_create(email='admin@example.com', defaults={'first_name': 'Admin'})
    if not owner.password:
        owner.set_password('admin')
        owner.save()

    # Create default Country and City
    country, _ = Country.objects.get_or_create(name='Kazakhstan')
    city, _ = City.objects.get_or_create(name='Almaty', defaults={'country': country})

    apartments_created = 0
    for item in data:
        title = item.get("Title", "Квартира")
        description = item.get("Text Preview", "")
        address = item.get("Subtitle", "")
        
        # Parse rooms
        rooms = 1
        room_match = re.search(r'(\d+)-комнатная', title)
        if room_match:
            rooms = int(room_match.group(1))
            
        # Parse price
        price_per_night = 0.0
        price_str = item.get("Price", "")
        price_match = re.search(r'([\d\s]+)〒', price_str)
        if price_match:
            price_clean = price_match.group(1).replace(' ', '')
            price_per_night = float(price_clean)

        Apartment.objects.create(
            title=title,
            description=description,
            address=address,
            city=city,
            price_per_night=price_per_night,
            rooms=rooms,
            owner=owner
        )
        apartments_created += 1

    print(f"Successfully created {apartments_created} apartments!")

if __name__ == '__main__':
    run()
