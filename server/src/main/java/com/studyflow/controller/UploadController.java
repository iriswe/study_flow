package com.studyflow.controller;

import com.studyflow.dto.ApiResponse;
import com.studyflow.dto.UploadResponse;
import com.studyflow.service.UploadService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/upload")
@RequiredArgsConstructor
@Tag(name = "文件上传", description = "图片上传（Mock）")
public class UploadController {

    private final UploadService uploadService;

    @Operation(summary = "上传图片", description = "上传图片文件（Mock 实现，OSS 开通后替换）")
    @PostMapping(value = "/image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<UploadResponse>> uploadImage(
            @RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(400, "请选择要上传的文件"));
        }

        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(400, "只支持上传图片文件"));
        }

        if (file.getSize() > 10 * 1024 * 1024) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(400, "文件大小不能超过 10MB"));
        }

        UploadResponse response = uploadService.uploadImage(file);
        return ResponseEntity.ok(ApiResponse.success("上传成功", response));
    }

    @Operation(summary = "获取预签名上传 URL", description = "获取预签名 URL 用于直传 OSS（Mock）")
    @GetMapping("/presigned-url")
    public ResponseEntity<ApiResponse<String>> getPresignedUploadUrl(
            @RequestParam String fileName,
            @RequestParam(defaultValue = "image/jpeg") String contentType) {
        if (contentType == null || !contentType.startsWith("image/")) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(400, "只支持图片类型"));
        }

        String presignedUrl = uploadService.generatePresignedUploadUrl(fileName, contentType);
        return ResponseEntity.ok(ApiResponse.success(presignedUrl));
    }
}