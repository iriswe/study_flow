package com.studyflow.service;

import com.studyflow.dto.*;
import com.studyflow.entity.Goal;
import com.studyflow.entity.Task;
import com.studyflow.entity.User;
import com.studyflow.exception.BusinessException;
import com.studyflow.repository.GoalRepository;
import com.studyflow.repository.HabitCheckinRepository;
import com.studyflow.repository.TaskRepository;
import com.studyflow.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GoalService {

    private final GoalRepository goalRepository;
    private final TaskRepository taskRepository;
    private final HabitCheckinRepository habitCheckinRepository;

    @Transactional(readOnly = true)
    public List<GoalResponse> getGoals(UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        List<Goal> goals = goalRepository.findByUserOrderByCreatedAtDesc(user);

        return goals.stream()
                .map(goal -> {
                    int[] counts = countTasks(goal);
                    return GoalResponse.from(goal, counts[0], counts[1]);
                })
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public GoalResponse getGoal(Long id, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        Goal goal = goalRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> new BusinessException(404, "目标不存在"));

        int[] counts = countTasks(goal);
        return GoalResponse.from(goal, counts[0], counts[1]);
    }

    @Transactional
    public GoalResponse createGoal(CreateGoalRequest request, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);

        Goal goal = Goal.builder()
                .user(user)
                .title(request.getTitle())
                .description(request.getDescription())
                .type(request.getType())
                .priority(request.getPriority())
                .deadline(request.getDeadline())
                .progress(BigDecimal.ZERO)
                .build();

        goal = goalRepository.save(goal);
        return GoalResponse.from(goal, 0, 0);
    }

    @Transactional
    public GoalResponse updateGoal(Long id, UpdateGoalRequest request, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        Goal goal = goalRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> new BusinessException(404, "目标不存在"));

        if (request.getTitle() != null) {
            goal.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            goal.setDescription(request.getDescription());
        }
        if (request.getType() != null) {
            goal.setType(request.getType());
        }
        if (request.getPriority() != null) {
            goal.setPriority(request.getPriority());
        }
        if (request.getDeadline() != null) {
            goal.setDeadline(request.getDeadline());
        }
        if (request.getProgress() != null) {
            goal.setProgress(request.getProgress());
        }

        goal = goalRepository.save(goal);

        int[] counts = countTasks(goal);
        return GoalResponse.from(goal, counts[0], counts[1]);
    }

    @Transactional
    public void deleteGoal(Long id, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        Goal goal = goalRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> new BusinessException(404, "目标不存在"));

        goalRepository.delete(goal);
    }

    private User getUser(UserPrincipal userPrincipal) {
        return User.builder()
                .id(userPrincipal.getId())
                .username(userPrincipal.getUsername())
                .build();
    }

    private int[] countTasks(Goal goal) {
        List<Task> allTasks = taskRepository.findByGoal(goal);
        int total = 0, done = 0;
        Set<Long> todayCheckedInIds = habitCheckinRepository.findTodayCheckinTaskIds(LocalDate.now());
        for (Task t : allTasks) {
            if (t.getTaskType() == Task.TaskType.HABIT) {
                if (isDueToday(t)) {
                    total++;
                    if (todayCheckedInIds.contains(t.getId())) done++;
                }
            } else {
                total++;
                if (t.getStatus() == Task.TaskStatus.COMPLETED) done++;
            }
        }
        return new int[]{total, done};
    }

    private boolean isDueToday(Task task) {
        if (task.getTaskType() != Task.TaskType.HABIT) return true;
        if (task.getRecurringFrequency() == null) return true;
        LocalDate today = LocalDate.now();
        return switch (task.getRecurringFrequency()) {
            case DAILY -> true;
            case WEEKDAYS -> today.getDayOfWeek().getValue() <= 5;
            case WEEKLY -> task.getCreatedAt() != null
                    && today.getDayOfWeek() == task.getCreatedAt().getDayOfWeek();
            default -> true;
        };
    }
}