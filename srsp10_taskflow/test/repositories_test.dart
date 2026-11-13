import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:srsp10_taskflow/core/app_exception.dart';
import 'package:srsp10_taskflow/data/database/app_database.dart';
import 'package:srsp10_taskflow/models/enums.dart';
import 'package:srsp10_taskflow/models/task_filter.dart';

import 'helpers.dart';

Matcher throwsAppError(String part) => throwsA(
  isA<AppException>().having((e) => e.message, 'message', contains(part)),
);

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());
  tearDown(() => env.dispose());

  group('Пользователи', () {
    test('создание и удаление пользователя', () async {
      final id = await env.user('Rasul');
      expect((await env.users.getUser(id))!.name, 'Rasul');

      await env.users.deleteUser(id);
      expect(await env.users.getUser(id), isNull);
    });

    test('email уникален (без учёта регистра)', () async {
      await env.users.createUser(name: 'A', email: 'same@test.kz');
      await expectLater(
        env.users.createUser(name: 'B', email: 'SAME@test.kz'),
        throwsAppError('уже существует'),
      );
      await expectLater(
        env.users.createUser(name: 'C', email: 'not-an-email'),
        throwsAppError('Некорректный email'),
      );
    });

    test('нельзя удалить пользователя с незавершёнными задачами', () async {
      final owner = await env.user('Owner');
      final worker = await env.user('Worker');
      final p = await env.project('P', owner, [worker]);
      final t = await env.tasks.createTask(
        projectId: p,
        title: 'Задача',
        assigneeId: worker,
        actorId: owner,
      );

      await expectLater(
        env.users.deleteUser(worker),
        throwsAppError('незавершённых задач'),
      );

      // После завершения задачи удалить можно, задача остаётся без исполнителя.
      await env.tasks.changeStatus(t, TaskStatus.done, actorId: owner);
      await env.users.deleteUser(worker);
      expect((await env.tasks.getTask(t))!.assigneeId, isNull);
    });
  });

  group('Проекты и участники', () {
    test('создание проекта: создатель становится Owner', () async {
      final owner = await env.user('Owner');
      final p = await env.projects.createProject(
        name: 'TaskFlow',
        description: 'Описание',
        ownerId: owner,
      );
      final project = await env.projects.getProject(p);
      expect(project!.name, 'TaskFlow');
      expect(project.status, ProjectStatus.active);

      final members = await env.projects.getMembers(p);
      expect(members.single.user.id, owner);
      expect(members.single.role, MemberRole.owner);
    });

    test('добавление участников, повторно добавить нельзя', () async {
      final owner = await env.user('Owner');
      final dev = await env.user('Dev');
      final p = await env.project('P', owner);

      await env.projects.addMember(p, dev, MemberRole.admin);
      expect(await env.projects.isMember(p, dev), isTrue);
      await expectLater(
        env.projects.addMember(p, dev, MemberRole.member),
        throwsAppError('уже участвует'),
      );
      expect((await env.projects.getMembers(p)).length, 2);
    });

    test('удаление проекта каскадно удаляет задачи и историю', () async {
      final owner = await env.user('Owner');
      final p = await env.project('P', owner);
      final t = await env.tasks.createTask(
        projectId: p,
        title: 'T',
        actorId: owner,
      );
      await env.projects.deleteProject(p);
      expect(await env.tasks.getTask(t), isNull);
      expect(await env.tasks.getHistory(t), isEmpty);
      expect(await env.projects.getMembers(p), isEmpty);
    });
  });

  group('Задачи', () {
    test('создание задачи пишет первую запись истории', () async {
      final owner = await env.user('Owner');
      final p = await env.project('P', owner);
      final t = await env.tasks.createTask(
        projectId: p,
        title: '  Сделать дизайн  ',
        priority: TaskPriority.high,
        deadline: env.inDays(2),
        actorId: owner,
      );

      final task = (await env.tasks.getTask(t))!;
      expect(task.title, 'Сделать дизайн');
      expect(task.status, TaskStatus.todo);
      expect(task.priority, TaskPriority.high);

      final history = await env.tasks.getHistory(t);
      expect(history.single.kind, HistoryKind.created);
      expect(history.single.changedBy, owner);
    });

    test('задачу нельзя создать без проекта', () async {
      final owner = await env.user('Owner');
      await expectLater(
        env.tasks.createTask(projectId: null, title: 'T', actorId: owner),
        throwsAppError('без проекта'),
      );
      await expectLater(
        env.tasks.createTask(projectId: 999, title: 'T', actorId: owner),
        throwsAppError('Проект не найден'),
      );
    });

    test('исполнитель должен состоять в проекте', () async {
      final owner = await env.user('Owner');
      final outsider = await env.user('Outsider');
      final p = await env.project('P', owner);

      await expectLater(
        env.tasks.createTask(
          projectId: p,
          title: 'T',
          assigneeId: outsider,
          actorId: owner,
        ),
        throwsAppError('участник проекта'),
      );

      final t = await env.tasks.createTask(
        projectId: p,
        title: 'T',
        actorId: owner,
      );
      await expectLater(
        env.tasks.reassign(t, outsider, actorId: owner),
        throwsAppError('участник проекта'),
      );
    });

    test('смена статуса сохраняется в истории', () async {
      final owner = await env.user('Owner');
      final p = await env.project('P', owner);
      final t = await env.tasks.createTask(
        projectId: p,
        title: 'T',
        actorId: owner,
      );

      await env.tasks.changeStatus(t, TaskStatus.inProgress, actorId: owner);
      await env.tasks.changeStatus(t, TaskStatus.done, actorId: owner);

      expect((await env.tasks.getTask(t))!.status, TaskStatus.done);
      final history = await env.tasks.getHistory(t);
      expect(history.map((h) => h.kind), [
        HistoryKind.created,
        HistoryKind.status,
        HistoryKind.status,
      ]);
      expect(history[1].oldStatus, TaskStatus.todo);
      expect(history[1].newStatus, TaskStatus.inProgress);
      expect(history[2].oldStatus, TaskStatus.inProgress);
      expect(history[2].newStatus, TaskStatus.done);
      expect(history.every((h) => h.changedBy == owner), isTrue);
    });

    test(
      'транзакция: ошибка записи истории отменяет создание задачи',
      () async {
        final owner = await env.user('Owner');
        final p = await env.project('P', owner);

        // Пользователя 9999 нет, поэтому запись истории нарушит внешний ключ.
        await expectLater(
          env.tasks.createTask(projectId: p, title: 'T', actorId: 9999),
          throwsA(anything),
        );
        expect(await env.tasks.countTasks(const TaskFilter()), 0);
        expect(await env.db.select(env.db.taskHistory).get(), isEmpty);
      },
    );

    test('переназначение исполнителя атомарно и попадает в историю', () async {
      final owner = await env.user('Owner');
      final a = await env.user('Alpha');
      final b = await env.user('Beta');
      final p = await env.project('P', owner, [a, b]);
      final t = await env.tasks.createTask(
        projectId: p,
        title: 'T',
        assigneeId: a,
        actorId: owner,
      );

      await env.tasks.reassign(t, b, actorId: owner);

      expect((await env.tasks.getTask(t))!.assigneeId, b);
      final last = (await env.tasks.getHistory(t)).last;
      expect(last.kind, HistoryKind.assignee);
      expect(last.details, 'Alpha → Beta');
    });

    test('Undo возвращает предыдущий статус', () async {
      final owner = await env.user('Owner');
      final p = await env.project('P', owner);
      final t = await env.tasks.createTask(
        projectId: p,
        title: 'T',
        actorId: owner,
      );
      await env.tasks.changeStatus(t, TaskStatus.inProgress, actorId: owner);
      await env.tasks.changeStatus(t, TaskStatus.done, actorId: owner);

      expect(
        await env.tasks.undoLastStatusChange(t, actorId: owner),
        TaskStatus.inProgress,
      );
      expect(
        await env.tasks.undoLastStatusChange(t, actorId: owner),
        TaskStatus.todo,
      );
      expect((await env.tasks.getTask(t))!.status, TaskStatus.todo);
      await expectLater(
        env.tasks.undoLastStatusChange(t, actorId: owner),
        throwsAppError('Нет изменений'),
      );
      expect(
        (await env.tasks.getHistory(t))
            .where((h) => h.kind == HistoryKind.undo),
        hasLength(2),
      );
    });

    test('не больше трёх незавершённых задач на один дедлайн', () async {
      final owner = await env.user('Owner');
      final dev = await env.user('Dev');
      final p = await env.project('P', owner, [dev]);
      final deadline = env.inDays(3);

      Future<int> create() => env.tasks.createTask(
        projectId: p,
        title: 'T',
        assigneeId: dev,
        deadline: deadline.add(const Duration(hours: 10)),
        actorId: owner,
      );

      final first = await create();
      await create();
      await create();
      await expectLater(create(), throwsAppError('уже 3 незавершённые'));

      // Завершённая задача в лимит не входит.
      await env.tasks.changeStatus(first, TaskStatus.done, actorId: owner);
      await create();
    });
  });

  group('Комментарии', () {
    test('добавление комментария и удаление только автором', () async {
      final owner = await env.user('Owner');
      final other = await env.user('Other');
      final p = await env.project('P', owner);
      final t = await env.tasks.createTask(
        projectId: p,
        title: 'T',
        actorId: owner,
      );

      final c = await env.comments.addComment(
        taskId: t,
        authorId: owner,
        text: 'Готово',
      );
      final list = await env.comments.watchComments(t).first;
      expect(list.single.comment.body, 'Готово');
      expect(list.single.author.id, owner);

      await expectLater(
        env.comments.deleteComment(c, userId: other),
        throwsAppError('только его автор'),
      );
      await env.comments.deleteComment(c, userId: owner);
      expect(await env.comments.watchComments(t).first, isEmpty);
    });

    test('нельзя комментировать несуществующую задачу', () async {
      final owner = await env.user('Owner');
      await expectLater(
        env.comments.addComment(taskId: 42, authorId: owner, text: 'Hi'),
        throwsAppError('несуществующую задачу'),
      );
    });
  });

  group('Корзина (Soft Delete)', () {
    test('удалённая задача пропадает из списков и видна в корзине', () async {
      final owner = await env.user('Owner');
      final p = await env.project('P', owner);
      final t = await env.tasks.createTask(
        projectId: p,
        title: 'T',
        actorId: owner,
      );

      await env.tasks.moveToTrash(t);

      expect(await env.tasks.getTask(t), isNotNull); // физически не удалена
      expect(await env.tasks.countTasks(const TaskFilter()), 0);
      final trash = await env.tasks.getTasks(
        const TaskFilter(deletedOnly: true),
      );
      expect(trash.single.task.id, t);
    });

    test('восстановление и полное удаление задачи', () async {
      final owner = await env.user('Owner');
      final p = await env.project('P', owner);
      final t1 = await env.tasks.createTask(
        projectId: p,
        title: 'Восстановить',
        actorId: owner,
      );
      final t2 = await env.tasks.createTask(
        projectId: p,
        title: 'Удалить',
        actorId: owner,
      );

      await env.tasks.moveToTrash(t1);
      await env.tasks.restore(t1);
      expect((await env.tasks.getTask(t1))!.deletedAt, isNull);
      expect(await env.tasks.countTasks(const TaskFilter()), 2);

      await expectLater(
        env.tasks.deletePermanently(t2),
        throwsAppError('в корзину'),
      );
      await env.tasks.moveToTrash(t2);
      await env.tasks.deletePermanently(t2);
      expect(await env.tasks.getTask(t2), isNull);
      expect(await env.tasks.getHistory(t2), isEmpty);
    });
  });

  group('Фильтрация, поиск, сортировка, пагинация', () {
    test('фильтры по статусу, приоритету и исполнителю', () async {
      final owner = await env.user('Owner');
      final dev = await env.user('Dev');
      final p = await env.project('P', owner, [dev]);
      final a = await env.tasks.createTask(
        projectId: p,
        title: 'A',
        priority: TaskPriority.critical,
        assigneeId: dev,
        actorId: owner,
      );
      await env.tasks.createTask(
        projectId: p,
        title: 'B',
        priority: TaskPriority.low,
        actorId: owner,
      );
      await env.tasks.changeStatus(a, TaskStatus.inProgress, actorId: owner);

      Future<List<String>> titles(TaskFilter f) async =>
          (await env.tasks.getTasks(f)).map((t) => t.task.title).toList();

      expect(await titles(const TaskFilter(status: TaskStatus.inProgress)), [
        'A',
      ]);
      expect(await titles(const TaskFilter(priority: TaskPriority.low)), ['B']);
      expect(await titles(TaskFilter(assigneeId: dev)), ['A']);
      expect(await titles(TaskFilter(projectId: p)), hasLength(2));
    });

    test('поиск по названию и описанию, сортировка и страницы', () async {
      final owner = await env.user('Owner');
      final p = await env.project('P', owner);
      await env.tasks.createTask(
        projectId: p,
        title: 'Дизайн экрана',
        deadline: env.inDays(5),
        actorId: owner,
      );
      await env.tasks.createTask(
        projectId: p,
        title: 'Отчёт',
        description: 'Добавить дизайн-систему',
        deadline: env.inDays(1),
        actorId: owner,
      );
      for (var i = 0; i < 5; i++) {
        await env.tasks.createTask(
          projectId: p,
          title: 'Задача $i',
          actorId: owner,
        );
      }

      final found = await env.tasks.getTasks(const TaskFilter(query: 'дизайн'));
      expect(found.map((t) => t.task.title).toSet(), {
        'Дизайн экрана',
        'Отчёт',
      });

      final byDeadline = await env.tasks.getTasks(
        const TaskFilter(sort: TaskSort.deadlineAsc),
      );
      expect(byDeadline.first.task.title, 'Отчёт');
      expect(byDeadline[1].task.title, 'Дизайн экрана');
      expect(byDeadline.last.task.deadline, isNull); // без дедлайна — в конце

      const filter = TaskFilter(sort: TaskSort.createdAsc);
      final page1 = await env.tasks.getTasks(filter, limit: 3);
      final page2 = await env.tasks.getTasks(filter, limit: 3, offset: 3);
      final page3 = await env.tasks.getTasks(filter, limit: 3, offset: 6);
      expect([page1.length, page2.length, page3.length], [3, 3, 1]);
      expect(
        {...page1, ...page2, ...page3}.map((t) => t.task.id).toSet(),
        hasLength(7),
      );
    });
  });

  group('Статистика и реактивность', () {
    test('статистика считается SQL-запросами корректно', () async {
      final owner = await env.user('Owner');
      final dev = await env.user('Dev');
      final p = await env.project('P', owner, [dev]);
      await env.project('Пустой', owner);

      Future<int> create(TaskPriority priority) => env.tasks.createTask(
        projectId: p,
        title: 'T',
        priority: priority,
        assigneeId: dev,
        actorId: owner,
      );
      final done = await create(TaskPriority.high);
      final cancelled = await create(TaskPriority.low);
      final overdue = await create(TaskPriority.high);
      await create(TaskPriority.critical);
      final trashed = await create(TaskPriority.low);

      await env.tasks.changeStatus(done, TaskStatus.done, actorId: owner);
      await env.tasks.changeStatus(
        cancelled,
        TaskStatus.cancelled,
        actorId: owner,
      );
      await (env.db.update(env.db.tasks)..where((t) => t.id.equals(overdue)))
          .write(TasksCompanion(deadline: Value(env.inDays(-2))));
      await env.tasks.moveToTrash(trashed);

      final s = await env.stats.getStats();
      expect(s.projects, 2);
      expect(s.totalTasks, 4); // задача из корзины не считается
      expect(s.doneTasks, 1);
      expect(s.openTasks, 2);
      expect(s.overdueTasks, 1);
      expect(s.byPriority[TaskPriority.high], 2);
      expect(s.byPriority[TaskPriority.low], 1);
      expect(s.byAssignee.single.name, 'Dev');
      expect(s.byAssignee.single.count, 4);
      final progress = s.projectProgress.firstWhere((x) => x.name == 'P');
      expect(
        progress.percent,
        closeTo(100 / 3, 0.01),
      ); // 1 из 3 (без отменённой)
    });

    test('watch() сам присылает новые данные после изменения', () async {
      final owner = await env.user('Owner');
      final p = await env.project('P', owner);
      final counts = env.tasks.watchCount(TaskFilter(projectId: p));

      final expectation = expectLater(counts, emitsInOrder([0, 1, 2]));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await env.tasks.createTask(projectId: p, title: 'A', actorId: owner);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await env.tasks.createTask(projectId: p, title: 'B', actorId: owner);
      await expectation;
    });
  });
}
