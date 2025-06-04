import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../models/hidden_gem.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService;
  
  Position? _currentPosition;
  String? _currentNeighborhood = 'Toronto 🍁';
  bool _isLocationEnabled = false;
  bool _hasLocationPermission = false;
  bool _isTrackingLocation = false;
  bool _isLoading = false;
  String? _locationError;
  List<HiddenGem> _nearbyGems = [];
  
  LocationProvider({required LocationService locationService}) 
      : _locationService = locationService {
    _initializeLocation();
  }

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentNeighborhood => _currentNeighborhood;
  bool get isLocationEnabled => _isLocationEnabled;
  bool get hasLocationPermission => _hasLocationPermission;
  bool get isTrackingLocation => _isTrackingLocation;
  bool get isLoading => _isLoading;
  String? get error => _locationError;
  List<HiddenGem> get nearbyGems => _nearbyGems;
  
  bool get isLocationAvailable => 
      _currentPosition != null && 
      _isLocationEnabled && 
      _hasLocationPermission;

  // Initialize location services
  Future<void> _initializeLocation() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _isLocationEnabled = await _locationService.isLocationServiceEnabled();
      _hasLocationPermission = await _locationService.checkLocationPermission();
      
      if (_isLocationEnabled && _hasLocationPermission) {
        await updateLocation();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _locationError = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Public method to initialize location
  Future<void> initializeLocation() async {
    await _initializeLocation();
  }

  // Disable location services
  void disableLocation() {
    stopLocationTracking();
    _isLocationEnabled = false;
    _hasLocationPermission = false;
    _currentPosition = null;
    _currentNeighborhood = 'Toronto 🍁';
    _locationError = null;
    notifyListeners();
  }

  // Request location permissions
  Future<bool> requestLocationPermission() async {
    try {
      _locationError = null;
      _isLoading = true;
      notifyListeners();
      
      final granted = await _locationService.requestLocationPermission();
      _hasLocationPermission = granted;
      
      if (granted) {
        _isLocationEnabled = await _locationService.isLocationServiceEnabled();
        if (_isLocationEnabled) {
          await updateLocation();
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return granted;
    } catch (e) {
      _locationError = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update current location
  Future<void> updateLocation() async {
    try {
      _locationError = null;
      _isLoading = true;
      notifyListeners();
      
      final position = await _locationService.getCurrentPosition();
      
      if (position != null) {
        _currentPosition = position;
        _currentNeighborhood = _locationService.getTorontoNeighborhood(
          position.latitude, 
          position.longitude,
        );
        
        // Check if within Toronto boundaries
        if (!_locationService.isWithinToronto(position)) {
          _locationError = 'You appear to be outside Toronto 🚧';
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _locationError = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start location tracking
  void startLocationTracking() {
    if (!_isTrackingLocation && _hasLocationPermission && _isLocationEnabled) {
      _isTrackingLocation = true;
      _locationService.startLocationTracking();
      
      // Listen for location updates
      _locationService.getPositionStream().listen(
        (Position position) {
          _currentPosition = position;
          _currentNeighborhood = _locationService.getTorontoNeighborhood(
            position.latitude,
            position.longitude,
          );
          notifyListeners();
        },
        onError: (error) {
          _locationError = error.toString();
          _isTrackingLocation = false;
          notifyListeners();
        },
      );
      
      notifyListeners();
    }
  }

  // Stop location tracking
  void stopLocationTracking() {
    if (_isTrackingLocation) {
      _isTrackingLocation = false;
      _locationService.stopLocationTracking();
      notifyListeners();
    }
  }

  // Find nearby gems
  void updateNearbyGems(List<HiddenGem> allGems, {double radiusKm = 5.0}) {
    if (_currentPosition != null) {
      _nearbyGems = _locationService.findClosestGems(
        allGems,
        _currentPosition!,
        radiusKm: radiusKm,
        maxResults: 20,
      );
      notifyListeners();
    }
  }

  // Get distance to a gem
  double? getDistanceToGem(HiddenGem gem) {
    if (_currentPosition == null) return null;
    
    return _locationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      gem.latitude,
      gem.longitude,
    );
  }

  // Get formatted distance to a gem
  String? getFormattedDistanceToGem(HiddenGem gem) {
    final distance = getDistanceToGem(gem);
    if (distance == null) return null;
    
    return _locationService.formatDistance(distance);
  }

  // Get direction to a gem
  String? getDirectionToGem(HiddenGem gem) {
    if (_currentPosition == null) return null;
    
    return _locationService.getDirectionToGem(gem, _currentPosition!);
  }

  // Check if user is near a gem
  bool isNearGem(HiddenGem gem) {
    if (_currentPosition == null) return false;
    
    return _locationService.isNearGem(gem, _currentPosition!);
  }

  // Get gems within walking distance (1km)
  List<HiddenGem> getWalkingDistanceGems(List<HiddenGem> allGems) {
    if (_currentPosition == null) return [];
    
    return _locationService.findClosestGems(
      allGems,
      _currentPosition!,
      radiusKm: 1.0,
      maxResults: 10,
    );
  }

  // Get gems for current neighborhood
  List<HiddenGem> getNeighborhoodGems(List<HiddenGem> allGems) {
    if (_currentPosition == null) return [];
    
    final currentNeighborhoodName = _currentNeighborhood?.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    
    return allGems.where((gem) {
      final gemNeighborhood = _locationService.getTorontoNeighborhood(
        gem.latitude,
        gem.longitude,
      );
      final gemNeighborhoodName = gemNeighborhood.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      
      return gemNeighborhoodName == currentNeighborhoodName;
    }).toList();
  }

  // Reset location data
  void resetLocation() {
    _currentPosition = null;
    _currentNeighborhood = 'Toronto 🍁';
    _locationError = null;
    _nearbyGems = [];
    stopLocationTracking();
    notifyListeners();
  }

  // Get location summary for display
  Map<String, dynamic> getLocationSummary() {
    return {
      'hasLocation': _currentPosition != null,
      'neighborhood': _currentNeighborhood,
      'isTracking': _isTrackingLocation,
      'nearbyGemsCount': _nearbyGems.length,
      'coordinates': _currentPosition != null 
          ? '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
          : null,
      'error': _locationError,
    };
  }

  @override
  void dispose() {
    stopLocationTracking();
    _locationService.dispose();
    super.dispose();
  }
} 