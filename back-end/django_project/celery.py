import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'django_project.settings')

app = Celery('django_project')

app.config_from_object('django.conf:settings', namespace='CELERY')

app.autodiscover_tasks()