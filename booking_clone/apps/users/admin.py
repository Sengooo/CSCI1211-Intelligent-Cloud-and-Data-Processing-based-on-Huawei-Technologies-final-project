from django.contrib.admin import register
from django.contrib.auth.admin import UserAdmin

from apps.users.models import CustomUser


# Register your models here.
@register(CustomUser)
class CustomUserAdmin(UserAdmin):
    """Admin panel for User"""

    list_display = (
        "email",
        "first_name",
        "last_name",
        "is_landlord",
        "is_renter",
        "is_active",
        "is_staff",
        "is_superuser"
    )

    #searching
    search_fields = (
        "email",
        "first_name",
        "last_name",
    )
    #filters in right side
    list_filter = ("is_landlord", "is_renter", "is_active", "is_staff")
    #sorting by email
    ordering = ("email",)

    fieldsets = UserAdmin.fieldsets + (
        (None, {"fields": ("is_landlord", "is_renter")}),
    )

    add_fieldsets = UserAdmin.add_fieldsets + (
        (None, {"fields": ("is_landlord", "is_renter")}),
    )
