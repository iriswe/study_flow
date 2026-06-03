package com.studyflow.dto;

import com.studyflow.entity.StudyLog;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StudyLogResponse {
    private Long id;
    private Long taskId;
    private String taskTitle;
    private Long goalId;       // ADDED
    private String goalTitle;  // ADDED
    private Integer duration;
    private String note;
    private String imageUrls;
    private StudyLog.ComprehensionScore score;
    private String problem;
    private LocalDateTime createdAt;

    public static StudyLogResponse from(StudyLog log) {
        return StudyLogResponse.builder()
                .id(log.getId())
                .taskId(log.getTask().getId())
                .taskTitle(log.getTask().getTitle())
                .goalId(log.getTask().getGoal().getId())
                .goalTitle(log.getTask().getGoal().getTitle())
                .duration(log.getDuration())
                .note(log.getNote())
                .imageUrls(log.getImageUrls())
                .score(log.getScore())
                .problem(log.getProblem())
                .createdAt(log.getCreatedAt())
                .build();
    }
}