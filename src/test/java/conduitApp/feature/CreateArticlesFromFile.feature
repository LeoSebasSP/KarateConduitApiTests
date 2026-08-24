Feature: Creation of Articles From File CSV

  Background:
    * url url
    * def tokenResponse = callonce read('classpath:helpers/TokenLogin.feature')
    * def token = tokenResponse.token
    * def dataGenerator = Java.type("helpers.DataGenerator")
    * def articleValues = dataGenerator.getRandomArticleValues()
    * def articleRequestBody = read ('classpath:/conduitApp/json/newArticleRequest.json')

    * def __gv = karate.get('__gatling') || {}
    * def articleTitle = __gv.title || articleValues.title
    * def articleDescription = __gv.description || articleValues.description
    * def articleBody = __gv.body || articleValues.body
    * set articleRequestBody.article.title = articleTitle
    * set articleRequestBody.article.description = articleDescription
    * set articleRequestBody.article.body = articleBody

  Scenario: Create Article from CSV
    Given path pathArticles
    And header Authorization = token
    And request articleRequestBody
    When method Post
    Then status 201
    And match response.article.title == "#(articleTitle)"
