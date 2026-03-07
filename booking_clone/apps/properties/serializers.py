from rest_framework import serializers
from .models import Apartment

class ApartmentSerializer(serializers.ModelSerializer):
    # This makes the city output as "Paris" instead of ID "5"
    owner = serializers.ReadOnlyField(source="owner.email")

    class Meta:
        model = Apartment
        fields = [
            "id",
            "title",
            "description",
            "address",
            "city",
            "price_per_night",
            "rooms",
            "owner",
            "created_at",
        ]
        read_only_fields = ["owner", "created_at"]