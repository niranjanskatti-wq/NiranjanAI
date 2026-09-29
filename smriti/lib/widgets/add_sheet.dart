import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/tokens.dart';
import '../data/enums.dart';

/// Bottom sheet behind the gold + button.
Future<void> showAddSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      builder: (ctx) {
        Widget option(IconData icon, Color color, String title, String sub, String route) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white),
              ),
              title: Text(title),
              subtitle: Text(sub),
              onTap: () {
                Navigator.pop(ctx);
                context.push(route);
              },
            );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('Add', style: context.text.headlineMedium),
              ),
              option(Icons.contacts_outlined, groupColor(EventGroup.birthday), 'Pick from contacts',
                  'Name, photo and numbers filled in', '/person/new?contacts=1'),
              option(Icons.person_add_alt_outlined, const Color(0xFF6E685D), 'Add a person manually',
                  'Type their details yourself', '/person/new'),
              option(Icons.favorite_outline, groupColor(EventGroup.anniversary), 'Couple event',
                  'One anniversary for two people', '/event/new?kind=couple'),
              option(Icons.event_note_outlined, groupColor(EventGroup.important), 'Important date',
                  'Insurance, passport, bills, service…', '/event/new?kind=other'),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
