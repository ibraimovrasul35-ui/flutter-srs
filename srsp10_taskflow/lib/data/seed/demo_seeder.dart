import '../../models/enums.dart';
import '../database/app_database.dart';
import '../repositories/comment_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/user_repository.dart';

/// Наполняет пустую базу небольшим набором данных при первом запуске.
class DemoSeeder {
  DemoSeeder(this._db);

  final AppDatabase _db;

  Future<void> seedIfEmpty() async {
    final users = UserRepository(_db);
    if ((await users.getUsers()).isNotEmpty) return;

    final projects = ProjectRepository(_db);
    final tasks = TaskRepository(_db);
    final comments = CommentRepository(_db);

    final rasul = await users.createUser(
      name: 'Расул',
      email: 'rasul@taskflow.kz',
    );
    final amina = await users.createUser(
      name: 'Амина',
      email: 'amina@taskflow.kz',
    );
    final daniyar = await users.createUser(
      name: 'Данияр',
      email: 'daniyar@taskflow.kz',
    );
    final aigerim = await users.createUser(
      name: 'Айгерим',
      email: 'aigerim@taskflow.kz',
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final shop = await projects.createProject(
      name: 'Интернет-магазин',
      description: 'Мобильное приложение магазина электроники',
      endDate: today.add(const Duration(days: 30)),
      ownerId: rasul,
    );
    await projects.addMember(shop, amina, MemberRole.admin);
    await projects.addMember(shop, daniyar, MemberRole.member);

    final diploma = await projects.createProject(
      name: 'Дипломная работа',
      description: 'Исследование и написание диплома',
      ownerId: amina,
    );
    await projects.addMember(diploma, aigerim, MemberRole.member);
    await projects.addMember(diploma, rasul, MemberRole.member);

    final design = await tasks.createTask(
      projectId: shop,
      title: 'Дизайн главного экрана',
      description: 'Макет каталога и карточки товара в Figma',
      assigneeId: amina,
      priority: TaskPriority.high,
      deadline: today.add(const Duration(days: 3)),
      actorId: rasul,
    );
    await tasks.changeStatus(design, TaskStatus.inProgress, actorId: amina);
    await comments.addComment(
      taskId: design,
      authorId: amina,
      text: 'Первый вариант макета готов, жду замечаний',
    );

    final db = await tasks.createTask(
      projectId: shop,
      title: 'Схема базы данных',
      description: 'Таблицы товаров, заказов и корзины',
      assigneeId: daniyar,
      priority: TaskPriority.critical,
      deadline: today.add(const Duration(days: 1)),
      actorId: rasul,
    );
    await tasks.changeStatus(db, TaskStatus.inProgress, actorId: daniyar);
    await tasks.changeStatus(db, TaskStatus.done, actorId: daniyar);

    await tasks.createTask(
      projectId: shop,
      title: 'Оплата картой',
      description: 'Интеграция платёжного шлюза',
      assigneeId: rasul,
      priority: TaskPriority.medium,
      deadline: today.add(const Duration(days: 7)),
      actorId: rasul,
    );
    await tasks.createTask(
      projectId: shop,
      title: 'Push-уведомления',
      priority: TaskPriority.low,
      actorId: rasul,
    );

    final review = await tasks.createTask(
      projectId: diploma,
      title: 'Обзор литературы',
      description: 'Найти 20 источников за последние 5 лет',
      assigneeId: aigerim,
      priority: TaskPriority.high,
      deadline: today.add(const Duration(days: 5)),
      actorId: amina,
    );
    await tasks.changeStatus(review, TaskStatus.inProgress, actorId: aigerim);
    await tasks.createTask(
      projectId: diploma,
      title: 'Презентация к защите',
      assigneeId: rasul,
      priority: TaskPriority.medium,
      deadline: today.add(const Duration(days: 14)),
      actorId: amina,
    );
  }
}
