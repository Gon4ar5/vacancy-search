## Поиск вакансий и требований

Этот сервис собирает вакансии с Habr Career, Hirify и hh.ru в одной базе. Можно задать вопрос и получить ответ по текстам вакансий.

Для этого вакансии разбиваются на фрагменты и индексируются в PostgreSQL с pgvector. При вопросе сервис находит подходящие фрагменты, а OpenAI составляет по ним ответ. Импорт и индексация вакансий выполняются в фоне через Sidekiq.

<img width="1505" height="1045" alt="image" src="https://github.com/user-attachments/assets/0ad6a12b-6471-4b1b-9f8b-91c3db8f153a" />

Стек: Ruby on Rails, PostgreSQL, pgvector, Sidekiq, Redis, RSpec, OpenAI API.
