import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/post.dart';
import '../bloc/favorites/favorites_cubit.dart';

/// Звёздочка «в избранное». Состояние берётся из общего FavoritesCubit,
/// поэтому одинаково выглядит в списке, деталях и на экране избранного.
class FavoriteButton extends StatelessWidget {
  final Post post;

  const FavoriteButton({super.key, required this.post});

  Future<void> _toggle(BuildContext context, bool wasFavorite) async {
    final messenger = ScaffoldMessenger.of(context);
    final failure = await context.read<FavoritesCubit>().toggle(post);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      duration: const Duration(seconds: 2),
      content: Text(failure?.message ??
          (wasFavorite ? 'Убрано из избранного' : 'Добавлено в избранное')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select<FavoritesCubit, bool>(
        (cubit) => cubit.state.isFavorite(post.id));
    return IconButton(
      tooltip: isFavorite ? 'Убрать из избранного' : 'В избранное',
      icon: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        color: isFavorite ? Colors.amber.shade700 : null,
      ),
      onPressed: () => _toggle(context, isFavorite),
    );
  }
}
