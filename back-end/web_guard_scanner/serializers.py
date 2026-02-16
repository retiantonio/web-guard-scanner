from rest_framework import serializers
from .models import Scan, Vulnerability, Target, Profile
from django.contrib.auth.models import User
from django.contrib.auth import authenticate

from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated

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

    owner = serializers.StringRelatedField(read_only=True)

    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    class Meta:
        model = Target
        fields = ['id', 'name', 'url', 'owner']


class RegisterSerializer(serializers.ModelSerializer):

    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ('username', 'email', 'password')

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password']
        )

        Profile.objects.create(user=user, user_type='STANDARD') 
        return user
    

class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        username = attrs.get("username")
        password = attrs.get("password")

        if username and password:
            user = authenticate(username=username, password=password)
            if not user:
                raise serializers.ValidationError("Invalid username or password.")
            
            if not user.is_active:
                raise serializers.ValidationError("This account is disabled.")
        else:
            raise serializers.ValidationError("Must include both 'username' and 'password'.")

        attrs["user"] = user
        return attrs
    
class ChangePlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = Profile
        fields = ['user_type']

    def validate_user_type(self, value):
        if value not in ['STANDARD', 'PRO']:
            raise serializers.ValidationError("Invalid plan type.")
        return value