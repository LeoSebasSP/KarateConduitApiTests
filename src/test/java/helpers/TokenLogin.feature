@TokenLogin
Feature: Get Token with Login

  Background:
    * def __gv = karate.get('__gatling') || {}
    * def email = __gv.email || email
    * def password = __gv.password || password

  Scenario: login and return token
    Given url url
    And path pathLogin
    And request {"user":{"email":"#(email)","password":"#(password)"}}
    When method Post
    Then status 200
    * def token = 'Token ' + response.user.token