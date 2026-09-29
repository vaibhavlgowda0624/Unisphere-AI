package edu.unisphere.api;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import edu.unisphere.api.security.AuthenticatedUser;
import edu.unisphere.api.security.UserAuthenticator;

@SpringBootTest
@AutoConfigureMockMvc
class IntelligenceControllerTest {
    @Autowired MockMvc mvc;
    @MockitoBean UserAuthenticator authenticator;

    @Test void anonymousIntegrityRequestIsRejected() throws Exception {
        mvc.perform(post("/api/intelligence/integrity")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"sourceText\":\"alpha\",\"candidateText\":\"alpha\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test void studentCannotReviewIntegrity() throws Exception {
        when(authenticator.authenticate("student-token")).thenReturn(new AuthenticatedUser("s1", "STUDENT"));
        mvc.perform(post("/api/intelligence/integrity")
                .header("Authorization", "Bearer student-token")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"sourceText\":\"alpha\",\"candidateText\":\"alpha\"}"))
                .andExpect(status().isForbidden());
    }

    @Test void facultyCanReviewIntegrity() throws Exception {
        when(authenticator.authenticate("faculty-token")).thenReturn(new AuthenticatedUser("f1", "FACULTY"));
        mvc.perform(post("/api/intelligence/integrity")
                .header("Authorization", "Bearer faculty-token")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"sourceText\":\"alpha\",\"candidateText\":\"alpha\"}"))
                .andExpect(status().isOk());
    }
}
