@JsonTransformers @regresion
Feature: JSON Transformers

  Background:
    * def article = { "title": "Karate JSON Transforms", "favoritesCount": 5 }

  Scenario: ternary if/else
    * def status = article.favoritesCount > 3 ? 'popular' : 'normal'
    * match status == 'popular'

  Scenario: if step + karate.set to add a field conditionally
    * def payload = { "title": "Draft Article" }
    * if (payload.title.length > 5) karate.set('payload', 'status', 'valid-title')
    * match payload.status == 'valid-title'

  Scenario: optional field with ##() - removes bio when null
    * def includeBio = false
    * def user = { "username": "karateTest5", "bio": "##(includeBio ? 'QA engineer' : null)" }
    * match user == { "username": "karateTest5" }
