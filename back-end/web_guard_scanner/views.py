from django.shortcuts import render
from rest_framework.response import Response
from rest_framework.decorators import api_view, action
from rest_framework import viewsets, status
from .models import Scan, Target

from .scanner.modules.wafwoof_detection_module import WafwoofDetectionModule
from .scanner.modules.nmap_version_detection_module import NmapVersionDetectionModule 

from .tasks import execute_scan_task

import subprocess

from .serializers import ScanSerializer, TargetSerializer

# Create your views here.
# request Handler

def myapp(request):
    return render(request, "main.html")

@api_view(['GET', 'POST'])
def getData(request):
    data = {"name" : ["Tiuca Paul", "Reti Antonio"]}
    return Response(data)

class ScanViewSet(viewsets.ModelViewSet):
    queryset = Scan.objects.all()

    serializer_class = ScanSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        scan = serializer.save()
        execute_scan_task.delay(scan.id)

        headers = self.get_success_headers(serializer.data)

        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
    
class TargetViewSet(viewsets.ModelViewSet):
    queryset = Target.objects.all()

    serializer_class = TargetSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

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
