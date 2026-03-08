from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework.test import APIClient
from rest_framework import status

from apps.users.models import CustomUser
from .models import Apartment, City


class ApartmentTests(APITestCase):

    def setUp(self):

        self.landlord = CustomUser.objects.create_user(
            email="landlord@test.com",
            password="testpass123",
            is_landlord=True
        )

        self.renter = CustomUser.objects.create_user(
            email="renter@test.com",
            password="testpass123",
            is_renter=True
        )

        self.city = City.objects.create(name="Almaty")

        self.client = APIClient()

    def test_landlord_can_create_apartment(self):

        self.client.force_authenticate(user=self.landlord)

        data = {
            "title": "Nice Apartment",
            "description": "Good place",
            "address": "Street 123",
            "city": self.city.id,
            "price_per_night": 500,
            "rooms": 2
        }

        response = self.client.post("/properties/apartments/", data)

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Apartment.objects.count(), 1)

    
    def test_renter_cannot_create_apartment(self):

        self.client.force_authenticate(user=self.renter)

        data = {
            "title": "Illegal Apartment",
            "description": "Should fail",
            "address": "Street 123",
            "city": self.city.id,
            "price_per_night": 500,
            "rooms": 2
        }

        response = self.client.post("/properties/apartments/", data)

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(Apartment.objects.count(), 0)

    
    def test_list_apartments(self): # get list of apartments

        Apartment.objects.create(
            title="Apt 1",
            description="Test",
            address="Addr",
            city=self.city,
            price_per_night=300,
            rooms=1,
            owner=self.landlord
        )

        response = self.client.get("/properties/apartments/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    
    def test_filter_apartments_by_city(self):

        Apartment.objects.create(
            title="City Apartment",
            description="Test",
            address="Addr",
            city=self.city,
            price_per_night=400,
            rooms=2,
            owner=self.landlord
        )

        response = self.client.get(f"/properties/apartments/?city={self.city.id}")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    
    def test_only_owner_can_update(self): # renter can't update

        apartment = Apartment.objects.create(
            title="Owner Apartment",
            description="Test",
            address="Addr",
            city=self.city,
            price_per_night=400,
            rooms=2,
            owner=self.landlord
        )

        self.client.force_authenticate(user=self.renter)

        response = self.client.patch(
            f"/properties/apartments/{apartment.id}/",
            {"title": "Hacked"}
        )

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)


    def test_owner_can_update(self): # only landlord can update

        apartment = Apartment.objects.create(
            title="Owner Apartment",
            description="Test",
            address="Addr",
            city=self.city,
            price_per_night=400,
            rooms=2,
            owner=self.landlord
        )

        self.client.force_authenticate(user=self.landlord)

        response = self.client.patch(
            f"/properties/apartments/{apartment.id}/",
            {"title": "Updated Title"}
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)

        apartment.refresh_from_db()
        self.assertEqual(apartment.title, "Updated Title")