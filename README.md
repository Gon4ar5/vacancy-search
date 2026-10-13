# Сервис для поиска вакансий

Rails 8 application with PostgreSQL, run locally through Docker Compose. Vacancy search uses OpenAI embeddings and PostgreSQL with pgvector.

## Tests

Run the RSpec suite with `docker compose exec -e RAILS_ENV=test web bundle exec rspec`.

## Start

```sh
docker compose up --build
```

Open <http://localhost:3000> to browse saved vacancies.

The Rails container waits for PostgreSQL to become healthy and runs `db:prepare` before starting the server. Postgres data is kept in the `postgres_data` Docker volume.
The Sidekiq worker runs the Habr Career, Hirify, and hh.ru import jobs every 30 minutes.

## Ask questions about vacancies

Put `OPENAI_API_KEY` in `.env` and run the Sidekiq worker with Docker Compose. New and updated vacancy text is then queued for indexing automatically. Run the task once to index vacancies already in the database; reruns skip unchanged fragments.

```sh
cp .env.example .env
# Add OPENAI_API_KEY to .env
docker compose up --build -d
docker compose exec web bin/rails rag:index_jobs
```

Then open <http://localhost:3000/question/new>, or use the **Задать вопрос** button. Search retrieves up to six relevant vacancy fragments; the answer is generated from those fragments and links back to the original vacancies. Background indexing requires the worker service to be running.

## Import from Habr Career

The importer reads public vacancy listings and their detail pages, then saves the title, company, original link, publication time, Habr vacancy ID, and description. It waits between detail-page requests and runs in the Sidekiq worker.

```sh
docker compose exec web bin/rails habr:import
```

By default the importer follows Habr's pagination links and continues until the last page. To limit a run, pass a category and page limit, for example `docker compose exec web bin/rails "habr:import[developer,1]"`. This queues the import; follow progress with `docker compose logs -f worker`.

## Import from Hirify

The first Hirify import follows listing pages until the end. Later imports stop when they reach the first vacancy already in the database. A saved source-import state distinguishes an interrupted initial scan from a completed one, so retrying an interrupted first import continues through the remaining pages. The importer runs as a Sidekiq job and waits between detail-page requests.

```sh
docker compose exec web bin/rails hirify:import
```

Follow progress with `docker compose logs -f worker`.

## Import from hh.ru

The importer reads public hh.ru vacancy listings for Belarus by default, then fetches each vacancy description. The first complete import follows all listing pages; later imports stop at the first already saved vacancy. A limited run is useful for a small initial check and does not mark the first import complete.

```sh
docker compose exec web bin/rails hh:import
```

Optional arguments are query, hh.ru area ID and page limit, for example `docker compose exec web bin/rails 'hh:import[Ruby,1002,2]'`. Find area IDs in hh.ru's [areas directory](https://api.hh.ru/areas).

## Stop

```sh
docker compose down
```

To also remove the local PostgreSQL data volume, run `docker compose down -v`.
