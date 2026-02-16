from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ScanViewSet, TargetViewSet, LoginView, RegisterView, ChangeUserTypeView

router = DefaultRouter()
router.register(r'scans', ScanViewSet,basename='scan')
router.register(r'targets', TargetViewSet, basename='target')

urlpatterns = [
    path('', include(router.urls)),

    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('change-plan/', ChangeUserTypeView.as_view(), name='change-plan'),
]