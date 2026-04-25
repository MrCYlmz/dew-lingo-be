# dew-lingo

A local-first language learning web app. The MVP teaches English through a single repeating loop driven by a local LLM.

---

# 1) Product goal

A user:

1. selects English and their level,
2. receives a set of target words,
3. writes a text using those words,
4. gets corrected with explanations,
5. receives learning cards from the mistakes,
6. takes a quiz generated from those mistakes,
7. must score at least 80% to unlock the next quest,
8. repeats the loop with different words at the same level.

The MVP is single-language, single-user-oriented, and fully local.

---

# 2) MVP scope

## In scope

* English only
* Level selection
* The full learning loop (quest → submission → correction → cards → quiz → progression)
* Persistence of every generated artifact so the same AI work is not repeated
* Contract-first API between frontend and backend
* Local deployment

## Out of scope for MVP

* Multi-language support
* User accounts / social login
* Payments
* Mobile app
* Teacher dashboard
* Collaborative or real-time learning
* Public cloud deployment

---

# 3) Core learning loop

1. User opens the app.
2. User chooses English and a level.
3. System creates a quest (target words + writing prompt + difficulty).
4. User writes a text.
5. System asks the AI for a correction (corrected text, errors, explanations).
6. System turns the mistakes into learning cards.
7. System generates a quiz from the corrections and cards.
8. User answers the quiz.
9. If score ≥ 80%, the next quest unlocks.
10. The next quest uses a different word set at the same level.

---

# 4) Product rules

These are invariants. Implementation details may change; these should not change silently.

## Learning rules

* MVP is English only.
* Every quest is tied to a level.
* Every quest must use a word set the user has not seen before at that level.
* The next quest unlocks only when quiz score ≥ 80%.
* Learning cards and quiz content must be derived from the user's actual text and its correction — not invented independently.

## Persistence rules

Every generated artifact is stored: quest, submission, correction, mistakes, cards, quiz, attempts, progression state, prompt versions, and raw AI responses. The goal is that re-running the same input never re-calls the model.

## AI boundary rules

* The frontend never calls the LLM directly. It talks only to the backend.
* The backend is the sole caller of the local LLM.
* Scoring (the 80% gate) is computed server-side and is deterministic. The client is never trusted for it.

---

# 5) AI design principles

The hard part of this app is making LLM output reliable enough to render and grade. The approach:

1. **Structured outputs only.** Each AI task has a JSON schema. The model is asked to return that structure and nothing else.
2. **Validate before use.** The backend validates every response against the task's schema. Invalid output is rejected; one repair retry is allowed.
3. **One task per call.** AI work is split into independent tasks (quest generation, correction, card generation, quiz generation), each with its own prompt and schema. No mega-prompt.
4. **Version prompts and schemas.** Every change is a new version. Published versions are immutable so caches stay valid.
5. **Cache deterministically.** Outputs are stored under a key derived from the model, prompt version, task, level, target words, normalized input, and language. Same key → return the stored result.
6. **Low temperature, short prompts, JSON-only.** Reliability beats creativity here.

The exact schemas, prompt templates, and cache key shape live with the code — not in this README.

---

# 6) Architecture at a glance

* **Frontend** — TypeScript app. Renders the loop, talks only to the backend.
* **Backend** — Java service. Owns business logic, persistence, AI orchestration, validation, and caching.
* **AI layer** — Local LLM (Ollama, Qwen3 4B in MVP). Called only by the backend.
* **Database** — PostgreSQL. Stores all artifacts and progression state.
* **API contract** — OpenAPI is the source of truth. Backend interfaces and frontend client are generated from it; neither side hand-writes request/response types.

Internally the backend should be modular (quest, submission, correction, cards, quiz, progress, AI orchestration, persistence/cache) even if it ships as a single deployable.

---

# 7) Domain entities

The model needs to represent at least:

* User, Level
* Quest, QuestWordSet
* WritingSubmission, CorrectionResult, Mistake
* LearningCard
* Quiz, QuizQuestion, QuizAttempt, QuizAnswer
* ProgressionState
* AIPromptVersion, AIResponseCache

Relationships follow the loop: a user has many quests; a quest has one word set and one or more submissions; a submission has one correction; a correction yields mistakes, cards, and one quiz; a quiz has questions and attempts.

---

# 8) Local development setup

You need the following on your machine. Versions match what the project is pinned to today.

## Required

* **Java 21** — for the backend and the openapi module (both compile to Java 21).
* **Docker** with Compose v2 — runs PostgreSQL. The backend's `compose.yaml` is started automatically by `spring-boot-docker-compose` when you run the app, or you can start it manually with `docker compose up -d` from `dew-lingo-be/`.
* **Ollama** running on the host at `http://localhost:11434`, with the `qwen3:4b` model pulled (`ollama pull qwen3:4b`). The backend talks to it directly; it is not containerized in MVP.
* **Node.js 22.11.0 / npm 10.9.0** — for the frontend dev server (`dew-lingo-fe/`).

## Provided by the repo (no need to install)

* **Maven** — both `dew-lingo-be/` and `dew-lingo-openapi/` ship the Maven wrapper (`./mvnw`). Use that instead of a system Maven.
* **Node toolchain for the openapi module** — `dew-lingo-openapi/` uses `frontend-maven-plugin`, which downloads its own Node/npm during the Maven build. You do **not** need Node installed to build that module.

## First-time bootstrap order

1. Build the openapi module first: `cd dew-lingo-openapi && ./mvnw install`. This installs the Java API JAR into your local Maven repo and produces the TypeScript client tarball that the frontend depends on.
2. Backend: `cd dew-lingo-be && ./mvnw clean package` (or `./mvnw spring-boot:run` to start it; Postgres will come up via Docker automatically).
3. Frontend: `cd dew-lingo-fe && npm install && npm run dev`.

---

# 9) MVP success criteria

The MVP is successful if:

* a user can complete a full learning cycle locally,
* AI output is stable and structured,
* every generated artifact is persisted and reused,
* progression is gated by quiz performance,
* and the architecture allows new languages or learning modes to be added later without rewriting the core.
