from rest_framework import serializers
from .models import Apartment

class ApartmentSerializer(serializers.ModelSerializer):
    # This makes the city output as "Paris" instead of ID "5"
    city = serializers.StringRelatedField(read_only=True)

    class __all__:
        model = Apartment
        fields = ['id', 'title', 'description', 'price', 'city', 'created_at']