package edu.unisphere.api.intelligence;

import org.springframework.stereotype.Service;
import java.util.Comparator;
import java.util.List;

@Service
public class LostFoundMatchingService {
    public record Item(String ownerId, String type, String status, String category,
                       String color, String description, String location) {}
    public record Candidate(String id, Item item) {}
    public record Match(String id, double score) {}

    public List<Match> matches(Item source, List<Candidate> candidates, double threshold) {
        if (threshold < 0 || threshold > 1) throw new IllegalArgumentException("threshold must be between 0 and 1");
        return candidates.stream()
                .map(candidate -> new Match(candidate.id(), score(source, candidate.item())))
                .filter(match -> match.score() > 0 && match.score() >= threshold)
                .sorted(Comparator.comparingDouble(Match::score).reversed())
                .toList();
    }

    public double score(Item source, Item candidate) {
        if (source == null || candidate == null
                || source.ownerId() == null || source.ownerId().equals(candidate.ownerId())
                || !"ACTIVE".equals(source.status()) || !"ACTIVE".equals(candidate.status())
                || source.type() == null || source.type().equals(candidate.type())) return 0.0;
        double category = source.category() != null
                && source.category().equalsIgnoreCase(candidate.category()) ? 0.30 : 0.0;
        return category
                + 0.25 * TextSimilarity.jaccard(source.color(), candidate.color())
                + 0.25 * TextSimilarity.jaccard(source.description(), candidate.description())
                + 0.20 * TextSimilarity.jaccard(source.location(), candidate.location());
    }
}
