package helpers;

import net.minidev.json.JSONObject;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

public class ArticlesValuesFeeder implements Iterator<Map<String, Object>> {

    private int counter = 0;

    @Override
    public boolean hasNext() {
        return true; // infinite: Gatling requires one row for each user we inject.
    }

    @Override
    public Map<String, Object> next() {
        counter++;
        JSONObject articleValues = DataGenerator.getRandomArticleValues();
        Map<String, Object> row = new HashMap<>();
        row.put("title", articleValues.get("title"));
        row.put("description", articleValues.get("description"));
        row.put("body", articleValues.get("body"));
        return row;
    }
}