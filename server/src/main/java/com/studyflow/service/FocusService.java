package com.studyflow.service;

import com.studyflow.dto.*;
import com.studyflow.entity.FocusSession;
import com.studyflow.entity.StudyLog;
import com.studyflow.entity.Task;
import com.studyflow.entity.User;
import com.studyflow.exception.BusinessException;
import com.studyflow.repository.FocusSessionRepository;
import com.studyflow.repository.TaskRepository;
import com.studyflow.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class FocusService {

    private final FocusSessionRepository focusSessionRepository;
    private final TaskRepository taskRepository;
    private final StudyLogService studyLogService;

    @Transactional(readOnly = true)
    public List<FocusSessionResponse> getSessions(UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        List<FocusSession> sessions = focusSessionRepository.findByUserOrderByCreatedAtDesc(user);
        return sessions.stream()
                .map(FocusSessionResponse::from)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<FocusSessionResponse> getTodaySessions(UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        LocalDateTime now = LocalDateTime.now();
        List<FocusSession> sessions = focusSessionRepository.findByUserAndDateRange(
                user, now.with(LocalTime.MIN), now.with(LocalTime.MAX));
        return sessions.stream()
                .map(FocusSessionResponse::from)
                .collect(Collectors.toList());
    }

    @Transactional
    public FocusSessionResponse createSession(CreateFocusSessionRequest request, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);

        Task task = null;
        if (request.getTaskId() != null) {
            task = taskRepository.findByIdAndGoalUser(request.getTaskId(), user)
                    .orElseThrow(() -> new BusinessException(404, "任务不存在"));
        }

        FocusSession session = FocusSession.builder()
                .user(user)
                .task(task)
                .duration(request.getDuration())
                .actualDuration(0)
                .status(FocusSession.SessionStatus.PENDING)
                .build();

        session = focusSessionRepository.save(session);
        return FocusSessionResponse.from(session);
    }

    @Transactional
    public FocusSessionResponse startSession(Long id, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        FocusSession session = focusSessionRepository.findById(id)
                .filter(s -> s.getUser().getId().equals(user.getId()))
                .orElseThrow(() -> new BusinessException(404, "专注记录不存在"));

        if (session.getStatus() != FocusSession.SessionStatus.PENDING &&
            session.getStatus() != FocusSession.SessionStatus.INTERRUPTED) {
            throw new BusinessException(400, "当前状态不允许开始");
        }

        session.setStatus(FocusSession.SessionStatus.RUNNING);
        session.setStartedAt(LocalDateTime.now());
        session = focusSessionRepository.save(session);

        return FocusSessionResponse.from(session);
    }

    @Transactional
    public FocusSessionResponse completeSession(Long id, int actualDuration, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        FocusSession session = focusSessionRepository.findById(id)
                .filter(s -> s.getUser().getId().equals(user.getId()))
                .orElseThrow(() -> new BusinessException(404, "专注记录不存在"));

        session.setStatus(FocusSession.SessionStatus.COMPLETED);
        session.setActualDuration(actualDuration);
        session.setEndedAt(LocalDateTime.now());
        session = focusSessionRepository.save(session);

        // 如果关联了任务，自动创建学习记录
        if (session.getTask() != null && actualDuration > 0) {
            try {
                CreateStudyLogRequest logRequest = new CreateStudyLogRequest();
                logRequest.setTaskId(session.getTask().getId());
                logRequest.setDuration(actualDuration);
                logRequest.setScore(StudyLog.ComprehensionScore.UNDERSTAND);
                studyLogService.createStudyLog(logRequest, userPrincipal);
            } catch (Exception e) {
                log.warn("自动创建学习记录失败: {}", e.getMessage());
            }
        }

        return FocusSessionResponse.from(session);
    }

    @Transactional
    public FocusSessionResponse interruptSession(Long id, int actualDuration, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        FocusSession session = focusSessionRepository.findById(id)
                .filter(s -> s.getUser().getId().equals(user.getId()))
                .orElseThrow(() -> new BusinessException(404, "专注记录不存在"));

        session.setStatus(FocusSession.SessionStatus.INTERRUPTED);
        session.setActualDuration(actualDuration);
        session.setEndedAt(LocalDateTime.now());
        session = focusSessionRepository.save(session);

        return FocusSessionResponse.from(session);
    }

    /**
     * 获取今日累计专注时长（分钟）。
     * COALESCE 保证永不为 null，没有记录时返回 0。
     */
    @Transactional(readOnly = true)
    public int getTodayFocusDuration(UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        LocalDateTime startOfDay = LocalDateTime.now().with(LocalTime.MIN);
        Integer result = focusSessionRepository.sumCompletedDurationByUserAndDate(user, startOfDay);
        return result != null ? result : 0;
    }

    private User getUser(UserPrincipal userPrincipal) {
        return User.builder()
                .id(userPrincipal.getId())
                .username(userPrincipal.getUsername())
                .build();
    }
}
