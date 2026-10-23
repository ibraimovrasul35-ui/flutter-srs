import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../state/create_post_cubit.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CreatePostCubit(context.read<PostRepository>())..loadUsers(),
      child: const _CreatePostView(),
    );
  }
}

class _CreatePostView extends StatefulWidget {
  const _CreatePostView();

  @override
  State<_CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<_CreatePostView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  int? _userId;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CreatePostCubit>().submit(
          title: _titleController.text,
          body: _bodyController.text,
          userId: _userId!,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreatePostCubit, CreatePostState>(
      listenWhen: (a, b) => a.submitStatus != b.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == SubmitStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text(state.errorMessage ?? 'Не удалось отправить пост'),
          ));
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Новый пост')),
          body: state.submitStatus == SubmitStatus.success
              ? _ResultView(post: state.createdPost!)
              : _buildForm(context, state),
        );
      },
    );
  }

  Widget _buildForm(BuildContext context, CreatePostState state) {
    final enabled = !state.isSubmitting;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _titleController,
            enabled: enabled,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Заголовок *',
              helperText: 'От 5 до 100 символов',
              border: OutlineInputBorder(),
            ),
            validator: CreatePostCubit.validateTitle,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bodyController,
            enabled: enabled,
            maxLength: 1000,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Текст *',
              helperText: 'От 10 до 1000 символов',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            validator: CreatePostCubit.validateBody,
          ),
          const SizedBox(height: 12),
          _buildUserField(context, state, enabled),
          const SizedBox(height: 24),
          FilledButton.icon(
            // Во время запроса кнопка заблокирована — повторно не отправить.
            onPressed: enabled ? _submit : null,
            icon: state.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(state.isSubmitting ? 'Отправка…' : 'Отправить'),
          ),
          const SizedBox(height: 12),
          const Text(
            'JSONPlaceholder принимает POST, но не сохраняет пост на сервере. '
            'Поэтому созданный пост будет показан в списке с пометкой '
            '«создан локально».',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildUserField(
      BuildContext context, CreatePostState state, bool enabled) {
    switch (state.usersStatus) {
      case UsersStatus.loading:
        return const InputDecorator(
          decoration: InputDecoration(
            labelText: 'Автор *',
            border: OutlineInputBorder(),
          ),
          child: LinearProgressIndicator(),
        );
      case UsersStatus.failure:
        return InputDecorator(
          decoration: InputDecoration(
            labelText: 'Автор *',
            errorText: state.errorMessage ?? 'Не удалось загрузить авторов',
            border: const OutlineInputBorder(),
          ),
          child: TextButton.icon(
            onPressed: context.read<CreatePostCubit>().loadUsers,
            icon: const Icon(Icons.refresh),
            label: const Text('Загрузить список авторов ещё раз'),
          ),
        );
      case UsersStatus.success:
        return DropdownButtonFormField<int>(
          initialValue: _userId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Автор *',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final u in state.users)
              DropdownMenuItem(
                value: u.id,
                child: Text('${u.name} (userId ${u.id})',
                    overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: enabled ? (v) => setState(() => _userId = v) : null,
          validator: CreatePostCubit.validateUser,
        );
    }
  }
}

/// Показывает объект, который вернул сервер на POST.
class _ResultView extends StatelessWidget {
  final Post post;

  const _ResultView({required this.post});

  @override
  Widget build(BuildContext context) {
    final json = const JsonEncoder.withIndent('  ').convert(post.toJson());
    // Кнопка «Назад» тоже возвращает пост, чтобы он не потерялся.
    return PopScope<Post>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, post);
      },
      child: _buildContent(context, json),
    );
  }

  Widget _buildContent(BuildContext context, String json) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Expanded(child: Text('Сервер принял пост (HTTP 201)')),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Ответ сервера:'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(json,
              style: const TextStyle(fontFamily: 'monospace')),
        ),
        const SizedBox(height: 12),
        Text(
          'id = ${post.id} выдал сервер, но пост там не сохранён. '
          'В списке он появится с пометкой «создан локально».',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pop(context, post),
          child: const Text('Добавить в список'),
        ),
      ],
    );
  }
}
