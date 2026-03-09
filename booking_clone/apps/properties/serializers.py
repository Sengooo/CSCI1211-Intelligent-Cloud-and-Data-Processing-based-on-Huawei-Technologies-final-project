from rest_framework import serializers
from .models import Apartment, City



class CitySerializer(serializers.ModelSerializer):
    class Meta:
        model = City
        fields = ["id", "name"]


class ApartmentSerializer(serializers.ModelSerializer):

    owner = serializers.ReadOnlyField(source="owner.email")

    city = CitySerializer(read_only=True)
    city_id = serializers.PrimaryKeyRelatedField(
        queryset=City.objects.all(),
        source="city",
        write_only=True
    )

    class Meta:
        model = Apartment
        fields = [
            "id",
            "title",
            "description",
            "address",
            "city",
            "city_id",
            "price_per_night",
            "rooms",
            "owner",
            "created_at",
        ]
        read_only_fields = ["owner", "created_at"]