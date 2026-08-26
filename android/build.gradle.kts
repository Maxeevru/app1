allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// ГЛОБАЛЬНЫЙ И БЕЗОТКАЗНЫЙ ФИКС ДЛЯ ВСЕХ ПЛАГИНОВ (ВКЛЮЧАЯ TELEPHONY):
subprojects {
    plugins.withId("com.android.application") {
        configure<com.android.build.gradle.BaseExtension> {
            compileSdkVersion(34)
            defaultConfig { targetSdk = 34 }
            // Если у плагина нет namespace, даем ему имя на основе его названия
            if (namespace == null) {
                namespace = "com.example.${project.name}"
            }
        }
    }
    plugins.withId("com.android.library") {
        configure<com.android.build.gradle.BaseExtension> {
            compileSdkVersion(34)
            defaultConfig { targetSdk = 34 }
            // Фикс ошибки Namespace not specified для старых библиотек
            if (namespace == null) {
                namespace = "com.example.${project.name}"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
