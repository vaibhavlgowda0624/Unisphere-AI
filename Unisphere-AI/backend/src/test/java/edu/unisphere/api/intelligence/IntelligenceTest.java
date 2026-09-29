package edu.unisphere.api.intelligence;

import static org.junit.jupiter.api.Assertions.*;
import org.junit.jupiter.api.Test;
import java.util.List;

class IntelligenceTest {
    @Test void jaccardNormalizesCaseAndPunctuation() {
        assertEquals(1.0 / 3.0, TextSimilarity.jaccard("Blue, BAG", "blue wallet"));
        assertEquals(0.0, TextSimilarity.jaccard("", ""));
    }

    @Test void lostFoundUsesSpecifiedWeightsAndExcludesOwnItems() {
        LostFoundMatchingService service = new LostFoundMatchingService();
        var lost = new LostFoundMatchingService.Item("alice", "LOST", "ACTIVE", "Bag", "Blue", "Laptop bag", "Library");
        var found = new LostFoundMatchingService.Item("bob", "FOUND", "ACTIVE", "Bag", "Blue", "Laptop bag", "Library");
        assertEquals(1.0, service.score(lost, found));
        assertEquals(0.0, service.score(lost, new LostFoundMatchingService.Item("alice", "FOUND", "ACTIVE", "Bag", "Blue", "Laptop bag", "Library")));
        assertEquals(0.0, service.score(lost, new LostFoundMatchingService.Item("bob", "LOST", "ACTIVE", "Bag", "Blue", "Laptop bag", "Library")));
    }

    @Test void lostFoundRanksOnlyOppositeOwnerCandidatesAboveThreshold() {
        var service = new LostFoundMatchingService();
        var source = new LostFoundMatchingService.Item("alice", "LOST", "ACTIVE", "Bag", "Blue", "Laptop bag", "Library");
        var match = new LostFoundMatchingService.Candidate("match", new LostFoundMatchingService.Item(
                "bob", "FOUND", "ACTIVE", "Bag", "Blue", "Laptop bag", "Library"));
        var own = new LostFoundMatchingService.Candidate("own", new LostFoundMatchingService.Item(
                "alice", "FOUND", "ACTIVE", "Bag", "Blue", "Laptop bag", "Library"));
        assertEquals(List.of("match"), service.matches(source, List.of(own, match), 0.6)
                .stream().map(LostFoundMatchingService.Match::id).toList());
    }

    @Test void integrityFlagIsForReviewAtConfiguredThreshold() {
        var service = new IntegrityCheckerService(0.5);
        var result = service.compare("alpha beta", "alpha gamma");
        assertEquals(1.0 / 3.0, result.score());
        assertFalse(result.flaggedForReview());
        assertThrows(IllegalArgumentException.class, () -> new IntegrityCheckerService(1.1));
    }
}
