package com.studyflow.service;

import com.studyflow.dto.*;
import com.studyflow.entity.Goal;
import com.studyflow.entity.StudyLog;
import com.studyflow.entity.Task;
import com.studyflow.entity.User;
import com.studyflow.exception.BusinessException;
import com.studyflow.repository.GoalRepository;
import com.studyflow.repository.StudyLogRepository;
import com.studyflow.repository.TaskRepository;
import com.studyflow.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StudyLogService {

    private final StudyLogRepository studyLogRepository;
    private final TaskRepository taskRepository;
    private final GoalRepository goalRepository;

    @Transactional(readOnly = true)
    public List<StudyLogResponse> getStudyLogs(UserPrincipal userPrincipal, Pageable pageable) {
        User user = getUser(userPrincipal);
        Page<StudyLog> logs = studyLogRepository.findByUserOrderByCreatedAtDesc(user, pageable);

        return logs.getContent().stream()
                .map(StudyLogResponse::from)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<StudyLogResponse> getStudyLogsByGoalId(UserPrincipal userPrincipal, Long goalId) {
        User user = getUser(userPrincipal);
        List<StudyLog> logs = studyLogRepository.findByUserAndGoalId(user, goalId);
        return logs.stream()
                .map(StudyLogResponse::from)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<StudyLogResponse> getStudyLogsByDateRange(
            UserPrincipal userPrincipal,
            LocalDateTime start,
            LocalDateTime end) {
        User user = getUser(userPrincipal);
        List<StudyLog> logs = studyLogRepository.findByUserAndCreatedAtBetweenOrderByCreatedAtDesc(user, start, end);

        return logs.stream()
                .map(StudyLogResponse::from)
                .collect(Collectors.toList());
    }

    @Transactional
    public StudyLogResponse createStudyLog(CreateStudyLogRequest request, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        Task task = taskRepository.findByIdAndGoalUser(request.getTaskId(), user)
                .orElseThrow(() -> new BusinessException(404, "任务不存在"));

        StudyLog log = StudyLog.builder()
                .user(user)
                .task(task)
                .duration(request.getDuration())
                .note(request.getNote())
                .imageUrls(request.getImageUrls())
                .score(request.getScore())
                .problem(request.getProblem())
                .build();

        log = studyLogRepository.save(log);
        return StudyLogResponse.from(log);
    }

    @Transactional(readOnly = true)
    public StudyLogResponse getStudyLog(Long id, UserPrincipal userPrincipal) {
        StudyLog log = studyLogRepository.findById(id)
                .filter(l -> l.getUser().getId().equals(userPrincipal.getId()))
                .orElseThrow(() -> new BusinessException(404, "记录不存在"));
        return StudyLogResponse.from(log);
    }

    @Transactional
    public StudyLogResponse updateStudyLog(Long id, CreateStudyLogRequest request, UserPrincipal userPrincipal) {
        StudyLog log = studyLogRepository.findById(id)
                .filter(l -> l.getUser().getId().equals(userPrincipal.getId()))
                .orElseThrow(() -> new BusinessException(404, "记录不存在"));
        if (request.getTaskId() != null) {
            Task task = taskRepository.findByIdAndGoalUser(request.getTaskId(), getUser(userPrincipal))
                    .orElseThrow(() -> new BusinessException(404, "任务不存在"));
            log.setTask(task);
        }
        if (request.getDuration() != null) {
            log.setDuration(request.getDuration());
        }
        if (request.getNote() != null) {
            log.setNote(request.getNote());
        }
        if (request.getImageUrls() != null) {
            log.setImageUrls(request.getImageUrls());
        }
        if (request.getScore() != null) {
            log.setScore(request.getScore());
        }
        if (request.getProblem() != null) {
            log.setProblem(request.getProblem());
        }

        log = studyLogRepository.save(log);
        return StudyLogResponse.from(log);
    }

    @Transactional
    public void deleteStudyLog(Long id, UserPrincipal userPrincipal) {
        StudyLog log = studyLogRepository.findById(id)
                .filter(l -> l.getUser().getId().equals(userPrincipal.getId()))
                .orElseThrow(() -> new BusinessException(404, "记录不存在"));
        studyLogRepository.delete(log);
    }

    @Transactional(readOnly = true)
    public Integer getTodayStudyDuration(UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        LocalDateTime startOfDay = LocalDateTime.now().with(LocalTime.MIN);
        return studyLogRepository.sumDurationByUserAndDate(user, startOfDay);
    }

    private User getUser(UserPrincipal userPrincipal) {
        return User.builder()
                .id(userPrincipal.getId())
                .username(userPrincipal.getUsername())
                .build();
    }
}