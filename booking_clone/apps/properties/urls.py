from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ApartmentViewSet, GenerateDescriptionAPIView

router = DefaultRouter()
router.register(r'apartments', ApartmentViewSet)

urlpatterns = [
    path('generate-description/', GenerateDescriptionAPIView.as_view(), name='generate-description'),
    path('', include(router.urls)),
]