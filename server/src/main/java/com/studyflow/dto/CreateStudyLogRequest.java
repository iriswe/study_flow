package com.studyflow.dto;

import com.studyflow.entity.StudyLog;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateStudyLogRequest {

    @NotNull(message = "任务ID不能为空")
    private Long taskId;

    @NotNull(message = "学习时长不能为空")
    private Integer duration;

    private String note;
    private String imageUrls;
    private StudyLog.ComprehensionScore score;
    private String problem;
}