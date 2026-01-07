from celery import shared_task
from .scanner.scan_manager import ScanManager

@shared_task
def execute_scan_task(scan_id):
    scan_manager = ScanManager(scan_id)
    scan_manager.run_scan()