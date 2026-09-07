# Fullstack Developer

Rails 8 + [Inertia.js](https://inertiajs.com/) + React frontend, bundled with Vite.

> This README will grow as the project evolves. For now it only covers running the app locally.

## Prerequisites

* Ruby `4.0.6` (see [.ruby-version](.ruby-version))
* Node.js (any recent LTS; developed against v24)
* [Docker](https://docs.docker.com/get-docker/) + Docker Compose, for the local PostgreSQL database

## Setup

1. Install gems and JS packages:

   ```bash
   bundle install
   npm install
   ```

2. Start PostgreSQL (runs on `localhost:5432`):

   ```bash
   docker compose up -d
   ```

3. Create and migrate the databases:

   ```bash
   bin/rails db:prepare
   ```

## Running the app

```bash
bin/dev
```

This uses [Foreman](https://github.com/ddollar/foreman) (or `overmind`/`hivemind`, if installed) to boot everything defined in [Procfile.dev](Procfile.dev):

* `web` — Rails server
* `css` — Tailwind watcher
* `vite` — Vite dev server (serves the React/Inertia frontend)

The app is then available at http://localhost:3000.

## Running tests

```bash
bin/rails test
```

The test database (`umanni_test`) runs against the same Dockerized Postgres instance as development — no extra setup needed.
