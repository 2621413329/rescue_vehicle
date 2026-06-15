import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/cart_risk_card.dart';
import '../../dashboard/models/dashboard_models.dart';

final cartListProvider = FutureProvider<List<CartRiskRank>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final list = await api.getList('/labels/cart-risks', query: {'limit': 20});
  return list.map((e) => CartRiskRank.fromJson(e as Map<String, dynamic>)).toList();
});

class CartListPage extends ConsumerWidget {
  const CartListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cartListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('抢救车管理')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (carts) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: carts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final c = carts[i];
            return CartRiskCard(
              rank: c.rank,
              cartName: c.cartName,
              location: c.location,
              riskScore: c.riskScore,
              expiredCount: c.expiredCount,
              nearExpiryCount: c.nearExpiryCount,
              lowStockCount: c.lowStockCount,
              onTap: () => context.push('/cart/${c.cartId}'),
            );
          },
        ),
      ),
    );
  }
}

class CartDetailPage extends ConsumerWidget {
  const CartDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('抢救车 #$id')),
      body: FutureBuilder(
        future: ref.read(apiClientProvider).get('/crash-carts/$id'),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          }
          final c = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: Text(c['cart_name'] as String? ?? ''),
                  subtitle: Text(c['location'] as String? ?? '未设置位置'),
                  trailing: Text(c['status'] as String? ?? ''),
                ),
              ),
              ListTile(
                title: const Text('层级管理'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/cart/$id/layers'),
              ),
              ListTile(
                title: const Text('风险分析'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/cart/risk'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CartRiskPage extends ConsumerWidget {
  const CartRiskPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cartListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('风险排行')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (carts) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: carts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final c = carts[i];
            return CartRiskCard(
              rank: c.rank,
              cartName: c.cartName,
              location: c.location,
              riskScore: c.riskScore,
              expiredCount: c.expiredCount,
              nearExpiryCount: c.nearExpiryCount,
              lowStockCount: c.lowStockCount,
            );
          },
        ),
      ),
    );
  }
}

class CartLayerPage extends ConsumerWidget {
  const CartLayerPage({super.key, required this.cartId});

  final int cartId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('层级管理')),
      body: FutureBuilder(
        future: ref.read(apiClientProvider).get('/crash-carts/layers/list', query: {
          'cart_id': cartId,
          'page': 1,
          'page_size': 50,
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('加载失败: ${snapshot.error}'));
          final layers = (snapshot.data!['items'] as List<dynamic>? ?? []);
          if (layers.isEmpty) return const Center(child: Text('暂无层级'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: layers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final l = layers[i] as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(l['layer_name'] as String? ?? ''),
                  subtitle: Text('第${l['layer_no']}层'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
