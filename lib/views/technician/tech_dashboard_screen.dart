import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class TechDashboardScreen extends StatefulWidget {
  const TechDashboardScreen({super.key});

  @override
  State<TechDashboardScreen> createState() => _TechDashboardScreenState();
}

class _TechDashboardScreenState extends State<TechDashboardScreen> {
  List<Booking> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
    });
    final all = await ApiService.getAllBookings();
    setState(() {
      _jobs = all;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Technician Portal'),
        actions: [
          IconButton(onPressed: _fetchJobs, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _jobs.isEmpty
              ? const Center(child: Text('No assigned jobs currently.'))
              : RefreshIndicator(
                  onRefresh: _fetchJobs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _jobs.length,
                    itemBuilder: (context, index) {
                      final job = _jobs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    job.bookingId,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16),
                                  ),
                                  Chip(
                                    label: Text(
                                      job.status,
                                      style: const TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                    backgroundColor: job.status == 'Completed'
                                        ? AppTheme.success
                                        : job.status == 'In Progress'
                                            ? Colors.orange
                                            : Colors.grey,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${job.deviceBrand} ${job.deviceModel}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text('Services: ${job.services.join(', ')}', style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(job.customerName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                  const Spacer(),
                                  const Icon(Icons.phone, size: 16, color: AppTheme.primary),
                                  const SizedBox(width: 6),
                                  Text(job.customerPhone),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(job.address, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (job.status != 'In Progress' && job.status != 'Completed') ...[
                                    OutlinedButton(
                                      onPressed: () async {
                                        await ApiService.updateBookingStatus(job.bookingId, 'In Progress');
                                        _fetchJobs();
                                      },
                                      child: const Text('Start Repair'),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (job.status != 'Completed') ...[
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.success,
                                        minimumSize: const Size(120, 40),
                                      ),
                                      onPressed: () async {
                                        await ApiService.updateBookingStatus(job.bookingId, 'Completed');
                                        _fetchJobs();
                                      },
                                      child: const Text('Mark Complete'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
