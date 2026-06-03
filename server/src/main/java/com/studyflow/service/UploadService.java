package com.studyflow.service;

import com.studyflow.dto.UploadResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

@Slf4j
@Service
public class UploadService {

    // TODO: OSS 开通后替换为真实的 OSS 客户端
    // import com.aliyun.oss.OSS;
    // import com.aliyun.oss.OSSClientBuilder;

    /**
     * Mock 图片上传
     * 实际项目中：
     * 1. 调用阿里云 OSS 生成预签名 URL
     * 2. 或直接上传到 OSS
     */
    public UploadResponse uploadImage(MultipartFile file) {
        String originalFilename = file.getOriginalFilename();
        String contentType = file.getContentType();

        log.info("Mock 上传图片: {}, 大小: {} bytes, 类型: {}",
                originalFilename, file.getSize(), contentType);

        // 生成唯一的文件 key
        String fileKey = generateFileKey(originalFilename);

        // TODO: OSS 开通后实现真实的文件上传
        // String fileUrl = uploadToOSS(file, fileKey);

        // Mock 返回
        return UploadResponse.builder()
                .fileKey(fileKey)
                .fileUrl("https://oss.studyflow.com/" + fileKey) // Mock URL
                .fileName(originalFilename)
                .fileSize(file.getSize())
                .contentType(contentType)
                .build();
    }

    /**
     * 生成预签名上传 URL（前端直接上传到 OSS）
     * TODO: OSS 开通后实现
     */
    public String generatePresignedUploadUrl(String fileName, String contentType) {
        String fileKey = generateFileKey(fileName);

        // TODO: OSS 开通后生成真实的预签名 URL
        // OSS ossClient = new OSSClientBuilder().build(...);
        // GeneratePresignedUrlRequest request = new GeneratePresignedUrlRequest(bucketName, fileKey);
        // request.setExpiration(new Date(System.currentTimeMillis() + 3600 * 1000)); // 1小时有效期
        // URL signedUrl = ossClient.generatePresignedUrl(request);

        log.info("生成 Mock 预签名 URL: {}", fileKey);

        // Mock 返回一个前端可以直接 PUT 的 URL
        return "https://oss.studyflow.com/" + fileKey + "?mock=true";
    }

    private String generateFileKey(String fileName) {
        String extension = "";
        if (fileName != null && fileName.contains(".")) {
            extension = fileName.substring(fileName.lastIndexOf("."));
        }
        return "uploads/" + UUID.randomUUID().toString().replace("-", "") + extension;
    }
}