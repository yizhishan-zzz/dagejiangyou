package com.community.micrologistics.exception

import com.community.micrologistics.dto.common.ApiErrorResponse
import jakarta.servlet.http.HttpServletRequest
import jakarta.validation.ConstraintViolationException
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.dao.OptimisticLockingFailureException
import org.springframework.validation.FieldError
import org.springframework.http.converter.HttpMessageNotReadableException
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.MissingRequestHeaderException
import org.springframework.web.bind.MissingServletRequestParameterException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException
import org.springframework.web.servlet.resource.NoResourceFoundException
import java.time.OffsetDateTime
import org.slf4j.LoggerFactory

@RestControllerAdvice
class GlobalExceptionHandler {
    private val logger = LoggerFactory.getLogger(GlobalExceptionHandler::class.java)
    @ExceptionHandler(TaskNotFoundException::class, ResourceNotFoundException::class)
    fun handleNotFound(
        exception: RuntimeException,
        request: HttpServletRequest
    ): ResponseEntity<ApiErrorResponse> = buildError(
        status = HttpStatus.NOT_FOUND,
        request = request,
        message = exception.message ?: "Resource not found"
    )

    @ExceptionHandler(NoResourceFoundException::class)
    fun handleNoResource(
        exception: NoResourceFoundException,
        request: HttpServletRequest
    ): ResponseEntity<ApiErrorResponse> = buildError(
        status = HttpStatus.NOT_FOUND,
        request = request,
        message = "接口不存在"
    )

    @ExceptionHandler(InsufficientFundsException::class)
    fun handleInsufficientFunds(
        exception: InsufficientFundsException,
        request: HttpServletRequest
    ): ResponseEntity<ApiErrorResponse> = buildError(
        status = HttpStatus.CONFLICT,
        request = request,
        message = exception.message ?: "Insufficient funds"
    )

    @ExceptionHandler(InvalidRoleException::class)
    fun handleInvalidRole(
        exception: InvalidRoleException,
        request: HttpServletRequest
    ): ResponseEntity<ApiErrorResponse> = buildError(
        status = HttpStatus.FORBIDDEN,
        request = request,
        message = exception.message ?: "Invalid role"
    )

    @ExceptionHandler(AuthenticationException::class)
    fun handleAuthentication(
        exception: AuthenticationException,
        request: HttpServletRequest
    ): ResponseEntity<ApiErrorResponse> = buildError(
        status = HttpStatus.UNAUTHORIZED,
        request = request,
        message = exception.message ?: "Authentication failed"
    )

    @ExceptionHandler(GeofenceViolationException::class)
    fun handleGeofenceViolation(
        exception: GeofenceViolationException,
        request: HttpServletRequest
    ): ResponseEntity<ApiErrorResponse> = buildError(
        status = HttpStatus.BAD_REQUEST,
        request = request,
        message = exception.message ?: "Geofence violation"
    )

    @ExceptionHandler(InvalidOperationException::class)
    fun handleInvalidOperation(
        exception: InvalidOperationException,
        request: HttpServletRequest
    ): ResponseEntity<ApiErrorResponse> = buildError(
        status = HttpStatus.CONFLICT,
        request = request,
        message = exception.message ?: "Invalid operation"
    )

    @ExceptionHandler(DataIntegrityViolationException::class)
    fun handleDataIntegrity(
        exception: DataIntegrityViolationException,
        request: HttpServletRequest
    ): ResponseEntity<ApiErrorResponse> = buildError(
        status = HttpStatus.CONFLICT,
        request = request,
        message = "请求与现有数据冲突，请刷新后重试"
    )

    @ExceptionHandler(OptimisticLockingFailureException::class)
    fun handleOptimisticLock(
        exception: OptimisticLockingFailureException,
        request: HttpServletRequest
    ): ResponseEntity<ApiErrorResponse> {
        logger.warn("Concurrent update rejected: {} {}", request.method, request.requestURI)
        return buildError(
            status = HttpStatus.CONFLICT,
            request = request,
            message = "数据刚刚发生变化，请刷新后重试"
        )
    }

    @ExceptionHandler(
        MethodArgumentNotValidException::class,
        ConstraintViolationException::class,
        MissingRequestHeaderException::class,
        MissingServletRequestParameterException::class,
        HttpMessageNotReadableException::class,
        MethodArgumentTypeMismatchException::class
    )
    fun handleValidationErrors(
        exception: Exception,
        request: HttpServletRequest
    ): ResponseEntity<ApiErrorResponse> {
        val details = when (exception) {
            is MethodArgumentNotValidException -> exception.bindingResult.allErrors.mapNotNull { error ->
                when (error) {
                    is FieldError -> "${error.field}: ${error.defaultMessage}"
                    else -> error.defaultMessage
                }
            }
            is ConstraintViolationException -> exception.constraintViolations.map { violation ->
                "${violation.propertyPath}: ${violation.message}"
            }
            is MissingRequestHeaderException -> listOf(exception.message)
            is MissingServletRequestParameterException -> listOf(
                "Missing request parameter: ${exception.parameterName}"
            )
            is HttpMessageNotReadableException -> listOf("请求体格式不正确")
            is MethodArgumentTypeMismatchException -> listOf(
                "Invalid value for ${exception.name}: ${exception.value}"
            )
            else -> emptyList()
        }

        return buildError(
            status = HttpStatus.BAD_REQUEST,
            request = request,
            message = "Request validation failed",
            details = details
        )
    }

    @ExceptionHandler(Exception::class)
    fun handleUnexpectedException(
        exception: Exception,
        request: HttpServletRequest
    ): ResponseEntity<ApiErrorResponse> {
        logger.error("Unhandled request error: {} {}", request.method, request.requestURI, exception)
        return buildError(
            status = HttpStatus.INTERNAL_SERVER_ERROR,
            request = request,
            message = "服务暂时不可用，请稍后重试"
        )
    }

    private fun buildError(
        status: HttpStatus,
        request: HttpServletRequest,
        message: String,
        details: List<String> = emptyList()
    ): ResponseEntity<ApiErrorResponse> {
        val response = ApiErrorResponse(
            timestamp = OffsetDateTime.now(),
            status = status.value(),
            error = status.reasonPhrase,
            message = message,
            path = request.requestURI,
            details = details
        )
        return ResponseEntity.status(status).body(response)
    }
}
