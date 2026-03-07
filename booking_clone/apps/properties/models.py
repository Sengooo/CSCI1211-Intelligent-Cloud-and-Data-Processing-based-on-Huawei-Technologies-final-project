from django.db import models
from django.conf import settings

# HACK: This allows to run migrations and test Apartment.
# Delete this block once the real City model appears.
class City(models.Model):
    name = models.CharField(max_length=100)
    def __str__(self):
        return self.name
    


class Apartment(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField()

    address = models.CharField(max_length=255)

    city = models.ForeignKey(City, on_delete=models.CASCADE, related_name="apartments")

    price_per_night = models.DecimalField(max_digits=10, decimal_places=2)
    rooms = models.IntegerField()

    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="apartments")


    created_at = models.DateTimeField(auto_now_add=True)
    def __str__(self):
        return self.title