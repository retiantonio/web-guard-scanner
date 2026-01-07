from django.db import models
from django.contrib.auth.models import User

# Create your models here.
class Profile(models.Model):
    USER_TYPE_PLANS = [
                    ('STANDARD', 'Standard'), 
                    ('PRO', 'Pro')
    ]

    user = models.OneToOneField(User, on_delete= models.CASCADE)
    user_type = models.CharField(max_length= 10, choices= USER_TYPE_PLANS, default= 'STANDARD')

    subscription_date = models.DateField(null= True, blank = True)
    renewal_date = models.DateField(null= True, blank= True)

    def __str__(self):
        return f"{self.user.username}'s Profile"

class Target(models.Model):
    owner = models.ForeignKey(User, on_delete= models.CASCADE, related_name = 'targets')
    name = models.CharField(max_length= 255)
    url = models.URLField(max_length= 1024)

    def __str__(self):
        return self.url

class Scan(models.Model):
    STATUS_STATES = [
            ('STARTING', 'Starting'),
            ('RUNNING', 'Running'),
            ('COMPLETED', 'Completed'),
            ('FAILED', 'Failed')
    ]

    target = models.ForeignKey(Target, on_delete= models.CASCADE, related_name= 'scans')
    status = models.CharField(max_length= 10, choices= STATUS_STATES, default= 'Pending')

    start_time = models.DateTimeField(null= True, blank= True)
    end_time = models.DateTimeField(null= True, blank= True)
    date = models.DateField(null= True, blank= True)

    score = models.IntegerField(null= True, blank= True)

    modules_selected = models.JSONField(default= list)

    def __str__(self):
        return f"Scan for {self.target.url} | {self.status}"
    
class Vulnerability(models.Model):
    scan = models.ForeignKey(Scan, on_delete= models.CASCADE, related_name= 'vulnerabilities')
    type = models.CharField(max_length= 255)
    details = models.JSONField(default=dict)
    
    url_found = models.URLField(max_length= 2048, blank= True)
    severity = models.CharField(max_length= 50)

    def __str__(self):
        return self.type