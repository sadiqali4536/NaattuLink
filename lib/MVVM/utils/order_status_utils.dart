class OrderStatusUtils {
  static String getOrderStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'confirmed':
        return 'Order Confirmed';
      case 'processing':
        return 'Processing';
      case 'shipped':
      case 'dispatched':
      case 'out_for_delivery':
      case 'delivered':
        return 'Order Dispatched';
      case 'cancelled':
        return 'Order Cancelled';
      default:
        return 'Order Status';
    }
  }

  static String getOrderStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'confirmed':
        return 'Your order has been confirmed successfully.';
      case 'processing':
        return 'The seller is preparing your order.';
      case 'shipped':
      case 'dispatched':
      case 'out_for_delivery':
      case 'delivered':
        return 'Your order has been dispatched. Track your shipment for updates.';
      case 'cancelled':
        return 'This order has been cancelled.';
      default:
        return 'Your order status has been updated.';
    }
  }
}
