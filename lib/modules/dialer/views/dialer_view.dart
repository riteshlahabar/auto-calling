// lib/modules/dialer/views/dialer_view.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/tiles/current_call_tile.dart';
import '../../../core/tiles/next_queue_tile.dart';
import '../../../core/widget/app_bottom_nav.dart';
import '../../../core/widget/progress_bar.dart';
import '../../../core/widget/stat_card.dart';
import '../controllers/dialer_controller.dart';

class DialerView extends GetView<DialerController> {
  const DialerView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false, // block default pop; we’ll logout instead
      onPopInvoked: (didPop) {
        if (!didPop) {
          controller.logout(); // manual logout on back
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // remove default back button
          centerTitle: true,
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          title: Row(
            mainAxisSize:
                MainAxisSize.min, // keep row compact so it can be centered
            children: [
              Image.asset(
                'assets/images/logo.png', // update to your asset path
                height: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Turnkey Dialer',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Logout',
              onPressed: controller.logout,
              icon: Transform.rotate(
                angle: -math.pi / 2, // 90° up
                child: const Icon(Icons.logout_rounded),
              ),
            ),
          ],
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              final s = controller.stats.value;
              final progressPct = (s.progress * 100).toStringAsFixed(0);
              final cur = controller.current.value;
              final nxt = controller.next.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (controller.statusText.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        controller.statusText.value,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Call Progress',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${s.connected}/${s.total}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ProgressBar(value: s.progress),
                  const SizedBox(height: 16),
                  Text(
                    'Call Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => StatCard(
                            label: 'Dialed',
                            value:
                                '${controller.dailyDialed.value}', // backend dialed_calls [web:604]
                            valueColor: cs.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(
                          () => StatCard(
                            label: 'Connected',
                            value:
                                '${controller.dailyConnected.value}', // backend connected_calls [web:604]
                            valueColor: cs.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'Pending',
                          value:
                              '${controller.stats.value.pending}', // keep local pending if desired
                          valueColor: cs.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Current Call',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CurrentCallTile(
                    name: cur.displayName,
                    number: cur.displayNumber,
                    duration: _format(cur.duration),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Next in Queue',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                  NextQueueTile(
                    name: nxt.displayName,
                    number: nxt.displayNumber,
                    status: controller.isRunning.value ? 'Waiting...' : 'Idle',                    
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => FilledButton.icon(
                            onPressed: controller.isRunning.value
                                ? null
                                : controller.start,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(
                          () => OutlinedButton.icon(
                            onPressed: controller.isRunning.value
                                ? controller.stop
                                : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Progress: $progressPct%',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              );
            }),
          ),
        ),
        bottomNavigationBar: Obx(
          () => AppBottomNav(
            currentIndex: controller.navIndex.value,
            onTap: controller.setNav,
          ),
        ),
      ),
    );
  }

  String _format(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
