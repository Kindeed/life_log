import java.io.File

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

fun containsNonAscii(value: String): Boolean = value.any { it.code > 127 }

val newBuildDir: File =
    if (containsNonAscii(rootProject.projectDir.absolutePath)) {
        File(System.getProperty("java.io.tmpdir"), "life_log_android_build")
    } else {
        rootProject.layout.buildDirectory.dir("../../build").get().asFile
    }
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    project.layout.buildDirectory.set(File(newBuildDir, project.name))
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// --- 解决 Isar 3.1.0 兼容性问题的智能补丁 ---
subprojects {
    // 定义修复逻辑
    val fixIsarNamespace = {
        if (project.name == "isar_flutter_libs") {
            try {
                val android = project.extensions.getByName("android")
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                setNamespace.invoke(android, "dev.isar.isar_flutter_libs")
                println(">>> 已自动修复 Isar namespace 问题 (项目: ${project.name})")
            } catch (e: Exception) {
                println(">>> 尝试修复 Isar namespace 失败: $e")
            }
        }
    }

    // 智能判断执行时机
    if (project.state.executed) {
        // 如果项目已经加载完了，立刻执行
        fixIsarNamespace()
    } else {
        // 如果还没加载完，就等它加载完再执行
        project.afterEvaluate {
            fixIsarNamespace()
        }
    }
}

subprojects {
    // --- 解决 android:attr/lStar not found 等资源链接问题 ---
    val applyCompileSdkFix = {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android")
            try {
                val setCompileSdk = android.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                setCompileSdk.invoke(android, 36)
            } catch (e: Exception) {
                try {
                    val setCompileSdkVersion = android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    setCompileSdkVersion.invoke(android, 36)
                } catch (e2: Exception) {}
            }
        }
    }

    if (project.state.executed) {
        applyCompileSdkFix()
    } else {
        project.afterEvaluate { applyCompileSdkFix() }
    }
}
