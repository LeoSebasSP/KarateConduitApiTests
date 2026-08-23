@CreationArticles @regresion
Feature: Creation of Articles

  Background:
    * url url
    * configure retry = {count: 3, interval: 2000}
    * def tokenResponse = callonce read('classpath:helpers/TokenLogin.feature')
    * def token = tokenResponse.token
    * def dataGenerator = Java.type("helpers.DataGenerator")
    * def articleValues = dataGenerator.getRandomArticleValues()
    * def articleRequestBody = read ('classpath:/conduitApp/json/newArticleRequest.json')
    * def timeValidator = read("classpath:helpers/timeValidator.js")

  Scenario: Create Article with header Authrorization
    Given path pathArticles
    And header Authorization = token
    And request articleRequestBody
    When method Post
    Then retry until 201
    And match response.article.title == "#(articleValues.title)"

  Scenario: Create and Delete Article with header Authrorization
    Given path pathArticles
    And header Authorization = token
    And request articleRequestBody
    When method Post
    Then status 201
    And match response.article.title == "#(articleValues.title)"
    And def idArticle = response.article.slug

    Given path pathArticles, idArticle
    When method Get
    Then status 200
    And match response.article.title == "#(articleValues.title)"

    Given path pathArticles, idArticle
    And header Authorization = token
    When method Delete
    Then status 204

    Given path pathArticles, idArticle
    When method Get
    Then status 404

  Scenario: Favorite articles
    # Step 1: Get atricles of the global feed
    Given path pathArticles
    And params {limit:10, offset:0}
    And header Authorization = token
    When method Get
    Then status 200

    # Step 2: Get the favorites count and slug ID for the first arice, save it to variables
    * def initialFavouritesCount = response.articles[0].favoritesCount
    * def slugId = response.articles[0].slug

    # Step 3: Make POST request to increse favorites count for the first article
    Given path pathArticles,slugId,'favorite'
    And header Authorization = token
    When method Post
    Then status 200
    # Step 4: Verify response schema
    * def articleFavouriteResponseSchema = read('classpath:/conduitApp/json/articleFavouriteResponse.json')
    And match response == articleFavouriteResponseSchema
    # Step 5: Verify that favorites article incremented by 1
    And match response.article.favoritesCount == initialFavouritesCount + 1

    # Step 6: Get all favorite articles
    Given path pathArticles
    And params {favorited: '#(username)', limit:10, offset:0}
    And header Authorization = token
    When method Get
    Then status 200
    # Step 7: Verify response schema
    * def getFavouriteArticleSchema = read('classpath:/conduitApp/json/getFavouriteArticle.json')
#    And match response == {"articles": "#[8]", "articlesCount": 8}
    And match each response.articles == getFavouriteArticleSchema
    # Step 8: Verify that slug ID from Step 2 exist in one of the favorite articles
    And match response.articles[*].slug contains slugId

  Scenario: Comment articles
    # Step 1: Get atricles of the global feed
    Given path pathArticles
    And params {limit:10, offset:0}
    And header Authorization = token
    When method Get
    Then status 200

    # Step 2: Get the slug ID for the first arice, save it to variable
    * def slugId = response.articles[0].slug

    # Step 3: Make a GET call to 'comments' end-point to get all comments
    Given path pathArticles,slugId,'comments'
    And header Authorization = token
    When method Get
    Then status 200
    # Step 4: Verify response schema (empty allowed - article may have zero comments)
    * configure matchEachEmptyAllowed = true
    * def getCommentArticleSchema = read('classpath:/conduitApp/json/getCommentArticle.json')
    And match each response.comments == getCommentArticleSchema

    # Step 5: Get the count of the comments array lentgh and save to variable
    * def initialCommentsAmount = response.comments.length

  # Step 6: Make a POST request to publish a new comment
    * def randomCommentBody = dataGenerator.getRandomCommentBody()
    Given path pathArticles,slugId,'comments'
    And header Authorization = token
    And request {"comment":{"body":"#(randomCommentBody)"}}
    When method Post
    Then status 200
  # Step 7: Verify response schema that should contain posted comment text
    And match response.comment == getCommentArticleSchema
    And match response.comment.body == randomCommentBody

  # Step 8: Get the list of all comments for this article one more time
    Given path pathArticles,slugId,'comments'
    And header Authorization = token
    When method Get
    Then status 200
  # Step 9: Verify number of comments increased by 1 (similar like we did with favorite counts)
    And match response.comments.length == initialCommentsAmount + 1

    * def commentsAmountAfterCreation = response.comments.length
    * def commentId = response.comments[0].id

  # Step 10: Make a DELETE request to delete comment
    Given path pathArticles,slugId,'comments',commentId
    And header Authorization = token
    When method Delete
    And status 200
  # Step 11: Get all comments again and verify number of comments decreased by 1
    Given path pathArticles,slugId,'comments'
    And header Authorization = token
    When method Get
    Then status 200
    And match response.comments.length == commentsAmountAfterCreation - 1


  Scenario: Create Article without header Authrorization
    Given path pathArticles
    And request articleRequestBody
    When method Post
    Then status 401
    And match response.status == 'error'
    And match response.message == 'missing authorization credentials'