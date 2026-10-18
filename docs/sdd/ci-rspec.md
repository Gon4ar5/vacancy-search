# CI для RSpec: спецификация и план

## Зачем

Сейчас GitHub Actions проверяет стиль кода через RuboCop и типовые уязвимости Rails через Brakeman, но не запускает существующую RSpec suite. Изменения могут пройти CI, даже если поведение приложения сломано.

## Требование

Для каждого pull request и каждого push в `main` GitHub Actions должен запускать RSpec на Ruby версии, заданной в `.ruby-version`, используя отдельную тестовую базу PostgreSQL с расширением pgvector.

## Критерии приёмки

1. Новая CI job запускается на тех же событиях, что и остальные проверки workflow.
2. Job использует Ruby из `.ruby-version` и зависимости из `Gemfile.lock`.
3. Job поднимает PostgreSQL с pgvector и ждёт готовности сервиса перед запуском приложения.
4. Rails подключается к тестовой базе `matchmate_test`, заданной в `config/database.yml`.
5. Job запускает всю RSpec suite командой `bundle exec rspec`.
6. Ненулевой exit code RSpec завершает job ошибкой и блокирует зелёный статус CI.
7. Секреты и OpenAI API не нужны для обычного запуска существующих тестов.

## Ограничения и решения

- Использовать официальный для проекта образ `pgvector/pgvector:pg16`, чтобы CI поддерживал расширение `vector`, требуемое схемой базы.
- Использовать встроенный GitHub Actions service container и проброс порта на `127.0.0.1`: job выполняется непосредственно на `ubuntu-latest`, а не внутри отдельного контейнера.
- Redis не поднимать: тестовое окружение использует Active Job test adapter; тесты не требуют реального Sidekiq worker.
- Разместить RSpec отдельной job, чтобы её результат и зависимость PostgreSQL были видны независимо от lint/security jobs.

## План реализации

1. Добавить `test` job с PostgreSQL/pgvector service и health check.
2. Настроить переменные окружения для тестовой базы.
3. Настроить Ruby и Bundler тем же способом, что и в остальных CI jobs.
4. Создать тестовую базу и загрузить схему командой `bundle exec rails db:prepare`.
5. Запустить `bundle exec rspec` как обязательный шаг job.
6. Проверить конфигурацию workflow и полный результат RSpec на GitHub Actions после push/PR.

## Проверка результата

Локальная проверка в Docker: пользователь сообщил, что прошли все 12 примеров RSpec. CI workflow пока не запускался на GitHub. Окончательное подтверждение — зелёная job `test` на pull request: только она проверит GitHub service container, health check и подготовку чистой базы на runner.
