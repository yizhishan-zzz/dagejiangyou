package com.community.micrologistics.config

import com.community.micrologistics.entity.PoolEntity
import com.community.micrologistics.entity.AdSlotEntity
import com.community.micrologistics.entity.CommunityEntity
import com.community.micrologistics.entity.CommunityBuildingEntity
import com.community.micrologistics.entity.TaskEntity
import com.community.micrologistics.entity.UserEntity
import com.community.micrologistics.entity.WalletEntity
import com.community.micrologistics.enums.PoolStatus
import com.community.micrologistics.enums.TaskStatus
import com.community.micrologistics.enums.TaskType
import com.community.micrologistics.enums.UserMode
import com.community.micrologistics.enums.WalletType
import com.community.micrologistics.enums.SystemRole
import com.community.micrologistics.repository.PoolRepository
import com.community.micrologistics.repository.AdSlotRepository
import com.community.micrologistics.repository.CommunityRepository
import com.community.micrologistics.repository.CommunityBuildingRepository
import com.community.micrologistics.repository.TaskRepository
import com.community.micrologistics.repository.UserRepository
import com.community.micrologistics.repository.WalletRepository
import org.slf4j.LoggerFactory
import org.springframework.boot.ApplicationArguments
import org.springframework.boot.ApplicationRunner
import org.springframework.context.annotation.Profile
import org.springframework.stereotype.Component
import org.springframework.security.crypto.password.PasswordEncoder
import java.math.BigDecimal
import java.util.UUID

@Component
@Profile("dev")
class DevDataSeeder(
    private val userRepository: UserRepository,
    private val walletRepository: WalletRepository,
    private val taskRepository: TaskRepository,
    private val poolRepository: PoolRepository,
    private val adSlotRepository: AdSlotRepository,
    private val communityRepository: CommunityRepository,
    private val buildingRepository: CommunityBuildingRepository,
    private val passwordEncoder: PasswordEncoder
) : ApplicationRunner {
    override fun run(args: ApplicationArguments) {
        seedCommunities()
        seedUsers()
        seedWallets()
        seedTasks()
        seedPools()
        seedAds()

        logger.info(
            """
            Local dev seed ready.
            Creator demo user: {}
            Runner demo user: {}
            Neighbor demo user: {}
            Demo password: {}
            Demo task id: {}
            Demo pool id: {}
            """.trimIndent(),
            CREATOR_USER_ID,
            RUNNER_USER_ID,
            NEIGHBOR_USER_ID,
            DEMO_PASSWORD,
            OPEN_TASK_ID,
            OPEN_POOL_ID
        )
    }

    private fun seedCommunities() {
        listOf(
            CommunityEntity(COMMUNITY_ID, "春和里社区", 31.2304, 121.4737),
            CommunityEntity(RIVERSIDE_COMMUNITY_ID, "滨江雅苑", 31.2328, 121.4761),
            CommunityEntity(GARDEN_COMMUNITY_ID, "梧桐花园", 31.2279, 121.4708)
        ).forEach { communityRepository.save(it) }

        listOf(
            CommunityBuildingEntity(BUILDING_3_ID, COMMUNITY_ID, "3号楼", 31.2300, 121.4739, 3),
            CommunityBuildingEntity(BUILDING_5_ID, COMMUNITY_ID, "5号楼", 31.2303, 121.4735, 5),
            CommunityBuildingEntity(BUILDING_7_ID, COMMUNITY_ID, "7号楼", 31.2310, 121.4743, 7),
            CommunityBuildingEntity(RIVER_A_ID, RIVERSIDE_COMMUNITY_ID, "A座", 31.2325, 121.4758, 1),
            CommunityBuildingEntity(RIVER_B_ID, RIVERSIDE_COMMUNITY_ID, "B座", 31.2330, 121.4763, 2),
            CommunityBuildingEntity(GARDEN_1_ID, GARDEN_COMMUNITY_ID, "1号楼", 31.2277, 121.4705, 1),
            CommunityBuildingEntity(GARDEN_2_ID, GARDEN_COMMUNITY_ID, "2号楼", 31.2281, 121.4711, 2)
        ).forEach { buildingRepository.save(it) }
    }

    private fun seedUsers() {
        val passwordHash = passwordEncoder.encode(DEMO_PASSWORD)
        val users = listOf(
            UserEntity(
                id = CREATOR_USER_ID,
                phoneNumber = "13800000001",
                displayName = "林晓雪",
                avatarEmoji = "雪",
                bio = "常驻 7 号楼，日常发布快递代取和临时代买需求。",
                passwordHash = passwordHash,
                activeMode = UserMode.CREATOR,
                creditScore = BigDecimal("98.50"),
                creatorEnabled = true,
                runnerEnabled = true,
                communityName = "春和里社区",
                buildingName = "7号楼",
                roomMask = "7-2***",
                notificationsEnabled = true,
                privacyMasked = true,
                communityVerified = true,
                communityId = COMMUNITY_ID,
                locationLatitude = 31.2310,
                locationLongitude = 121.4743
            ),
            UserEntity(
                id = RUNNER_USER_ID,
                phoneNumber = "13800000002",
                displayName = "周子衡",
                avatarEmoji = "跑",
                bio = "工作日和晚饭后接单比较多，超短距跑腿和代拿效率很高。",
                passwordHash = passwordHash,
                activeMode = UserMode.RUNNER,
                creditScore = BigDecimal("96.20"),
                creatorEnabled = true,
                runnerEnabled = true,
                communityName = "春和里社区",
                buildingName = "5号楼",
                roomMask = "5-1***",
                notificationsEnabled = true,
                privacyMasked = true,
                communityVerified = true,
                communityId = COMMUNITY_ID,
                locationLatitude = 31.2303,
                locationLongitude = 121.4735
            ),
            UserEntity(
                id = NEIGHBOR_USER_ID,
                phoneNumber = "13800000003",
                displayName = "陈阿姨",
                avatarEmoji = "邻",
                bio = "经常组织社区拼单，也会顺手帮大家带些日用品。",
                passwordHash = passwordHash,
                activeMode = UserMode.CREATOR,
                creditScore = BigDecimal("93.80"),
                creatorEnabled = true,
                runnerEnabled = true,
                communityName = "春和里社区",
                buildingName = "3号楼",
                roomMask = "3-1***",
                notificationsEnabled = true,
                privacyMasked = true,
                communityVerified = true,
                communityId = COMMUNITY_ID,
                locationLatitude = 31.2300,
                locationLongitude = 121.4739
            ),
            UserEntity(
                id = ADMIN_USER_ID,
                phoneNumber = "13800000099",
                displayName = "平台管理员",
                avatarEmoji = "管",
                bio = "负责平台运营、安全审核与服务治理。",
                passwordHash = passwordHash,
                activeMode = UserMode.CREATOR,
                creditScore = BigDecimal("100.00"),
                creatorEnabled = true,
                runnerEnabled = true,
                communityName = "平台运营中心",
                notificationsEnabled = true,
                privacyMasked = true,
                communityVerified = true,
                systemRole = SystemRole.ADMIN
            )
        )

        users.forEach { userRepository.save(it) }
    }

    private fun seedWallets() {
        val wallets = listOf(
            wallet(CREATOR_CREATOR_WALLET_ID, CREATOR_USER_ID, WalletType.CREATOR, "113.64", "6.36"),
            wallet(CREATOR_RUNNER_WALLET_ID, CREATOR_USER_ID, WalletType.RUNNER, "18.50", "0.00"),
            wallet(RUNNER_CREATOR_WALLET_ID, RUNNER_USER_ID, WalletType.CREATOR, "88.00", "0.00"),
            wallet(RUNNER_RUNNER_WALLET_ID, RUNNER_USER_ID, WalletType.RUNNER, "26.00", "0.00"),
            wallet(NEIGHBOR_CREATOR_WALLET_ID, NEIGHBOR_USER_ID, WalletType.CREATOR, "63.32", "2.68"),
            wallet(NEIGHBOR_RUNNER_WALLET_ID, NEIGHBOR_USER_ID, WalletType.RUNNER, "12.00", "0.00")
        )

        wallets.forEach { walletRepository.save(it) }
    }

    private fun seedTasks() {
        val tasks = listOf(
            TaskEntity(
                id = OPEN_TASK_ID,
                creatorId = CREATOR_USER_ID,
                communityId = COMMUNITY_ID,
                taskType = TaskType.PACKAGE_PICKUP,
                status = TaskStatus.OPEN,
                title = "北门驿站快递代取",
                description = "北门驿站有一个小件快递，帮忙带到 7 号楼电梯厅即可。",
                pickupLatitude = 31.2304,
                pickupLongitude = 121.4737,
                dropoffLatitude = 31.2310,
                dropoffLongitude = 121.4743,
                pickupFloor = 1,
                dropoffFloor = 7,
                pickupHasElevator = true,
                dropoffHasElevator = false,
                weightKg = BigDecimal("1.20"),
                weatherSurcharge = BigDecimal("0.50"),
                baseFee = BigDecimal("2.00"),
                suggestedTip = BigDecimal("6.36"),
                escrowAmount = BigDecimal("6.36")
            ),
            TaskEntity(
                id = SECOND_TASK_ID,
                creatorId = NEIGHBOR_USER_ID,
                communityId = COMMUNITY_ID,
                taskType = TaskType.ERRAND,
                status = TaskStatus.OPEN,
                title = "楼下便利店酱油速购",
                description = "顺手带一包纸巾和两瓶矿泉水，送到 3 号楼电梯口。",
                pickupLatitude = 31.2298,
                pickupLongitude = 121.4731,
                dropoffLatitude = 31.2300,
                dropoffLongitude = 121.4739,
                pickupFloor = 1,
                dropoffFloor = 3,
                pickupHasElevator = true,
                dropoffHasElevator = true,
                weightKg = BigDecimal("0.60"),
                weatherSurcharge = BigDecimal("0.00"),
                baseFee = BigDecimal("2.50"),
                suggestedTip = BigDecimal("2.68"),
                escrowAmount = BigDecimal("2.68")
            )
        )

        tasks.forEach { taskRepository.save(it) }
    }

    private fun seedPools() {
        poolRepository.save(
            PoolEntity(
                id = OPEN_POOL_ID,
                creatorId = NEIGHBOR_USER_ID,
                communityId = COMMUNITY_ID,
                title = "晚饭轻食拼单",
                storeName = "大堂轻食档口",
                category = "社区团餐",
                summary = "晚高峰一起下单能摊薄配送费，满 6 人直接成团。",
                pickupPoint = "3号楼架空层自提点",
                status = PoolStatus.OPEN,
                freightFee = BigDecimal("6.00"),
                deliveryFee = BigDecimal("3.60"),
                targetParticipants = 6,
                currentParticipants = 1,
                countdownMinutes = 18,
                sharedFeePerUser = BigDecimal("9.60")
            )
        )
    }

    private fun seedAds() {
        listOf(
            AdSlotEntity(
                id = HOME_AD_ID,
                placement = "HOME_TOP",
                label = "社区推荐",
                title = "晚饭前，顺手帮你带回家",
                subtitle = "附近便利店与邻里帮办已接入，短距离也能安排得明明白白。",
                actionLabel = "去看看",
                actionRoute = "/marketplace",
                accentHex = "#2257D9",
                sortOrder = 10
            ),
            AdSlotEntity(
                id = MARKETPLACE_AD_ID,
                placement = "MARKETPLACE_TOP",
                label = "本周精选",
                title = "同一栋楼，顺路就是最快的路线",
                subtitle = "看看附近正在等待响应的短途任务，接一单再回家。",
                actionLabel = "浏览任务",
                actionRoute = "/marketplace",
                accentHex = "#F04E45",
                sortOrder = 10
            )
        ).forEach { adSlotRepository.save(it) }
    }

    private fun wallet(
        walletId: UUID,
        userId: UUID,
        walletType: WalletType,
        availableBalance: String,
        frozenBalance: String
    ) = WalletEntity(
        id = walletId,
        userId = userId,
        walletType = walletType,
        availableBalance = BigDecimal(availableBalance),
        frozenBalance = BigDecimal(frozenBalance)
    )

    companion object {
        private val logger = LoggerFactory.getLogger(DevDataSeeder::class.java)
        const val DEMO_PASSWORD = "demo123456"

        private val COMMUNITY_ID: UUID = UUID.fromString("99999999-9999-9999-9999-999999999999")
        private val RIVERSIDE_COMMUNITY_ID: UUID = UUID.fromString("88888888-8888-8888-8888-888888888888")
        private val GARDEN_COMMUNITY_ID: UUID = UUID.fromString("77777777-7777-7777-7777-777777777777")

        private val BUILDING_3_ID: UUID = UUID.fromString("10000000-0000-0000-0000-000000000003")
        private val BUILDING_5_ID: UUID = UUID.fromString("10000000-0000-0000-0000-000000000005")
        private val BUILDING_7_ID: UUID = UUID.fromString("10000000-0000-0000-0000-000000000007")
        private val RIVER_A_ID: UUID = UUID.fromString("20000000-0000-0000-0000-000000000001")
        private val RIVER_B_ID: UUID = UUID.fromString("20000000-0000-0000-0000-000000000002")
        private val GARDEN_1_ID: UUID = UUID.fromString("30000000-0000-0000-0000-000000000001")
        private val GARDEN_2_ID: UUID = UUID.fromString("30000000-0000-0000-0000-000000000002")

        val CREATOR_USER_ID: UUID = UUID.fromString("11111111-1111-1111-1111-111111111111")
        val RUNNER_USER_ID: UUID = UUID.fromString("22222222-2222-2222-2222-222222222222")
        val NEIGHBOR_USER_ID: UUID = UUID.fromString("33333333-3333-3333-3333-333333333333")
        val ADMIN_USER_ID: UUID = UUID.fromString("99999999-aaaa-9999-aaaa-999999999999")

        private val CREATOR_CREATOR_WALLET_ID: UUID = UUID.fromString("11111111-aaaa-1111-aaaa-111111111111")
        private val CREATOR_RUNNER_WALLET_ID: UUID = UUID.fromString("11111111-bbbb-1111-bbbb-111111111111")
        private val RUNNER_CREATOR_WALLET_ID: UUID = UUID.fromString("22222222-aaaa-2222-aaaa-222222222222")
        private val RUNNER_RUNNER_WALLET_ID: UUID = UUID.fromString("22222222-bbbb-2222-bbbb-222222222222")
        private val NEIGHBOR_CREATOR_WALLET_ID: UUID = UUID.fromString("33333333-aaaa-3333-aaaa-333333333333")
        private val NEIGHBOR_RUNNER_WALLET_ID: UUID = UUID.fromString("33333333-bbbb-3333-bbbb-333333333333")

        val OPEN_TASK_ID: UUID = UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")
        private val SECOND_TASK_ID: UUID = UUID.fromString("cccccccc-cccc-cccc-cccc-cccccccccccc")
        val OPEN_POOL_ID: UUID = UUID.fromString("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")
        private val HOME_AD_ID: UUID = UUID.fromString("aaaaaaaa-1111-aaaa-1111-aaaaaaaa1111")
        private val MARKETPLACE_AD_ID: UUID = UUID.fromString("bbbbbbbb-2222-bbbb-2222-bbbbbbbb2222")
    }
}
