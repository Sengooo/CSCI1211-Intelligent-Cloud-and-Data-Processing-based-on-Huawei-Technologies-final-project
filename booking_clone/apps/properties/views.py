from rest_framework import viewsets
from django_filters.rest_framework import DjangoFilterBackend

from .models import Apartment
from .serializers import ApartmentSerializer
from .filters import ApartmentFilter
from .permissions import IsLandlordOrReadOnly, IsApartmentOwner



class ApartmentViewSet(viewsets.ModelViewSet):
    queryset = Apartment.objects.all()
    serializer_class = ApartmentSerializer

    filter_backends = [DjangoFilterBackend]
    filterset_class = ApartmentFilter

    permission_classes = [IsLandlordOrReadOnly, IsApartmentOwner]

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)