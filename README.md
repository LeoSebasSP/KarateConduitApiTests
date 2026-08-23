# onboarding - Karate API Tests

Pruebas de API para el Conduit demo (RealWorld) usando el framework de Karate (`io.karatelabs`, la versión nueva de Karate Labs, no el `com.intuit.karate` de toda la vida). Es el proyecto del curso de Bondar Academy, apuntando contra su API pública:

`https://conduit-api.bondaracademy.com`

Ojo con eso: es una API compartida con todo el mundo que está haciendo el curso, no es un ambiente aislado para nosotros. Más abajo hay una sección de cosas raras que pasan por esto mismo.

## Requisitos

- Java 21
- Maven (o usar el wrapper si algún día lo agregamos, por ahora no hay)
- Docker + Docker Compose, si prefieres correrlo sin instalar nada local

## Estructura

```
src/test/java/
  karate-config.js              config global (dev / cert / prod)
  conduitApp/
    ConduitTest.java            el runner de JUnit, corre todo lo de conduitApp/
    feature/
      Articles.feature          crear/borrar/favoritear/comentar artículos
      HomePage.feature          tags y feed de artículos
      SignUp.feature            registro de usuario + validaciones de error
      JsonTransformers.feature  ejemplos sueltos de transformación de JSON con if
    json/                       schemas de match y bodies de request reusables
  helpers/
    TokenLogin.feature          hace login y devuelve el token
    dummy.feature                lo usa el afterScenario de HomePage, ver nota abajo
    DataGenerator.java           genera emails/usernames/artículos random con javafaker
    timeValidator.js             valida que un campo de fecha tenga formato ISO
```

Todo vive bajo `src/test/java` (features, json, js, todo), no hay `src/test/resources` separado. El `pom.xml` ya está configurado para tratar esa carpeta como resource también (excluyendo los `.java`).

## Ambientes

`karate-config.js` tiene tres bloques: `dev`, `cert` y `prod`. Los dos primeros están vacíos (son placeholders del template original de Karate). El único que realmente define `url`, `pathArticles`, `pathLogin`, etc. es `prod`. Si corres las pruebas sin especificar `karate.env`, se cae en `dev` y absolutamente todo falla con errores tipo `url is not defined`, porque esas variables nunca se definieron.

Por ahora, siempre hay que correr con `-Dkarate.env=prod`. No es el ambiente "de producción" de nada nuestro, es simplemente el único bloque de config que tiene contenido - el nombre viene así del template del curso.

## Cómo correr las pruebas

Todas, contra prod:

```bash
mvn test -Dkarate.env=prod
```

Solo las que tienen el tag `@regresion` (por ahora son todas, pero la idea es ir separando smoke tests de regresión completa a futuro):

```bash
mvn test -Dkarate.env=prod -Dkarate.options="--tags @regresion"
```

Una sola feature (útil cuando estás debuggeando algo puntual):

```bash
mvn test -Dkarate.env=prod -Dkarate.options="--tags @SignUp"
```

El reporte HTML queda en `target/karate-reports/karate-summary.html`.

## Con Docker

```bash
docker compose up --build
```

El `docker-compose.yml` monta `./target` para que el reporte quede accesible en el host después de correr, y monta también `~/.m2` para no descargar las dependencias de Maven cada vez que reconstruyes la imagen. El comando ya corre con `-Dkarate.env=prod`.

Nota: el comando usa `mvn clean test`, no solo `test`. Es a propósito - como `target` es un volumen montado, si no se limpia, clases compiladas viejas (de pruebas que ya borraste del código) se quedan ahí y Maven las vuelve a ejecutar como si nada. El `clean` necesita el flag `-Dmaven.clean.failOnError=false` porque Maven no puede borrar el directorio `target` completo (es el punto de montaje del volumen), solo su contenido - sin ese flag el build revienta aunque en realidad sí limpió todo.

## Cosas a tener en cuenta (aprendidas a las malas)

- **La API es compartida.** No hagas `match` de conteos exactos tipo `articlesCount: 3` contra el feed global o contra favoritos - la cuenta va subiendo con cada corrida (nuestra y la de cualquier otro estudiante usando la misma cuenta de prueba `karateTest5`). En `Favorite articles` ese match está comentado por esta razón.
- **Los títulos de artículo son únicos globalmente.** Si usas un título fijo tipo `"Delete Article"` y el test se corta antes del DELETE, ese artículo queda huérfano y la próxima corrida falla con `must be unique`. Por eso ahora los artículos se generan con `DataGenerator.getRandomArticleValues()`.
- **`match each` sobre un array vacío falla por defecto** en esta versión de Karate (a diferencia del Karate clásico, donde pasa sin problema). Si el array puede venir vacío (como los comentarios de un artículo nuevo), hay que agregar `* configure matchEachEmptyAllowed = true` antes del match.
- **`configure afterScenario` se hereda en los `karate.call()`.** El hook de `HomePage.feature` llama a `dummy.feature`, y si ese feature no resetea el hook, cuando termina SU propio scenario dispara el mismo `afterScenario` de nuevo → se llama a sí mismo → stack overflow. Por eso `dummy.feature` tiene `* configure afterScenario = null` como primer paso, no lo saques.
- **`Scenario Outline` + docstring (`"""`) no se llevan bien en esta versión del engine.** Da un `NullPointerException` raro al armar las filas de `Examples`. Si necesitas un `request` con placeholders dentro de un Outline, ponlo en una sola línea en vez de docstring (ver `SignUp.feature`).
- **`TokenLogin.feature` necesita un `Scenario`, no alcanza con `Background`.** Sin scenario, el `Background` nunca corre y `callonce` devuelve nada, con lo cual la variable de resultado queda indefinida (no null, indefinida - el error es tipo `x is not defined`, no un null pointer).
- **Los usernames random pueden pasarse de 20 caracteres** (el límite que impone la API). `DataGenerator.getRandomUsername()` ya lo trunca, pero si tocas ese método de nuevo, ojo con eso.

## Tags disponibles

- `@regresion` - suite completa, todas las features
- `@SignUp`, `@HomePage`, `@CreationArticles`, `@JsonTransformers` - por feature
- `@ignore` - convención para marcar algo que no debe correr todavía (por ahora no hay ningún scenario con este tag, pero `ConduitTest.java` tiene la línea comentada `.tags("~@ignore")` lista para cuando haga falta)

Documentación oficial de Karate Labs, por si algo de esto queda desactualizado: https://docs.karatelabs.io/getting-started/why-karate
