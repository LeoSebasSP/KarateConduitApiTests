@HomePage @regresion
Feature: Tests for the Home Page

  Background:
    * url url

    # After Hooks
    * configure afterScenario = function(){ karate.call('classpath:helpers/dummy.feature')}
    * configure afterFeature =
      """
      function(){
        karate.log("--------------------------------------- All Tests Completed ---------------------------------------")
      }
      """

  Scenario: Get all tags
    Given path pathTags
    When method Get
    Then status 200
    And match response.tags contains 'Blog'
    And match response.tags contains ['Blog', 'Git']
    And match response.tags !contains 'cars'
    And match response.tags contains any ['hola','test', 'Git']
    And match response.tags == "#array"
    And match each response.tags == "#string"

  Scenario: Get all articles
    * def timeValidator = read("classpath:helpers/timeValidator.js")

    Given path pathArticles
#    And params {limit: 10, offset: 0}
    When method Get
    Then status 200
    And match response == {"articles": "#[10]", "articlesCount": 10}
    And match each response.articles ==
    """
      {
        "slug": "#string",
        "title": "#string",
        "description": "#string",
        "body": "#string",
        "tagList": "#array",
        "createdAt": "#? timeValidator(_)",
        "updatedAt": "#? timeValidator(_)",
        "favorited": "#boolean",
        "favoritesCount": "#number",
        "author": {
          "username": "#string",
          "bio": "##string",
          "image": "#string",
          "following": "#boolean"
        }
      }
    """

