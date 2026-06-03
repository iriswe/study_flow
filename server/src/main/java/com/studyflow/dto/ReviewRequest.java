package com.studyflow.dto;

import com.studyflow.entity.Review;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ReviewRequest {

    @NotNull(message = "复习反馈不能为空")
    private Review.ReviewResponse response;

    // 可选的复习笔记（独立于 Task.note）
    private String note;
}
