@SignUp @regresion
Feature: Sign up new user

  Background:
    * url url
    * def dataGenerator = Java.type("helpers.DataGenerator")
    * def userEmail = dataGenerator.getRandomEmail()
    * def userUsername = dataGenerator.getRandomUsername()

  Scenario: New user Sign up
    Given path pathUsers
    And request
      """
      {
        "user": {
          "email":"#(userEmail)",
          "password":"test2123",
          "username":"#(userUsername)"
        }
      }
      """
    When method Post
    Then status 201
    And match response ==
      """
      {
        "user": {
          "id": "#number",
          "email": "#(userEmail)",
          "username": "#(userUsername)",
          "bio": "##string",
          "image": "#string",
          "token": "#string"
        }
      }
      """

  Scenario Outline: Validate Sign up error message
    Given path pathUsers
    And request {"user":{"email":"<email>","password":"<password>","username":"<username>"}}
    When method Post
    Then status 422
    And match response == <errorResponse>

    Examples:
      | email                 | password  | username                       | errorResponse                                                                       |
      | #(userEmail)          | karate123 | karateTest5                    | {"errors":{"username":["has already been taken"]}}                                  |
      | karateTest5@gmail.com | karate123 | #(userUsername)                | {"errors":{"email":["has already been taken"]}}                                     |
      | karateTest5@gmail.com | karate123 | karateTest5                    | {errors: {email: ["has already been taken"], username: ["has already been taken"]}} |
      | karateTest5           | karate123 | #(userUsername)                | {"errors":{"email":["is invalid"]}}                                                 |
      | #(userEmail)          | karate123 | karateTestsdlljfnskjdnf3224834 | {"errors":{"username":["is too long (maximum is 20 characters)"]}}                  |
      | #(userEmail)          | kara      | #(userUsername)                | {"errors":{"password":["is too short (minimum is 8 characters)"]}}                  |
      |                       | karate123 | #(userUsername)                | {"errors":{"email":["can't be blank"]}}                                             |
      | #(userEmail)          | karate123 |                                | {"errors":{"username":["can't be blank"]}}                                          |
      | #(userEmail)          |           | #(userUsername)                | {"errors":{"password":["can't be blank"]}}                                          |
