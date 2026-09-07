import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';
import 'server_controller.dart';

class SubscriptionController extends ChangeNotifier {
  final StorageService _storageService;
  final SubscriptionService _subscriptionService;

  List<Subscription> _subscriptions = [];
  List<Subscription> get subscriptions => _subscriptions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  SubscriptionController(this._storageService, [SubscriptionService? subscriptionService])
      : _subscriptionService = subscriptionService ?? SubscriptionService() {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    _subscriptions = _storageService.loadSubscriptions();
    notifyListeners();
  }

  Future<bool> addSubscription({
    required String name,
    required String url,
    required ServerController serverController,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final subId = 'sub_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final result = await _subscriptionService.fetchSubscription(
        id: subId,
        name: name,
        url: url,
      );

      _subscriptions.add(result.subscription);
      _storageService.saveSubscriptions(_subscriptions);

      // Add downloaded nodes to server controller
      serverController.addMultiple(result.nodes);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSubscription(
    Subscription sub, {
    required ServerController serverController,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _subscriptionService.fetchSubscription(
        id: sub.id,
        name: sub.name,
        url: sub.url,
      );

      final index = _subscriptions.indexWhere((s) => s.id == sub.id);
      if (index != -1) {
        _subscriptions[index] = result.subscription;
      }
      _storageService.saveSubscriptions(_subscriptions);

      // Replace previous nodes belonging to this subscription
      serverController.removeSubscriptionNodes(sub.id);
      serverController.addMultiple(result.nodes);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> updateAll({required ServerController serverController}) async {
    if (_isLoading || _subscriptions.isEmpty) return;
    for (final sub in List<Subscription>.from(_subscriptions)) {
      await updateSubscription(sub, serverController: serverController);
    }
  }

  void deleteSubscription(String id, {required ServerController serverController}) {
    _subscriptions.removeWhere((s) => s.id == id);
    _storageService.saveSubscriptions(_subscriptions);
    serverController.removeSubscriptionNodes(id);
    notifyListeners();
  }
}
