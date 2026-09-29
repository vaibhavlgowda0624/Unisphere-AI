package edu.unisphere.api.intelligence;

import java.text.Normalizer;
import java.util.Arrays;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

public final class TextSimilarity {
    private TextSimilarity() {}

    public static Set<String> tokens(String value) {
        if (value == null || value.isBlank()) return Set.of();
        String normalized = Normalizer.normalize(value, Normalizer.Form.NFKC)
                .toLowerCase(Locale.ROOT);
        return Arrays.stream(normalized.split("[^\\p{L}\\p{N}]+"))
                .filter(token -> !token.isBlank())
                .collect(Collectors.toUnmodifiableSet());
    }

    public static double jaccard(String left, String right) {
        Set<String> a = tokens(left);
        Set<String> b = tokens(right);
        if (a.isEmpty() && b.isEmpty()) return 0.0;
        long intersection = a.stream().filter(b::contains).count();
        return (double) intersection / (a.size() + b.size() - intersection);
    }
}
