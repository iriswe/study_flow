package com.studyflow.dto;

import com.studyflow.entity.FocusSession;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FocusSessionResponse {
    private Long id;
    private Long taskId;
    private String taskTitle;
    private Integer duration;
    private Integer actualDuration;
    private FocusSession.SessionStatus status;
    private LocalDateTime startedAt;
    private LocalDateTime endedAt;
    private LocalDateTime createdAt;

    public static FocusSessionResponse from(FocusSession session) {
        return FocusSessionResponse.builder()
                .id(session.getId())
                .taskId(session.getTask() != null ? session.getTask().getId() : null)
                .taskTitle(session.getTask() != null ? session.getTask().getTitle() : null)
                .duration(session.getDuration())
                .actualDuration(session.getActualDuration())
                .status(session.getStatus())
                .startedAt(session.getStartedAt())
                .endedAt(session.getEndedAt())
                .createdAt(session.getCreatedAt())
                .build();
    }
}