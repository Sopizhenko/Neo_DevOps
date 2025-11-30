from django.contrib import admin
from django.urls import path
from django.http import JsonResponse

def home(request):
    return JsonResponse({
        'status': 'success',
        'message': 'Django app is running!',
        'version': '1.0.0'
    })

def health(request):
    return JsonResponse({'status': 'healthy'})

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', home, name='home'),
    path('health/', health, name='health'),
]
