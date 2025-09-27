# Repository Guidelines

## Project Structure & Module Organization
Runtime code lives under `lib/`, with `lib/ruby_llm/` holding provider adapters, tools, and Zeitwerk autoloaders. Appraisal Gemfiles sit in `gemfiles/`, and project rake tasks in `lib/tasks/`. Specs reside in `spec/`, fixtures and VCR cassettes in `spec/fixtures/`, and documentation assets in `docs/`. CLI helpers `bin/setup` and `bin/console` prep dependencies and open a sandbox console.

## Build, Test & Development Commands
- `bundle install` – install gem dependencies.
- `bin/setup` – wrap bundler install and prepare appraisal gemfiles.
- `bin/console` – boot an IRB session with `RubyLLM` preloaded.
- `overcommit --install` (once) and `overcommit --run` – configure and execute the git hook suite that runs RuboCop, RSpec, and lint checks.
- `bundle exec rspec` – run the full RSpec suite (mirrors the overcommit test step).
- `rake models` – refresh generated model metadata (`models.json`, alias tables, availability docs).
- `rake vcr:record[openai]` – re-record provider-specific VCR fixtures; use `all` to refresh the entire cassette set.

## Coding Style & Naming Conventions
Follow Ruby defaults: two-space indentation, frozen string literals, and `snake_case` filenames. Namespace new classes under `RubyLLM::` and keep filenames aligned with class names to satisfy Zeitwerk. RuboCop (`.rubocop.yml`) is the style source of truth; run `bundle exec rubocop` when iterating on formatting fixes.

## Testing Guidelines
RSpec is the primary framework; place new specs beside their implementation under `spec/ruby_llm/**` using `_spec.rb` suffixes. Use shared helpers from `spec/support/` to keep WebMock expectations consistent. When touching API integrations, re-record affected VCR cassettes and sanity-check sanitization. SimpleCov enforces coverage—avoid lowering coverage for core adapters.

## Commit & Pull Request Guidelines
Keep commits focused and match the short, descriptive style in history. Run the hook suite before pushing and ensure `bundle exec rspec` passes locally. Each PR should describe the change, note validation steps, and link any related issues or screenshots. Never hand-edit generated model catalogs; instead, document the command you ran (`rake models`) in the PR body.

## Security & Configuration Tips
Store provider credentials in `.env` or your shell profile—Dotenv loads them for specs. Do not commit secrets or unredacted cassette payloads. When exploring new providers, prefer temporary branches and document required environment variables in the PR description.
