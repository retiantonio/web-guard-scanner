from rest_framework import serializers
from .models import Scan, Vulnerability, Target

class VulnerabilitySerializer(serializers.ModelSerializer):
    class Meta:
        model = Vulnerability

        fields = ['id', 'type', 'details', 'url_found', 'severity']

class ScanSerializer(serializers.ModelSerializer):
    vulnerabilities = VulnerabilitySerializer(many=True, read_only=True)
    target_url = serializers.ReadOnlyField(source='target.url') 

    class Meta:
        model = Scan

        fields = [
            'id', 
            'target', 
            'target_url',
            'status', 
            'start_time', 
            'end_time', 
            'date', 
            'score', 
            'modules_selected',
            'vulnerabilities'
        ]
        
        read_only_fields = [
            'status', 
            'start_time', 
            'end_time', 
            'date', 
            'score', 
            'vulnerabilities'
        ]

class TargetSerializer(serializers.ModelSerializer):

    class Meta:
        model = Target
        fields = '__all__'