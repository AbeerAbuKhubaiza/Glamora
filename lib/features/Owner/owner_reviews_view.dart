
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/features/Home/data/repo/reviews_repository.dart';


class OwnerReviewsTab extends StatefulWidget {
  final String salonId;

  const OwnerReviewsTab({super.key, required this.salonId});

  @override
  State<OwnerReviewsTab> createState() => _OwnerReviewsTabState();
}

class _OwnerReviewsTabState extends State<OwnerReviewsTab> {
  final _repo = const ReviewsRepository();
  final _ref = FirebaseDatabase.instance.ref('reviews');

  late Future<List<Review>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchSalonReviews(widget.salonId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repo.fetchSalonReviews(widget.salonId);
    });
  }

  Future<void> _replyToReview(Review r) async {
    final controller = TextEditingController(text: r.ownerReply ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          r.ownerReply == null || r.ownerReply!.isEmpty
              ? 'Reply to review'
              : 'Edit reply',
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Write your reply here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final reply = controller.text.trim();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await _ref.child(r.id).update({
      'ownerReply': reply.isEmpty ? null : reply,
      'ownerReplyAt': reply.isEmpty ? null : nowIso,
    });

    await _refresh();
  }

  Future<void> _deleteReview(Review r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _ref.child(r.id).remove();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Review>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimaryColor),
          );
        }

        final reviews = snap.data!;
        if (reviews.isEmpty) {
          return const Center(
            child: Text('No reviews yet', style: TextStyle(color: Colors.grey)),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = reviews[i];
              final hasReply = (r.ownerReply ?? '').trim().isNotEmpty;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ratingStars(r.rating),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.createdAt.toLocal().toString().split('.').first,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'reply') {
                              _replyToReview(r);
                            } else if (val == 'delete') {
                              _deleteReview(r);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'reply',
                              child: Text('Reply / edit reply'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete review'),
                            ),
                          ],
                          child: const Icon(
                            Icons.more_vert,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    if ((r.comment ?? '').isNotEmpty)
                      Text(r.comment!, style: const TextStyle(fontSize: 13)),

                    if ((r.comment ?? '').isNotEmpty) const SizedBox(height: 8),

                    if (hasReply) _ownerReplyBubble(r),
                    if (!hasReply)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _replyToReview(r),
                          style: TextButton.styleFrom(
                            foregroundColor: kPrimaryColor,
                          ),
                          icon: const Icon(Icons.reply_outlined, size: 18),
                          label: const Text(
                            'Reply',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _ratingStars(int rating) {
    rating = rating.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 18,
          color: i < rating ? Colors.amber : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _ownerReplyBubble(Review r) {
    final ts = r.ownerReplyAt != null
        ? r.ownerReplyAt!.toLocal().toString().split('.').first
        : '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Owner reply',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(r.ownerReply ?? '', style: const TextStyle(fontSize: 13)),
          if (ts.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(ts, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _replyToReview(r),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                foregroundColor: kPrimaryColor,
              ),
              child: const Text('Edit reply', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}
