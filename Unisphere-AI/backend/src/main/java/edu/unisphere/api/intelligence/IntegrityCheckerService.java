package edu.unisphere.api.intelligence;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class IntegrityCheckerService {
    private final double threshold;

    public IntegrityCheckerService(@Value("${unisphere.integrity.threshold:0.6}") double threshold) {
        if (threshold < 0 || threshold > 1) throw new IllegalArgumentException("Threshold must be between 0 and 1");
        this.threshold = threshold;
    }

    public Result compare(String sourceText, String candidateText) {
        double score = TextSimilarity.jaccard(sourceText, candidateText);
        return new Result(score, threshold, score >= threshold);
    }

    public record Result(double score, double threshold, boolean flaggedForReview) {}
}
