import django_filters
from .models import Apartment


class ApartmentFilter(django_filters.FilterSet):

    min_price = django_filters.NumberFilter(
        field_name="price_per_night",
        lookup_expr="gte"
    )

    max_price = django_filters.NumberFilter(
        field_name="price_per_night",
        lookup_expr="lte"
    )

    class Meta:
        model = Apartment
        fields = [
            "city",
            "rooms",
        ]