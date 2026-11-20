import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../domain/entities/post.dart';
import '../../domain/validators/post_validator.dart';
import '../bloc/create_post/create_post_cubit.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  static Route<Post> route() => MaterialPageRoute<Post>(
        builder: (_) => BlocProvider(
          create: (_) => sl<CreatePostCubit>()..loadAuthors(),
          child: const CreatePostPage(),
        ),
      );

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
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
    // Подсказки под полями — для удобства; окончательную проверку
    // делает CreatePostUseCase по тем же правилам.
    if (!_formKey.currentState!.validate()) return;
    context.read<CreatePostCubit>().submit(
          title: _titleController.text,
          body: _bodyController.text,
          userId: _userId,
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
            content: Text(
                state.submitFailure?.message ?? 'Не удалось отправить пост'),
            action: SnackBarAction(
              label: 'Повторить',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: _submit,
            ),
          ));
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Новый пост')),
          body: state.submitStatus == SubmitStatus.success
              ? _CreatedPostView(post: state.createdPost!)
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
            maxLength: PostValidator.titleMax,
            decoration: const InputDecoration(
              labelText: 'Заголовок *',
              helperText: 'От ${PostValidator.titleMin} до '
                  '${PostValidator.titleMax} символов',
              border: OutlineInputBorder(),
            ),
            validator: PostValidator.title,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bodyController,
            enabled: enabled,
            maxLength: PostValidator.bodyMax,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Текст *',
              helperText: 'От ${PostValidator.bodyMin} до '
                  '${PostValidator.bodyMax} символов',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            validator: PostValidator.body,
          ),
          const SizedBox(height: 12),
          _buildAuthorField(context, state, enabled),
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

  Widget _buildAuthorField(
      BuildContext context, CreatePostState state, bool enabled) {
    const decoration = InputDecoration(
      labelText: 'Автор *',
      border: OutlineInputBorder(),
    );
    switch (state.authorsStatus) {
      case AuthorsStatus.loading:
        return const InputDecorator(
          decoration: decoration,
          child: LinearProgressIndicator(),
        );
      case AuthorsStatus.failure:
      case AuthorsStatus.empty:
        return InputDecorator(
          decoration: decoration.copyWith(
            errorText: state.authorsStatus == AuthorsStatus.empty
                ? 'Список авторов пуст'
                : state.authorsFailure?.message,
            errorMaxLines: 3,
          ),
          child: TextButton.icon(
            onPressed: context.read<CreatePostCubit>().loadAuthors,
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        );
      case AuthorsStatus.success:
        return DropdownButtonFormField<int>(
          initialValue: _userId,
          isExpanded: true,
          decoration: decoration,
          items: [
            for (final a in state.authors)
              DropdownMenuItem(
                value: a.id,
                child: Text('${a.name} (userId ${a.id})',
                    overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: enabled ? (v) => setState(() => _userId = v) : null,
          validator: PostValidator.author,
        );
    }
  }
}

/// Что вернул сервер на POST. Показываются поля сущности, а не JSON.
class _CreatedPostView extends StatelessWidget {
  final Post post;

  const _CreatedPostView({required this.post});

  @override
  Widget build(BuildContext context) {
    // Кнопка «Назад» тоже возвращает пост, чтобы он не потерялся.
    return PopScope<Post>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, post);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text('Сервер принял пост')),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(title: const Text('id'), trailing: Text('${post.id}')),
                ListTile(
                    title: const Text('userId'),
                    trailing: Text('${post.userId}')),
                ListTile(
                    title: const Text('Заголовок'),
                    subtitle: Text(post.title)),
                ListTile(
                    title: const Text('Текст'), subtitle: Text(post.body)),
              ],
            ),
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
      ),
    );
  }
}
