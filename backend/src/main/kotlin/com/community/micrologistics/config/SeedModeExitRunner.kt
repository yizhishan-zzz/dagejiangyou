package com.community.micrologistics.config

import org.slf4j.LoggerFactory
import org.springframework.boot.ApplicationArguments
import org.springframework.boot.ApplicationRunner
import org.springframework.boot.ExitCodeGenerator
import org.springframework.boot.SpringApplication
import org.springframework.context.ConfigurableApplicationContext
import org.springframework.context.annotation.Profile
import org.springframework.stereotype.Component
import kotlin.system.exitProcess

@Component
@Profile("seed")
class SeedModeExitRunner(
    private val applicationContext: ConfigurableApplicationContext
) : ApplicationRunner {
    override fun run(args: ApplicationArguments) {
        logger.info("Seed mode finished loading schema.sql and data.sql. Exiting bootstrap process.")
        val exitCode = SpringApplication.exit(applicationContext, ExitCodeGenerator { 0 })
        exitProcess(exitCode)
    }

    companion object {
        private val logger = LoggerFactory.getLogger(SeedModeExitRunner::class.java)
    }
}
