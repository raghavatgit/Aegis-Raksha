plugins {
    id("com.android.application") apply false
    id("com.android.library") apply false
    id("org.jetbrains.kotlin.android") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}


val externalBuildDir = file("C:/flutter_builds/Raksha-Net")
externalBuildDir.mkdirs()
rootProject.layout.buildDirectory.set(externalBuildDir)

subprojects {
    val subBuildDir = file("C:/flutter_builds/Raksha-Net/${project.name}")
    project.layout.buildDirectory.set(subBuildDir)
}


subprojects {
    val subproject = this

    // Automatically strip legacy v1 embedding Registrar references and dangling @JvmStatic from older Flutter plugins
    val srcDir = file("${subproject.projectDir}/src/main")
    if (srcDir.exists()) {
        try {
            srcDir.walkTopDown().filter { it.isFile && (it.extension == "kt" || it.extension == "java") }.forEach { file ->
                var text = file.readText()
                if (file.name == "FlutterNearbyConnectionsPlugin.kt" || text.contains("Registrar") || text.contains("registerWith")) {
                    text = text.replace(Regex("""import\s+io\.flutter\.plugin\.common\.PluginRegistry\.Registrar;?"""), "// import removed for Flutter v2 embedding")
                    // Comment out any @JvmStatic so it doesn't dangle without a member declaration
                    text = text.replace("@JvmStatic", "// @JvmStatic")
                    val funcIndex = text.indexOf("fun registerWith")
                    if (funcIndex != -1) {
                        val openBrace = text.indexOf('{', funcIndex)
                        if (openBrace != -1) {
                            var braceCount = 1
                            var endIndex = openBrace + 1
                            while (braceCount > 0 && endIndex < text.length) {
                                if (text[endIndex] == '{') braceCount++
                                else if (text[endIndex] == '}') braceCount--
                                endIndex++
                            }
                            if (braceCount == 0) {
                                text = text.substring(0, funcIndex) + "/* registerWith removed for Flutter v2 */" + text.substring(endIndex)
                            }
                        }
                    }
                    val javaFuncIndex = text.indexOf("registerWith(Registrar")
                    if (javaFuncIndex != -1) {
                        val lineStart = text.lastIndexOf('\n', javaFuncIndex)
                        val startIndex = if (lineStart != -1) lineStart + 1 else javaFuncIndex
                        val openBrace = text.indexOf('{', javaFuncIndex)
                        if (openBrace != -1) {
                            var braceCount = 1
                            var endIndex = openBrace + 1
                            while (braceCount > 0 && endIndex < text.length) {
                                if (text[endIndex] == '{') braceCount++
                                else if (text[endIndex] == '}') braceCount--
                                endIndex++
                            }
                            if (braceCount == 0) {
                                text = text.substring(0, startIndex) + "/* registerWith removed for Flutter v2 */\n" + text.substring(endIndex)
                            }
                        }
                    }
                    file.setWritable(true)
                    file.writeText(text)

                    if (file.name == "FlutterNearbyConnectionsPlugin.kt") {
                        try {
                            file.copyTo(rootProject.file("android/flutter_nearby_connections_plugin_dump.txt"), overwrite = true)
                        } catch (e: Exception) {
                            // Ignore
                        }
                    }
                }
            }
        } catch (e: Exception) {
            // Ignore if cannot patch
        }
    }

    subproject.plugins.withId("com.android.library") {
        var extractedPackage: String? = null
        val manifestFile = file("${subproject.projectDir}/src/main/AndroidManifest.xml")
        if (manifestFile.exists()) {
            try {
                var content = manifestFile.readText()
                val packageRegex = Regex("""package\s*=\s*"[^"]*"""")
                val match = packageRegex.find(content)
                if (match != null) {
                    extractedPackage = match.value.substringAfter("\"").substringBefore("\"")
                    manifestFile.setWritable(true)
                    content = content.replace(packageRegex, "")
                    manifestFile.writeText(content)
                }
            } catch (e: Exception) {
                // Ignore if cannot modify
            }
        }

        try {
            val extension = subproject.extensions.findByName("android")
            if (extension != null) {
                val getNamespace = extension.javaClass.getMethod("getNamespace")
                val current = getNamespace.invoke(extension)
                if (current == null) {
                    val setNamespace = extension.javaClass.getMethod("setNamespace", String::class.java)
                    val defaultNamespace = extractedPackage
                        ?: if (subproject.name == "flutter_nearby_connections") "com.nankai.flutter_nearby_connections"
                        else "com.example.${subproject.name.replace('-', '_')}"
                    setNamespace.invoke(extension, defaultNamespace)
                }
            }
        } catch (e: Exception) {
            // Ignore
        }
    }

    val configureAndroid = {
        try {
            val extension = subproject.extensions.findByName("android")
            if (extension != null) {
                val getNamespace = extension.javaClass.getMethod("getNamespace")
                val current = getNamespace.invoke(extension)
                if (current == null) {
                    val setNamespace = extension.javaClass.getMethod("setNamespace", String::class.java)
                    val defaultNamespace = if (subproject.name == "flutter_nearby_connections") {
                        "com.nankai.flutter_nearby_connections"
                    } else {
                        "com.example.${subproject.name.replace('-', '_')}"
                    }
                    setNamespace.invoke(extension, defaultNamespace)
                }

                val setCompileSdkVersion = extension.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                setCompileSdkVersion.invoke(extension, 36)
            }
        } catch (e: Exception) {
            // Ignore if subproject does not support setting compileSdkVersion
        }
    }

    if (subproject.state.executed) {
        configureAndroid()
    } else {
        subproject.afterEvaluate {
            configureAndroid()
        }
    }

    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "17"
        }
    }
    
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}