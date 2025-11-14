from django.urls import path
from . import views

urlpatterns = [
    path('', views.myapp),
    path('name/api/', views.getData)
]