from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ScanViewSet, TargetViewSet

router = DefaultRouter()
router.register(r'scans', ScanViewSet,basename='scan')
router.register(r'targets', TargetViewSet, basename='target')

urlpatterns = [
    path('', include(router.urls)),
]