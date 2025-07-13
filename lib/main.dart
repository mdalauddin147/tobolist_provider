 import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ----------------------- Models ------------------------

class MilestoneModel {
  final String title;
  final String category;
  final DateTime createdAt;
  final DateTime reminderTime;
  bool isCompleted;

  MilestoneModel({
    required this.title,
    required this.category,
    required this.createdAt,
    required this.reminderTime,
    this.isCompleted = false,
  });
}

// ------------------- Provider Logic ---------------------

class MilestoneHandlerProvider with ChangeNotifier {
  final List<MilestoneModel> _milestones = List<MilestoneModel>.generate(
    5,
    (int index) => MilestoneModel(
      title:
          'Milestone ${index + 1}:  Give each milestone a target completion date',
      category: 'Project ${index % 2 + 1}',
      createdAt: DateTime.now().subtract(Duration(days: index)),
      reminderTime: DateTime.now().add(Duration(hours: index + 1)),
      isCompleted: index % 3 == 0, // Some milestones are completed initially
    ),
  );

  String _searchQuery = '';

  List<MilestoneModel> get milestones {
    if (_searchQuery.isEmpty) return _milestones;
    return _milestones
        .where((MilestoneModel milestone) =>
            milestone.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            milestone.category.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addMilestone(MilestoneModel milestoneModel) async {
    _milestones.insert(0, milestoneModel); // Add at the top
    notifyListeners();
  }

  Future<void> completeMilestone({required int index}) async {
    // Get the milestone from the currently filtered list
    final MilestoneModel milestoneToComplete = milestones[index];
    // Find the corresponding milestone in the main list and update its status
    final int originalIndex = _milestones.indexOf(milestoneToComplete);
    if (originalIndex != -1) {
      _milestones[originalIndex].isCompleted = true;
      notifyListeners();
    }
  }

  Future<void> deleteMilestone(int index) async {
    // Get the milestone from the currently filtered list
    final MilestoneModel milestoneToDelete = milestones[index];
    // Remove the corresponding milestone from the main list
    _milestones.remove(milestoneToDelete);
    notifyListeners();
  }
}

// --------------------- UI Helper ------------------------

class PopupMenuHelper {
  static Widget buildPopupMenu(
    BuildContext context, {
    required void Function(String) onSelected,
    required List<Map<String, String>> optionsList,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: onSelected,
      itemBuilder: (BuildContext _) => optionsList
          .map<PopupMenuItem<String>>((Map<String, String> opt) =>
              PopupMenuItem<String>(
                value: opt.keys.first,
                child: Text(opt.values.first),
              ))
          .toList(),
    );
  }
}

// -------------------- Utility Functions -----------------

String formatDateTimeToString(DateTime dateTime) {
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

String formatTimeFromDateTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

// ----------------------- Main UI ------------------------

void main() {
  runApp(
    ChangeNotifierProvider<MilestoneHandlerProvider>(
      create: (BuildContext context) => MilestoneHandlerProvider(),
      builder: (BuildContext context, Widget? child) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MilestonePlannerScreen(),
      ),
    ),
  );
}

class MilestonePlannerScreen extends StatefulWidget {
  const MilestonePlannerScreen({super.key});

  @override
  State<MilestonePlannerScreen> createState() => _MilestonePlannerScreenState();
}

class _MilestonePlannerScreenState extends State<MilestonePlannerScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddMilestoneDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Milestone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    categoryController.text.isNotEmpty) {
                  final MilestoneModel newMilestone = MilestoneModel(
                    title: titleController.text,
                    category: categoryController.text,
                    createdAt: DateTime.now(),
                    reminderTime: DateTime.now().add(const Duration(hours: 1)),
                  );

                  Provider.of<MilestoneHandlerProvider>(dialogContext, listen: false)
                      .addMilestone(newMilestone);

                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showMilestoneDetailsDialog(BuildContext context, MilestoneModel milestone) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(milestone.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Category: ${milestone.category}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                    'Created At: ${formatDateTimeToString(milestone.createdAt)} at ${formatTimeFromDateTime(milestone.createdAt)}'),
                Text(
                    'Reminder Time: ${formatDateTimeToString(milestone.reminderTime)} at ${formatTimeFromDateTime(milestone.reminderTime)}'),
                Text('Status: ${milestone.isCompleted ? 'Completed' : 'Pending'}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final MilestoneHandlerProvider milestoneProvider =
        Provider.of<MilestoneHandlerProvider>(context);
    final List<MilestoneModel> milestones = milestoneProvider.milestones;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Milestone Planner'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearchBar(context);
            },
          )
        ],
      ),
      body: milestones.isEmpty
          ? const Center(child: Text('No milestones found'))
          : ListView.builder(
              itemCount: milestones.length,
              itemBuilder: (BuildContext listContext, int index) {
                final MilestoneModel milestone = milestones[index];
                final bool isCompleted = milestone.isCompleted;

                return Card(
                  elevation: 4,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: isCompleted
                      ? Colors.grey.shade100
                      : Colors.white, // Subtle color change for completed
                  child: InkWell(
                    onTap: () => _showMilestoneDetailsDialog(listContext, milestone),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Milestone Title (moved to top)
                          Text(
                            milestone.title,
                            style: TextStyle(
                              fontSize: 22, // Slightly larger
                              fontWeight: FontWeight.bold,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted ? Colors.grey : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2, // Allow title to wrap
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              // Category Chip
                              Chip(
                                label: Text(
                                  milestone.category,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                avatar: const Icon(Icons.label_outline,
                                    size: 16),
                                visualDensity: VisualDensity.compact,
                              ),
                              const Spacer(),
                              // Completion indicator (checkmark if completed)
                              if (isCompleted)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8.0),
                                  child: Icon(Icons.check_circle_outline,
                                      color: Colors.green),
                                ),
                              // PopupMenuHelper
                              PopupMenuHelper.buildPopupMenu(
                                listContext,
                                onSelected: (String value) async {
                                  switch (value) {
                                    case "complete":
                                      await Provider.of<MilestoneHandlerProvider>(
                                              listContext,
                                              listen: false)
                                          .completeMilestone(index: index);
                                      break;
                                    case "delete":
                                      await Provider.of<MilestoneHandlerProvider>(
                                              listContext,
                                              listen: false)
                                          .deleteMilestone(index);
                                      break;
                                  }
                                },
                                optionsList: <Map<String, String>>[
                                  if (!isCompleted) {"complete": "Complete"},
                                  {"delete": "Delete"}
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(height: 1, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Icon(Icons.calendar_today,
                                      size: 16, color: Colors.black54),
                                  const SizedBox(width: 6),
                                  Text(formatDateTimeToString(milestone.createdAt),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87)),
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  const Icon(Icons.alarm,
                                      size: 16, color: Colors.black54),
                                  const SizedBox(width: 6),
                                  Text(formatTimeFromDateTime(milestone.reminderTime),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMilestoneDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void showSearchBar(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Search Milestones'),
          content: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search by title or category',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (String query) {
              Provider.of<MilestoneHandlerProvider>(dialogContext, listen: false)
                  .updateSearchQuery(query);
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _searchController.clear();
                Provider.of<MilestoneHandlerProvider>(dialogContext, listen: false)
                    .updateSearchQuery('');
                Navigator.pop(dialogContext);
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}