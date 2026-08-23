package helpers;

import com.github.javafaker.Faker;
import net.minidev.json.JSONObject;

public class DataGenerator {
    public static String getRandomEmail() {
        Faker faker = new Faker();
        return faker.name().firstName().toLowerCase() + faker.random().nextInt(0, 100) + "@gmail.com";
    }

    public static String getRandomUsername() {
        Faker faker = new Faker();
        String username = faker.name().username();
        return username.length() > 20 ? username.substring(0, 20) : username;
    }

    public static JSONObject getRandomArticleValues() {
        Faker faker = new Faker();
        String title = faker.gameOfThrones().character();
        String description = faker.gameOfThrones().city();
        String body = faker.gameOfThrones().quote();
        JSONObject article = new JSONObject();
        article.put("title", title);
        article.put("description", description);
        article.put("body", body);
        return article;
    }

    public static String getRandomCommentBody() {
        Faker faker = new Faker();
        return faker.backToTheFuture().character();
    }
}
