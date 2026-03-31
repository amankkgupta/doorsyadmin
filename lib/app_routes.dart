import 'package:admindoorstep/auth/views/login_screen.dart';
import 'package:admindoorstep/home/views/home_screen.dart';
import 'package:admindoorstep/order/views/view_orders_screen.dart';
import 'package:admindoorstep/product/views/create_product_screen.dart';
import 'package:admindoorstep/update/views/create_update_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const login = '/';
  static const home = '/home';
  static const viewOrders = '/view-orders';
  static const createProduct = '/create-product';
  static const createUpdate = '/create-update';

  static Map<String, WidgetBuilder> get routes => {
        login: (_) => const LoginScreen(),
        home: (_) => const HomeScreen(),
        viewOrders: (_) => const ViewOrdersScreen(),
        createProduct: (_) => const CreateProductScreen(),
        createUpdate: (_) => const CreateUpdateScreen(),
      };
}
