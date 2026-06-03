package com.studyflow.service;

import com.studyflow.dto.*;
import com.studyflow.entity.Goal;
import com.studyflow.entity.HabitCheckin;
import com.studyflow.entity.SubTask;
import com.studyflow.entity.Task;
import com.studyflow.entity.User;
import com.studyflow.exception.BusinessException;
import com.studyflow.repository.GoalRepository;
import com.studyflow.repository.HabitCheckinRepository;
import com.studyflow.repository.SubTaskRepository;
import com.studyflow.repository.TaskRepository;
import com.studyflow.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class TaskService {

    private final TaskRepository taskRepository;
    private final GoalRepository goalRepository;
    private final SubTaskRepository subTaskRepository;
    private final HabitCheckinRepository habitCheckinRepository;

    @Transactional(readOnly = true)
    public List<TaskResponse> getTasks(UserPrincipal userPrincipal, Long goalId, boolean todayOnly) {
        List<Task> tasks;
        if (goalId != null) {
            Goal goal = goalRepository.findByIdAndUser(goalId, getUser(userPrincipal))
                    .orElse(null);
            if (goal != null) {
                tasks = taskRepository.findByGoal(goal);
            } else {
                tasks = List.of();
            }
        } else {
            tasks = taskRepository.findByUserOrderByPriority(getUser(userPrincipal));
        }
        if (todayOnly) {
            tasks = tasks.stream()
                    .filter(t -> t.getTaskType() != Task.TaskType.HABIT || isDueToday(t))
                    .collect(Collectors.toList());
        }
        Set<Long> todayCheckedInIds = habitCheckinRepository.findTodayCheckinTaskIds(LocalDate.now());
        return tasks.stream().map(t -> {
            TaskResponse resp = toTaskResponse(t);
            if (t.getTaskType() == Task.TaskType.HABIT) {
                resp.setCheckedInToday(todayCheckedInIds.contains(t.getId()));
            }
            return resp;
        }).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public TaskResponse getTask(Long id, UserPrincipal userPrincipal) {
        Task task = taskRepository.findByIdAndGoalUser(id, getUser(userPrincipal))
                .orElseThrow(() -> new BusinessException(404, "任务不存在"));
        TaskResponse resp = toTaskResponse(task);
        if (task.getTaskType() == Task.TaskType.HABIT) {
            resp.setCheckedInToday(
                    habitCheckinRepository.findByTaskAndCheckinDate(task, LocalDate.now()).isPresent());
        }
        return resp;
    }

    @Transactional
    public TaskResponse createTask(CreateTaskRequest request, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);

        // 参数校验
        if (request.getTitle() == null || request.getTitle().isBlank()) {
            throw new BusinessException(400, "任务标题不能为空");
        }
        if (request.getTitle().length() > 200) {
            throw new BusinessException(400, "任务标题不能超过 200 个字符");
        }
        if (request.getGoalId() == null) {
            throw new BusinessException(400, "目标ID不能为空");
        }
        if (request.getPriority() == null) {
            throw new BusinessException(400, "优先级不能为空");
        }

        Goal goal = goalRepository.findByIdAndUser(request.getGoalId(), user)
                .orElseThrow(() -> new BusinessException(404, "目标不存在"));

        // 习惯任务必须有重复频率
        if (request.getTaskType() == Task.TaskType.HABIT && request.getRecurringFrequency() == null) {
            throw new BusinessException(400, "习惯任务必须设置重复频率");
        }

        // 子任务标题校验
        if (request.getSubTasks() != null) {
            for (int i = 0; i < request.getSubTasks().size(); i++) {
                String subTitle = request.getSubTasks().get(i);
                if (subTitle == null || subTitle.isBlank()) {
                    throw new BusinessException(400, "子任务标题不能为空");
                }
                if (subTitle.length() > 200) {
                    throw new BusinessException(400, "子任务标题不能超过 200 个字符");
                }
            }
        }

        Task task = Task.builder()
                .goal(goal)
                .title(request.getTitle())
                .priority(request.getPriority())
                .estimateMinutes(request.getEstimateMinutes())
                .dueDate(request.getDueDate())
                .note(request.getNote())
                .status(Task.TaskStatus.PENDING)
                .sortOrder(0)
                .taskType(request.getTaskType() != null ? request.getTaskType() : Task.TaskType.PROGRESSION)
                .recurringFrequency(request.getRecurringFrequency())
                .recurringTime(request.getRecurringTime())
                .currentStreak(0)
                .longestStreak(0)
                .totalCompleted(0)
                .build();

        task = taskRepository.save(task);

        // 创建子任务
        log.info("开始创建子任务, subTasks={}, taskId={}", request.getSubTasks(), task.getId());
        if (request.getSubTasks() != null && !request.getSubTasks().isEmpty()) {
            int order = 0;
            for (String subTaskTitle : request.getSubTasks()) {
                log.info("创建子任务: taskId={}, title={}, order={}", task.getId(), subTaskTitle, order);
                SubTask subTask = SubTask.builder()
                        .task(task)
                        .title(subTaskTitle)
                        .completed(false)
                        .sortOrder(order++)
                        .build();
                SubTask saved = subTaskRepository.save(subTask);
                log.info("子任务保存成功: subtaskId={}, title={}", saved.getId(), saved.getTitle());
            }
        }

        updateGoalProgress(goal);

        TaskResponse resp = toTaskResponse(task);
        if (task.getTaskType() == Task.TaskType.HABIT) {
            resp.setCheckedInToday(false);
        }
        return resp;
    }

    @Transactional
    public TaskResponse updateTask(Long id, UpdateTaskRequest request, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        Task task = taskRepository.findByIdAndGoalUser(id, user)
                .orElseThrow(() -> new BusinessException(404, "任务不存在"));

        // 标题校验
        if (request.getTitle() != null && request.getTitle().isBlank()) {
            throw new BusinessException(400, "任务标题不能为空");
        }
        if (request.getTitle() != null && request.getTitle().length() > 200) {
            throw new BusinessException(400, "任务标题不能超过 200 个字符");
        }

        // 习惯任务必须有重复频率
        if (request.getTaskType() == Task.TaskType.HABIT
                && request.getRecurringFrequency() == null
                && task.getTaskType() != Task.TaskType.HABIT) {
            throw new BusinessException(400, "习惯任务必须设置重复频率");
        }

        // 子任务标题校验
        if (request.getSubTasks() != null) {
            for (int i = 0; i < request.getSubTasks().size(); i++) {
                String subTitle = request.getSubTasks().get(i);
                if (subTitle == null || subTitle.isBlank()) {
                    throw new BusinessException(400, "子任务标题不能为空");
                }
                if (subTitle.length() > 200) {
                    throw new BusinessException(400, "子任务标题不能超过 200 个字符");
                }
            }
        }

        if (request.getTitle() != null) {
            task.setTitle(request.getTitle());
        }
        if (request.getGoalId() != null) {
            Goal newGoal = goalRepository.findByIdAndUser(request.getGoalId(), user)
                    .orElseThrow(() -> new BusinessException(404, "目标不存在"));
            task.setGoal(newGoal);
        }
        if (request.getPriority() != null) {
            task.setPriority(request.getPriority());
        }
        if (request.getStatus() != null) {
            task.setStatus(request.getStatus());
        }
        if (request.getEstimateMinutes() != null) {
            task.setEstimateMinutes(request.getEstimateMinutes());
        }
        if (request.getActualMinutes() != null) {
            task.setActualMinutes(request.getActualMinutes());
        }
        if (request.getDueDate() != null) {
            task.setDueDate(request.getDueDate());
        }
        if (request.getNote() != null) {
            task.setNote(request.getNote());
        }
        if (request.getSortOrder() != null) {
            task.setSortOrder(request.getSortOrder());
        }
        if (request.getTaskType() != null) {
            task.setTaskType(request.getTaskType());
        }
        if (request.getRecurringFrequency() != null) {
            task.setRecurringFrequency(request.getRecurringFrequency());
        }
        if (request.getRecurringTime() != null) {
            task.setRecurringTime(request.getRecurringTime());
        }

        // 更新子任务列表
        if (request.getSubTasks() != null) {
            // 获取当前子任务
            List<SubTask> existingSubTasks = subTaskRepository.findByTaskOrderBySortOrderAsc(task);

            // 更新或新增子任务
            for (int i = 0; i < request.getSubTasks().size(); i++) {
                String subTaskTitle = request.getSubTasks().get(i);
                if (i < existingSubTasks.size()) {
                    // 更新现有子任务标题
                    SubTask existing = existingSubTasks.get(i);
                    existing.setTitle(subTaskTitle);
                    subTaskRepository.save(existing);
                } else {
                    // 新增子任务
                    SubTask newSubTask = SubTask.builder()
                            .task(task)
                            .title(subTaskTitle)
                            .completed(false)
                            .sortOrder(i)
                            .build();
                    subTaskRepository.save(newSubTask);
                }
            }

            // 删除超出范围的子任务（保留编辑时删掉的）
            for (int i = request.getSubTasks().size(); i < existingSubTasks.size(); i++) {
                subTaskRepository.delete(existingSubTasks.get(i));
            }
        }

        task = taskRepository.save(task);
        updateGoalProgress(task.getGoal());

        return toTaskResponse(task);
    }

    @Transactional
    public TaskResponse completeTask(Long id, UserPrincipal userPrincipal) {
        Task task = getTaskEntity(id, userPrincipal);
        if (task.getTaskType() == Task.TaskType.HABIT) {
            LocalDate today = LocalDate.now();
            if (habitCheckinRepository.findByTaskAndCheckinDate(task, today).isPresent()) {
                TaskResponse resp = toTaskResponse(task);
                resp.setCheckedInToday(true);
                return resp;
            }
            try {
                habitCheckinRepository.save(new HabitCheckin(task, today));
            } catch (DataIntegrityViolationException e) {
                TaskResponse resp = toTaskResponse(task);
                resp.setCheckedInToday(true);
                return resp;
            }
            recalcStreaks(task);
            updateGoalProgress(task.getGoal());
            TaskResponse resp = toTaskResponse(task);
            resp.setCheckedInToday(true);
            return resp;
        }
        task.setStatus(Task.TaskStatus.COMPLETED);
        if (task.getSubTasks() != null && !task.getSubTasks().isEmpty()) {
            for (SubTask st : task.getSubTasks()) {
                if (!Boolean.TRUE.equals(st.getCompleted())) {
                    st.setCompleted(true);
                    subTaskRepository.save(st);
                }
            }
        }
        task = taskRepository.save(task);
        updateGoalProgress(task.getGoal());
        return toTaskResponse(task);
    }

    @Transactional
    public void deleteTask(Long id, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        Task task = taskRepository.findByIdAndGoalUser(id, user)
                .orElseThrow(() -> new BusinessException(404, "任务不存在"));

        Goal goal = task.getGoal();
        taskRepository.delete(task);
        updateGoalProgress(goal);
    }

    @Transactional
    public TaskResponse uncompleteTask(Long id, UserPrincipal userPrincipal) {
        Task task = getTaskEntity(id, userPrincipal);
        if (task.getTaskType() == Task.TaskType.HABIT) {
            LocalDate today = LocalDate.now();
            habitCheckinRepository.deleteByTaskAndCheckinDate(task, today);
            recalcStreaks(task);
            updateGoalProgress(task.getGoal());
            TaskResponse resp = toTaskResponse(task);
            resp.setCheckedInToday(false);
            return resp;
        }
        task.setStatus(Task.TaskStatus.PENDING);
        if (task.getSubTasks() != null && !task.getSubTasks().isEmpty()) {
            for (SubTask st : task.getSubTasks()) {
                if (Boolean.TRUE.equals(st.getCompleted())) {
                    st.setCompleted(false);
                    subTaskRepository.save(st);
                }
            }
        }
        task = taskRepository.save(task);
        updateGoalProgress(task.getGoal());
        return toTaskResponse(task);
    }

    @Transactional
    public TaskResponse batchCreateSubTasks(Long taskId, BatchCreateSubTaskRequest request, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        Task task = taskRepository.findByIdAndGoalUser(taskId, user)
                .orElseThrow(() -> new BusinessException(404, "任务不存在"));

        // 参数校验 - 根据模式分别校验
        List<String> subTaskTitles;
        if (request.getMode() == BatchCreateSubTaskRequest.Mode.PASTE) {
            if (request.getItems() == null || request.getItems().isEmpty()) {
                throw new BusinessException(400, "粘贴模式必须提供子任务列表");
            }
            for (String item : request.getItems()) {
                if (item == null || item.isBlank()) {
                    throw new BusinessException(400, "子任务标题不能为空");
                }
                if (item.length() > 200) {
                    throw new BusinessException(400, "子任务标题不能超过 200 个字符");
                }
            }
            subTaskTitles = request.getItems();
        } else {
            // 序列生成模式
            String prefix = request.getPrefix() != null ? request.getPrefix() : "";
            String suffix = request.getSuffix() != null ? request.getSuffix() : "";
            String placeholder = request.getPlaceholder() != null ? request.getPlaceholder() : "{n}";
            int count = request.getCount() != null ? request.getCount() : 10;
            int startAt = request.getStartAt() != null ? request.getStartAt() : 1;

            List<String> generated = new ArrayList<>();
            for (int i = 0; i < count; i++) {
                String title = prefix.replace(placeholder, String.valueOf(startAt + i)) + suffix;
                generated.add(title);
            }
            subTaskTitles = generated;
        }

        // 获取当前最大排序值
        long maxSortOrder = subTaskRepository.countByTask(task);

        // 批量创建子任务
        int order = (int) maxSortOrder;
        for (String title : subTaskTitles) {
            if (title != null && !title.trim().isEmpty()) {
                SubTask subTask = SubTask.builder()
                        .task(task)
                        .title(title.trim())
                        .completed(false)
                        .sortOrder(order++)
                        .build();
                subTaskRepository.save(subTask);
            }
        }

        return toTaskResponse(task);
    }

    @Transactional
    public TaskResponse toggleSubTask(Long taskId, Long subTaskId, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        Task task = taskRepository.findByIdAndGoalUser(taskId, user)
                .orElseThrow(() -> new BusinessException(404, "任务不存在"));

        SubTask subTask = subTaskRepository.findById(subTaskId)
                .orElseThrow(() -> new BusinessException(404, "子任务不存在"));

        if (!subTask.getTask().getId().equals(taskId)) {
            throw new BusinessException(403, "无权操作此子任务");
        }

        boolean newCompletedState = !Boolean.TRUE.equals(subTask.getCompleted());
        subTask.setCompleted(newCompletedState);
        subTaskRepository.save(subTask);

        // Refresh task to get fresh subtask collection (JPA doesn't auto-refresh parent)
        task = taskRepository.findById(task.getId()).orElse(task);

        if (task.getTaskType() == Task.TaskType.HABIT) {
            boolean allDone = task.getSubTasks().stream()
                    .allMatch(s -> s.getId().equals(subTaskId)
                            ? newCompletedState
                            : Boolean.TRUE.equals(s.getCompleted()));
            if (allDone) {
                LocalDate today = LocalDate.now();
                if (!habitCheckinRepository.findByTaskAndCheckinDate(task, today).isPresent()) {
                    try {
                        habitCheckinRepository.save(new HabitCheckin(task, today));
                    } catch (DataIntegrityViolationException e) { /* idempotent */ }
                    recalcStreaks(task);
                }
            } else {
                habitCheckinRepository.deleteByTaskAndCheckinDate(task, LocalDate.now());
                recalcStreaks(task);
            }
            updateGoalProgress(task.getGoal());
            TaskResponse resp = toTaskResponse(task);
            resp.setCheckedInToday(allDone);
            return resp;
        }

        // Progression tasks — only set COMPLETED if all subtasks done
        boolean allDone = task.getSubTasks().stream().allMatch(s ->
                s.getId().equals(subTaskId) ? newCompletedState : Boolean.TRUE.equals(s.getCompleted()));
        if (newCompletedState) {
            task.setStatus(allDone ? Task.TaskStatus.COMPLETED : Task.TaskStatus.IN_PROGRESS);
        } else {
            boolean anyCompleted = task.getSubTasks().stream()
                    .anyMatch(s -> !s.getId().equals(subTaskId) && Boolean.TRUE.equals(s.getCompleted()));
            task.setStatus(anyCompleted ? Task.TaskStatus.IN_PROGRESS : Task.TaskStatus.PENDING);
        }
        taskRepository.save(task);
        updateGoalProgress(task.getGoal());
        return toTaskResponse(task);
    }

    private void recalcStreaks(Task task) {
        List<HabitCheckin> checkins = habitCheckinRepository
                .findByTaskAndCheckinDateAfterOrderByCheckinDateDesc(task, LocalDate.now().minusDays(400));
        task.setTotalCompleted((int) habitCheckinRepository.countByTask(task));
        if (checkins.isEmpty()) {
            task.setCurrentStreak(0);
            task.setLongestStreak(0);
            task.setLastCompletedDate(null);
            taskRepository.save(task);
            return;
        }
        task.setLastCompletedDate(checkins.get(0).getCheckinDate().atStartOfDay());

        // Current streak: consecutive days from most recent checkin
        int currentStreak = 0;
        LocalDate expected = checkins.get(0).getCheckinDate();
        for (HabitCheckin c : checkins) {
            if (c.getCheckinDate().equals(expected)) {
                currentStreak++;
                expected = expected.minusDays(1);
            } else {
                break;
            }
        }
        task.setCurrentStreak(currentStreak);

        // Longest streak: scan all checkins for longest consecutive run
        int longest = 0;
        int run = 0;
        LocalDate prev = null;
        for (int i = checkins.size() - 1; i >= 0; i--) {
            LocalDate d = checkins.get(i).getCheckinDate();
            if (prev != null && d.equals(prev.plusDays(1))) {
                run++;
            } else {
                run = 1;
            }
            if (run > longest) longest = run;
            prev = d;
        }
        // Preserve historical longest streak (don't decrease on uncomplete)
        if (longest > task.getLongestStreak()) {
            task.setLongestStreak(longest);
        }
        taskRepository.save(task);
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

    private Task getTaskEntity(Long id, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        return taskRepository.findByIdAndGoalUser(id, user)
                .orElseThrow(() -> new BusinessException(404, "任务不存在"));
    }

    private TaskResponse toTaskResponse(Task task) {
        List<SubTask> subTasks = subTaskRepository.findByTaskOrderBySortOrderAsc(task);
        List<TaskResponse.SubTaskResponse> subTaskResponses = subTasks.stream()
                .map(st -> TaskResponse.SubTaskResponse.builder()
                        .id(st.getId())
                        .title(st.getTitle())
                        .completed(st.getCompleted())
                        .sortOrder(st.getSortOrder())
                        .build())
                .collect(Collectors.toList());

        return TaskResponse.from(task, subTaskResponses);
    }

    private void updateGoalProgress(Goal goal) {
        List<Task> allTasks = taskRepository.findByGoal(goal);
        int total = 0;
        int done = 0;
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

        BigDecimal progress = total > 0
                ? BigDecimal.valueOf(done).multiply(BigDecimal.valueOf(100))
                        .divide(BigDecimal.valueOf(total), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;
        goal.setProgress(progress);
        goalRepository.save(goal);
    }

    private User getUser(UserPrincipal userPrincipal) {
        return User.builder()
                .id(userPrincipal.getId())
                .username(userPrincipal.getUsername())
                .build();
    }
}