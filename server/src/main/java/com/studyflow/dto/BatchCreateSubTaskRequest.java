package com.studyflow.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;

import java.util.List;

@Data
public class BatchCreateSubTaskRequest {

    public enum Mode {
        SEQUENCE,  // 序列生成
        PASTE      // 粘贴导入
    }

    private Mode mode = Mode.PASTE;

    private List<String> items;  // 粘贴模式必填，序列模式可不传

    // 序列生成模式
    private String prefix;      // 前缀，如 "第{章}节"
    private String suffix;      // 后缀，如 "总结"
    @Min(value = 1, message = "序列生成数量最少为 1")
    @Max(value = 500, message = "序列生成数量不能超过 500")
    private Integer count;      // 数量
    @Min(value = 0, message = "起始数字不能为负数")
    @Max(value = 999999, message = "起始数字不能超过 999999")
    private Integer startAt;    // 起始数字，默认为1
    private String placeholder; // 占位符，默认 "{n}"
}