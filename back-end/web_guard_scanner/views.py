from django.shortcuts import render
from rest_framework.response import Response
from rest_framework.decorators import api_view

# Create your views here.
# request Handler

def myapp(request):
    return render(request, "main.html")

@api_view(['GET', 'POST'])
def getData(request):
    data = {"name" : ["Tiuca Paul", "Reti Antonio"]}
    return Response(data)

