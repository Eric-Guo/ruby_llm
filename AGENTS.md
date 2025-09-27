# Repository Guidelines

## Project Structure & Module Organization
- Runtime code lives in `lib/`, with provider adapters, tools, and autoloaders under `lib/ruby_llm/`.
- Specs reside in `spec/`; shared helpers are in `spec/support/` and cassettes under `spec/fixtures/`.
- Rake tasks sit in `lib/tasks/`; documentation assets are in `docs/`; appraisal Gemfiles are in `gemfiles/`.
- CLI helpers `bin/setup` and `bin/console` bootstrap dependencies and start an IRB sandbox with `RubyLLM` loaded.

## Build, Test, and Development Commands
- `bundle install` — install the base gem dependencies.
- `bin/setup` — wrap bundler install and prepare appraisal Gemfiles.
- `bundle exec rspec` — execute the full RSpec suite; mirrors the Overcommit test hook.
- `overcommit --install` (once) and `overcommit --run` — configure and run git hooks that execute RuboCop, RSpec, and lint checks.
- `rake models` — regenerate `models.json`, alias tables, and availability docs; run after changing provider metadata.
- `rake vcr:record[openai]` or `[all]` — refresh provider-specific VCR fixtures.

## Coding Style & Naming Conventions
- Ruby defaults: two-space indentation, frozen string literals, and `snake_case` filenames matching class namespaces.
- Namespace new classes under `RubyLLM::` and align file paths for Zeitwerk autoloading.
- RuboCop (`bundle exec rubocop`) enforces formatting; resolve offenses locally before committing.

## Testing Guidelines
- RSpec is the primary framework; name specs `*_spec.rb` under `spec/ruby_llm/**`.
- SimpleCov tracks coverage; avoid regressions in core adapters.
- Re-record relevant VCR cassettes when changing HTTP interactions and review sanitization.
- Run `bundle exec rspec` (or `overcommit --run`) before pushing.

## Commit & Pull Request Guidelines
- Keep commits focused with short, descriptive messages (≤72 characters subject, imperative mood).
- For PRs, describe the change, list validation steps (e.g., `bundle exec rspec`), and link related issues or screenshots.
- Document any generated artifacts by stating the command used (e.g., “Ran `rake models`”); never hand-edit generated catalogs.

## Security & Configuration Tips
- Load provider credentials through `.env` or shell profile; Dotenv handles specs.
- Do not commit secrets or unsanitized cassette payloads.
- Explore new providers in temporary branches and note required environment variables in the PR description.
