package com.community.micrologistics.exception

import java.util.UUID

class TaskNotFoundException : RuntimeException {
    constructor(taskId: UUID) : super("Task $taskId was not found")
    constructor(message: String) : super(message)
}
