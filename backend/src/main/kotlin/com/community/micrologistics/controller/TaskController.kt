package com.community.micrologistics.controller

import com.community.micrologistics.dto.task.CreateTaskRequest
import com.community.micrologistics.dto.task.NearbyTaskResponse
import com.community.micrologistics.dto.task.TaskAcceptResponse
import com.community.micrologistics.dto.task.TaskConfirmResponse
import com.community.micrologistics.dto.task.TaskDetailResponse
import com.community.micrologistics.dto.task.TaskResponse
import com.community.micrologistics.dto.task.TaskStatusUpdateRequest
import com.community.micrologistics.dto.task.TaskStatusUpdateResponse
import com.community.micrologistics.service.TaskService
import com.community.micrologistics.security.AppPrincipal
import jakarta.validation.Valid
import org.springframework.validation.annotation.Validated
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestHeader
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import org.springframework.security.core.annotation.AuthenticationPrincipal
import java.util.UUID

@Validated
@RestController
@RequestMapping("/api/v1/tasks")
class TaskController(
    private val taskService: TaskService
) {
    @PostMapping
    fun createTask(
        @AuthenticationPrincipal principal: AppPrincipal,
        @Valid @RequestBody request: CreateTaskRequest
    ): TaskResponse = taskService.createTask(principal.userId, request)

    @GetMapping("/nearby")
    fun nearbyTasks(
        @AuthenticationPrincipal principal: AppPrincipal,
        @RequestParam latitude: Double,
        @RequestParam longitude: Double
    ): List<NearbyTaskResponse> = taskService.findNearbyTasks(principal.userId, latitude, longitude)

    @GetMapping("/mine")
    fun myTasks(@AuthenticationPrincipal principal: AppPrincipal): List<TaskDetailResponse> =
        taskService.listMyTasks(principal.userId)

    @GetMapping("/{id}")
    fun taskDetail(
        @AuthenticationPrincipal principal: AppPrincipal,
        @PathVariable id: UUID
    ): TaskDetailResponse = taskService.getTask(principal.userId, id)

    @PostMapping("/{id}/accept")
    fun acceptTask(
        @AuthenticationPrincipal principal: AppPrincipal,
        @PathVariable id: UUID,
        @RequestParam latitude: Double,
        @RequestParam longitude: Double
    ): TaskAcceptResponse = taskService.acceptTask(principal.userId, id, latitude, longitude)

    @PostMapping("/by-code/{code}/accept")
    fun acceptPrivateTask(
        @AuthenticationPrincipal principal: AppPrincipal,
        @PathVariable code: String,
        @RequestParam latitude: Double,
        @RequestParam longitude: Double
    ): TaskAcceptResponse = taskService.acceptTaskByCode(principal.userId, code, latitude, longitude)

    @PostMapping("/{id}/update-status")
    fun updateTaskStatus(
        @AuthenticationPrincipal principal: AppPrincipal,
        @PathVariable id: UUID,
        @Valid @RequestBody request: TaskStatusUpdateRequest
    ): TaskStatusUpdateResponse = taskService.updateTaskStatus(principal.userId, id, request)

    @PostMapping("/{id}/confirm")
    fun confirmTask(
        @AuthenticationPrincipal principal: AppPrincipal,
        @PathVariable id: UUID
    ): TaskConfirmResponse = taskService.confirmTask(principal.userId, id)

    @PostMapping("/{id}/cancel")
    fun cancelTask(
        @AuthenticationPrincipal principal: AppPrincipal,
        @PathVariable id: UUID
    ): TaskDetailResponse = taskService.cancelTask(principal.userId, id)
}
