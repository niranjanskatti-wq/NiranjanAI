import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import 'festival_model.dart';

/// Opens the right page for an entry: the festival page or the event page.
void openEntry(BuildContext context, EventEntry e) {
  if (e is FestivalEntry) {
    context.push('/festival?key=${Uri.encodeQueryComponent(e.festival.key)}');
  } else {
    context.push('/event/${e.event.id}');
  }
}
