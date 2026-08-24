function fn() {
  var env = karate.env;
  karate.log('karate.env system property was:', env);
  if (!env) {
    env = 'prod';
  }
  var config = {
    env: env,
    myVarName: 'someValue'
  }

  if (env == 'dev') {
    // customize
    // e.g. config.foo = 'bar';
  } else if (env == 'cert') {
    // customize
  } else if (env == 'prod') {
    config.url = 'https://conduit-api.bondaracademy.com'
    config.pathTags = '/api/tags'
    config.pathArticles = 'api/articles'
    config.pathLogin = '/api/users/login'
    config.pathUsers = '/api/users'

    config.email = 'karateTest5@gmail.com'
    config.username = 'karateTest5'
    config.password = 'karateTest5'
  }

  // var accessToken = karate.callSingle('classpath:helpers/TokenLogin.feature', config).token
  // karate.configure('headers', {Authorization: accessToken})

  return config;
}