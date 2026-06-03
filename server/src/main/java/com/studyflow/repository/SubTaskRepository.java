package com.studyflow.repository;

import com.studyflow.entity.Task;
import com.studyflow.entity.SubTask;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SubTaskRepository extends JpaRepository<SubTask, Long> {

    List<SubTask> findByTaskOrderBySortOrderAsc(Task task);

    long countByTask(Task task);

    long countByTaskAndCompleted(Task task, Boolean completed);
}