package com.studyflow.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UploadResponse {
    private String fileKey;
    private String fileUrl;
    private String fileName;
    private Long fileSize;
    private String contentType;

    public static UploadResponse mock(String fileName, String contentType) {
        String fileKey = "uploads/" + System.currentTimeMillis() + "_" + fileName;
        // Mock URL，实际项目替换为 OSS URL
        String fileUrl = "https://oss.studyflow.com/" + fileKey;
        return UploadResponse.builder()
                .fileKey(fileKey)
                .fileUrl(fileUrl)
                .fileName(fileName)
                .fileSize(0L)
                .contentType(contentType)
                .build();
    }
}