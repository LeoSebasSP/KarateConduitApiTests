# onboarding - Karate API Tests

API tests for the Conduit demo (RealWorld) using the Karate framework (`io.karatelabs`, Karate Labs' new version, not the classic `com.intuit.karate`). This is the Bondar Academy course project, pointing at their public API:

`https://conduit-api.bondaracademy.com`

Heads up: this is an API shared with everyone taking the course, not an isolated environment for us. There's a section further down about weird things that happen because of exactly this.

## Requirements

- Java 21
- Maven (or the wrapper, if we ever add it - not there yet)
- Docker + Docker Compose, if you'd rather run it without installing anything locally

## Structure

```
src/test/java/
  karate-config.js                  global config (dev / cert / prod)
  logback-test.xml                  logging config (karate.http at TRACE to see request/response bodies)
  conduitApp/
    ConduitTest.java                JUnit runner, runs everything under conduitApp/
    feature/
      Articles.feature              create/delete/favorite/comment on articles
      HomePage.feature              tags and article feed
      SignUp.feature                user registration + validation errors
      CreateArticlesFromFile.feature   article creation driven by a CSV feeder (see Performance testing)
      CreateArticlesFromFaker.feature  article creation driven by a custom Faker feeder (see Performance testing)
      JsonTransformers.feature      standalone examples of JSON transformation with if
    json/                          reusable match schemas and request bodies
    performance/                   Gatling load simulations (see Performance testing)
      KarateProtocol.java            shared protocol: URI grouping, pauses and request naming
      FirstPerfTest.java             minimal example: 3 users signing up at once
      ArticlePerfTest.java           runs the full Articles.feature (create/favorite/comment/delete) under load
      UserThinkTime.java             sign up, pause, then browse the home page
      SimulationSetup.java           feeder + think time + ramped injection profile + assertion, all together
      CreateArticlesFeederFromFile.java   article creation fed from a fixed CSV
      CreateArticlesCustomFeeder.java     article creation fed from a hand-rolled Faker-backed feeder
  helpers/
    TokenLogin.feature              logs in and returns the token
    dummy.feature                   used by HomePage's afterScenario, see note below
    DataGenerator.java              generates random emails/usernames/articles with javafaker
    ArticlesValuesFeeder.java       hand-rolled Gatling feeder, wraps DataGenerator for unique article data
    timeValidator.js                validates that a date field is ISO-formatted
src/test/resources/
  data/
    articles.csv                   fixed article data for CreateArticlesFeederFromFile
    simulationsetup-users.csv      real, working credentials dedicated to SimulationSetup (see Performance testing)
```

Everything under `src/test/java` (features, json, js) is treated as a resource too - the `pom.xml` is configured for that, excluding the `.java` files. Feeder data for Gatling, on the other hand, lives under the standard `src/test/resources`, and there's a reason it's split that way - see "Performance testing" below.

## Environments

`karate-config.js` has three blocks: `dev`, `cert` and `prod`. The first two are empty (leftover placeholders from Karate's original template). The only one that actually defines `url`, `pathArticles`, `pathLogin`, etc. is `prod`. If you run the tests without specifying `karate.env`, it falls back to `prod` too (see the note in "Performance testing" about why the fallback isn't `dev`).

For the JUnit suite, you can still be explicit and pass `-Dkarate.env=prod`. It's not "our production" of anything, it's simply the only config block that has content - the name comes from the course template.

## Running the functional tests

All of them, against prod:

```bash
mvn test -Dkarate.env=prod
```

Only the ones tagged `@regresion` (right now that's all of them, but the idea is to eventually split smoke tests from the full regression suite):

```bash
mvn test -Dkarate.env=prod -Dkarate.options="--tags @regresion"
```

A single feature (handy when debugging something specific):

```bash
mvn test -Dkarate.env=prod -Dkarate.options="--tags @SignUp"
```

The HTML report lands at `target/karate-reports/karate-summary.html`.

## Performance testing (Gatling)

This project also has Gatling load simulations under `src/test/java/conduitApp/performance/`, built with `io.karatelabs:karate-gatling` (version pinned via `<karate.version>` in `pom.xml`) plus the `gatling-maven-plugin`. It's worth being explicit about something: **this is a from-scratch rewrite by Karate Labs, not the old `com.intuit.karate` V1 karate-gatling integration.** Patterns you'll find in older tutorials or Stack Overflow answers (`PerfContext`, `__gatling.pause`, etc.) generally don't apply here - see the gotchas below for what actually works in this version.

### Running the simulations

One simulation:

```bash
mvn gatling:test -Dgatling.simulationClass=conduitApp.performance.FirstPerfTest
```

All of them in one run:

```bash
mvn gatling:test -Dgatling.runMultipleSimulations=true
```

Without `-Dgatling.runMultipleSimulations=true`, Gatling refuses to run at all as soon as it finds more than one `Simulation` class on the classpath - it doesn't just run the first one, it fails outright.

Each run generates its own HTML report under `target/gatling/<simulation-name>-<timestamp>/index.html`.

### What each simulation demonstrates

- **`KarateProtocol`** isn't a simulation, it's shared configuration reused by the others. It groups URI patterns for reporting (`/api/articles/{slug}`, `/api/articles/{slug}/favorite`, `/api/articles/{slug}/comments`, `/api/articles/{slug}/comments/{commentId}`), adds pauses after specific methods (e.g. 500ms after a favorite POST), and defines a custom `nameResolver` so comment requests show up in the report as "Create Comment" / "Get Comment" / "Delete Comment" instead of raw URLs.
- **`FirstPerfTest`** - the simplest possible example: 3 users signing up at once, no protocol, no pauses. The entry point if you've never touched Gatling.
- **`ArticlePerfTest`** - runs the entire `Articles.feature` (create, favorite, comment, delete) under load, using the shared protocol for grouping/naming/pausing. See the concurrency gotcha below - it's expected to show a few KOs.
- **`UserThinkTime`** - sign up, then a `.pause(1s, 3s)` (Gatling's own DSL, between two `.exec(karateFeature(...))` calls), then browse the home page. This is the right way to add think time *between* feature calls.
- **`SimulationSetup`** - the "complete" example: feeder + `karateSet` for credentials + think time + a ramped injection profile (`rampUsers(3) during 5s`, `nothingFor(2s)`, `rampUsers(2) during 5s`) + a `global().successfulRequests().percent().gt(95.0)` assertion, all wired together.
- **`CreateArticlesFeederFromFile`** - articles created from a fixed CSV feeder (`data/articles.csv`, via Gatling's built-in `csv(...)`).
- **`CreateArticlesCustomFeeder`** - articles created from a hand-rolled feeder (`helpers/ArticlesValuesFeeder.java`, a plain `Iterator<Map<String,Object>>` that generates fresh Faker data on every `next()` call).

### How Gatling and a `.feature` file talk to each other

`karateSet(key, ...)` in a `ScenarioBuilder` sets a Gatling session variable. Inside the `.feature` file the simulation calls, that value shows up under `__gatling.<key>` (e.g. `karateSet("email", ...)` becomes `__gatling.email`). The safe pattern to read it, used throughout this project's Background sections, is:

```
* def __gv = karate.get('__gatling') || {}
* def email = __gv.email || email
```

Two things matter here, and both come from real bugs found while wiring this up:

- `karate.get('__gatling')` (no `$`) does a *plain variable lookup*. `karate.get('$__gatling.email')` *would* be JsonPath, and JsonPath throws a `PathNotFoundException` if the key doesn't exist - which it won't, for any simulation that doesn't call `karateSet("email", ...)`. The `__gv.email` plain-JS-property-access form used here just returns `undefined` instead, which is what you want.
- The `|| {}` guards against `__gatling` not existing at all (e.g. when the feature runs through the normal JUnit suite, not through Gatling). The `|| email` on the next line falls back to whatever `karate-config.js` already set up.

### Gotchas (learned the hard way, same as the functional suite)

- **`-Dkarate.env` never reaches a Gatling run, no matter what you pass.** `karate-gatling`'s `KarateExecutor` builds the suite via `Runner.builder()....buildSuite()`, and that method never applies the `-Dkarate.env` override - only `Runner.Builder.parallel(int)` does that, which is the path `ConduitTest.java` uses, not the one Gatling uses. This isn't a config mistake, it's a real gap in this version of the library (confirmed by reading its source). The fix here: `karate-config.js` defaults `env` to `'prod'` when nothing is set, since that's the only block with real config anyway (`dev`/`cert` are empty placeholders) - this covers both "no `-Dkarate.env` passed" and "running under Gatling, where it's *never* passed" with one line.
- **`karate-config.js` runs before `__gatling`/`__karate` even exist**, for any feature, always. `ScenarioRuntime.initEngine()` evaluates the config JS first and only afterwards binds the variables `karate-gatling` injects. So don't try to read Gatling session data from `karate-config.js` - it structurally can't work. Read it from the Background of the actual `.feature` file the simulation calls instead (that runs *after* the bind).
- **`read('some.json')` with embedded `#(...)` expressions evaluates them immediately, not lazily.** Any variable referenced inside the JSON has to be defined *before* the `read(...)` line in the Background, not after. Bit us with `dataGenerator`/`articleValues` needing to exist before `articleRequestBody = read(...)` in both `CreateArticlesFromFile.feature` and `CreateArticlesFromFaker.feature`.
- **A `.feature` file under `conduitApp/feature/` also runs through the normal JUnit suite**, not just when a Gatling simulation calls it - `ConduitTest.java` scans everything under `classpath:conduitApp`, no exceptions for files that happen to be Gatling-oriented. That means `CreateArticlesFromFile.feature` and `CreateArticlesFromFaker.feature` need to work standalone too, with no `__gatling` context at all - which is exactly why they always fall back with `__gv.title || articleValues.title` rather than assuming `__gv.title` is there.
- **Gatling feeders resolve paths against the classpath root, via `src/test/resources`, not against anything you configure in `pom.xml`.** You might see a `<simulationsFolder>`/`<configFolder>` block in gatling-maven-plugin examples online - those parameters don't exist for this plugin version (4.21.6); Maven just prints "unknown parameter" warnings and silently ignores them. Because this project's `<testResources>` block in `pom.xml` already replaces Maven's implicit defaults, `src/test/resources` had to be added back explicitly as its own `<testResource>` entry, or feeder CSVs never make it onto the classpath at all.
- **Pausing *between* feature calls vs. pausing *inside* one feature's steps are two different tools.** Between calls, use Gatling's own `.pause(...)` in the `ScenarioBuilder` (see `UserThinkTime`) - it's the framework-native way and it's what the report's timeline reflects. Inside a single feature's Background/steps, there's no Gatling-provided non-blocking equivalent in this library version - a plain `Thread.sleep` via a small JS helper (`function(ms){ java.lang.Thread.sleep(ms) }`) is the correct and only option; don't try to bridge to a `__gatling.pause` variable, it isn't something this library provides.
- **Fixed CSV data + an API that enforces uniqueness eventually collide.** `CreateArticlesFeederFromFile` reads fixed titles from `data/articles.csv`; run it enough times against the shared prod API and you'll start seeing `{"title":["must be unique"]}` (422) once those exact titles already exist from a previous run. `CreateArticlesCustomFeeder` doesn't have this problem, since every row is freshly Faker-generated. Pick whichever fits what you're trying to demonstrate - a repeatable failure mode is a legitimate thing to want to see too.
- **An `.assertions(...)` needs credentials it can actually rely on.** `SimulationSetup` has a hard `successfulRequests().percent().gt(95.0)` assertion, so it uses its own dedicated feeder (`data/simulationsetup-users.csv`, one real working account) instead of any feeder built around intentionally-wrong data - mixing "this is supposed to sometimes fail" fixtures with a must-pass assertion just breaks the build for the wrong reason.
- **Concurrent virtual users sharing one demo account and the same shared article will race each other.** `ArticlePerfTest`'s favorite/comment scenarios read a count and then assert `count + 1`; with several VUs hitting the same first article of the global feed at once, some of those assertions lose the race. That's inherent to load-testing a shared backend with a single demo account, not a bug in the simulation - expect a handful of KOs there and don't chase them.

## With Docker

```bash
docker compose up --build
```

`docker-compose.yml` mounts `./target` so the report stays accessible on the host after the run, and also mounts `~/.m2` so you're not redownloading Maven dependencies on every image rebuild. The default command already runs with `-Dkarate.env=prod`.

Note: the command uses `mvn clean test`, not just `test`. That's on purpose - since `target` is a mounted volume, without cleaning, old compiled classes (from tests you already deleted from the code) stick around and Maven runs them again as if nothing changed. The `clean` needs the `-Dmaven.clean.failOnError=false` flag because Maven can't delete the whole `target` directory (it's the volume's mount point), only its contents - without that flag the build blows up even though it actually did clean everything.

The `Dockerfile` copies both `src/test/java` and `src/test/resources` into the image, so Gatling simulations can also be run inside a container if you need to, e.g.:

```bash
docker compose run --rm karate-tests mvn gatling:test -Dgatling.simulationClass=conduitApp.performance.FirstPerfTest
```

## Things to keep in mind (learned the hard way)

- **The API is shared.** Don't `match` exact counts like `articlesCount: 3` against the global feed or favorites - the count keeps climbing with every run (ours and every other student's, all hitting the same `karateTest5` test account). That match is commented out in `Favorite articles` for exactly this reason.
- **Article titles are globally unique.** If you use a fixed title like `"Delete Article"` and the test stops before the DELETE step, that article is orphaned and the next run fails with `must be unique`. That's why articles are now generated with `DataGenerator.getRandomArticleValues()` (or, for the Gatling examples, a feeder - see "Performance testing" above for the tradeoffs of a fixed CSV vs. a Faker-backed one).
- **`match each` on an empty array fails by default** in this version of Karate (unlike classic Karate, where it's fine). If the array can legitimately come back empty (like comments on a brand-new article), add `* configure matchEachEmptyAllowed = true` before the match.
- **`configure afterScenario` is inherited by `karate.call()`.** `HomePage.feature`'s hook calls `dummy.feature`, and if that feature doesn't reset the hook, when its own scenario ends it fires the same `afterScenario` again → calls itself → stack overflow. That's why `dummy.feature` has `* configure afterScenario = null` as its very first step - don't remove it.
- **`Scenario Outline` + a docstring (`"""`) don't get along in this version of the engine.** It throws a weird `NullPointerException` while building the `Examples` rows. If you need a `request` with placeholders inside an Outline, put it on a single line instead of a docstring (see `SignUp.feature`).
- **`TokenLogin.feature` needs a `Scenario`, a `Background` alone isn't enough.** Without a scenario, the `Background` never runs and `callonce` returns nothing, leaving the result variable undefined (not null - undefined; the error looks like `x is not defined`, not a null pointer).
- **Random usernames can go over 20 characters** (the API's limit). `DataGenerator.getRandomUsername()` already truncates it, but if you touch that method again, watch out for this.

## Available tags

- `@regresion` - full suite, all features
- `@SignUp`, `@HomePage`, `@CreationArticles`, `@JsonTransformers` - per feature
- `@ignore` - convention for marking something that shouldn't run yet (no scenario currently has this tag, but `ConduitTest.java` has the commented-out line `.tags("~@ignore")` ready for when it's needed)

Official Karate Labs documentation, in case any of this goes stale: https://docs.karatelabs.io/getting-started/why-karate
