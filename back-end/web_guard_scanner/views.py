from django.shortcuts import render
from rest_framework.response import Response
from rest_framework.decorators import api_view, action
from rest_framework import viewsets, status
from rest_framework.views import APIView
from rest_framework.authtoken.models import Token
from rest_framework.permissions import IsAdminUser
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework.permissions import AllowAny

from django.shortcuts import get_object_or_404



from .models import Scan, Target, Profile

from .scanner.modules.wafwoof_detection_module import WafwoofDetectionModule
from .scanner.modules.nmap_version_detection_module import NmapVersionDetectionModule 

from .tasks import execute_scan_task


from .serializers import ScanSerializer, TargetSerializer, RegisterSerializer, LoginSerializer, ChangePlanSerializer

# Create your views here.
# request Handler

def myapp(request):
    return render(request, "main.html")

@api_view(['GET', 'POST'])
def getData(request):
    data = {"name" : ["Tiuca Paul", "Reti Antonio"]}
    return Response(data)

class ScanViewSet(viewsets.ModelViewSet):
    serializer_class = ScanSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        scan = serializer.save()
        execute_scan_task.delay(scan.id)

        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
    
    def get_queryset(self):
        user = self.request.user
        return Scan.objects.filter(target__owner=user).order_by('-start_time')

class TargetViewSet(viewsets.ModelViewSet):
    queryset = Target.objects.all()

    serializer_class = TargetSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)

    @action(detail=True, methods=['post'])
    def get_web_application_firewall(self, request, pk=None):
        target = self.get_object()

        waf_module = WafwoofDetectionModule() 
        result = waf_module.scan(target.url)
        if result:
            return Response({
                "status": "completed",
                "output": result
            })
        else:
            return Response({
                "status": "error",
                "message": "wafw00f failed"
            }, status=408)
    
    @action(detail=True, methods=['post'])
    def get_versions_and_engines(self, request, pk=None):
        target = self.get_object()
        
        nmap_module = NmapVersionDetectionModule()
        result = nmap_module.scan(target.url)
        if result:
              return Response({
                "status": "completed",
                "output": result
            })
        else:
            return Response({
                "status": "error",
                "message": "nmap failed"
            }, status=408)

    
class RegisterView(APIView):

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            token, created = Token.objects.get_or_create(user=user)
            
            return Response({
                "status": "success",
                "message": "User registered successfully",
                "token": token.key,
                "user_type": user.profile.user_type
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    

class LoginView(APIView):

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        user = serializer.validated_data['user']
        token, created = Token.objects.get_or_create(user=user)
        
        return Response({
            "token": token.key,
            "username": user.username,
            "user_type": user.profile.user_type,
            "message": "Login successful"
        })


class ChangeUserTypeView(APIView):
    
    # authentication_classes = [TokenAuthentication] 
    # permission_classes = [IsAuthenticated]

    def post(self, request):
        profile = get_object_or_404(Profile, user=request.user)
        
        serializer = ChangePlanSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response({
                "status": "success",
                "username": profile.user.username,
                "new_plan": profile.user_type
            })
        return Response(serializer.errors, status=400)